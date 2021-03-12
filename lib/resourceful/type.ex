defmodule Resourceful.Type do
  @moduledoc """
  `Resourceful.Type` is a struct and set of functions for representing and
  mapping internal data structures to data structures more appropriate for edge
  clients (e.g. API clients). As a result, field names are _always_ strings and
  not atoms.

  In addition to mapping data field names, it validates that client
  representations conform to various constraints set by the type. These include
  transversing field graphs, limiting which fields can be queried, and how deep
  down the graph queries can go.

  The naming conventions and some of design philosophy is geared heavily toward
  APIs over HTTP and [JSON:API specification](https://jsonapi.org/). However,
  there is nothing JSON-API specific about types.

  ## Fields

  A "field" refers to an attribute or a relationship on a given type. These
  share a common namespace and in some respects can be treated interchangeably.

  There is a distinction between "local" fields and "query" fields.

  Local fields are those which are directly on the current type. For example, a
  type of album may have local attributes such as a title and release date and
  local relationships such as artist and songs.

  Query fields are a combination of local fields and fields anywhere in the
  resource graph. So, in the above example, query fields would include something
  like an album's title and the related artist's name.

   ### Relationships and Registries

  In order to use relationships, a type must be included in a
  `Resourceful.Registry` and, in general, types are meant to be used in
  conjunction with a registry. In most functions dealing with relationships and
  related types, a type's `name` (just a string) is used rather than passing
  a type struct. The struct itself will be looked up from the registry.

  ### Queries

  The term "query" is used to refer to filtering and sorting collections of
  resources. Since queries ultimately work on attributes, fields eligible to be
  queried must be attributes. You could sort songs by an album's title but you
  wouldn't reasonably sort them by an album resource.

  Fields given for a query can be represented as a list of strings or as a dot
  separated string. So, when looking at a song, the artist's name could be
  accessed through `"album.artist.name"` or `["album", "artist", "name"]`. As
  with many things related to types, string input from API sources is going to
  be the most common form of input.

  ## "Root" Types

  Resource graphs are put together from the perspective of a "root" type. Any
  type can be a root type. In the example of an API, if you were looking at an
  album, it would be the root with its songs and artist further down the graph.

  ## Building Types

  In addition to functions that actually do something with types, there are a
  number of functions used for transforming types such as `max_depth/2`. As
  types are designed with registries in mind, types can be built at compile-time
  using transformation functions in a manner that may be easier to read than
  `new/2` with options.

  ## Ecto Schemas

  There is some overlap with `Ecto.Schema`. In fact, attribute types use the
  same type system. While schemas can be used for edge data, primarily when
  coupled with change sets, types are more specifically tailored to the task.
  Types, combined with `Resourceful.Collection` can be combined to construct a
  queryable API with concerns that are specific to working with the edge.
  The query format is specifically limited for this purpose.
  """

  defmodule FieldError do
    defexception message: "field could not be found"
  end

  defmodule InvalidName do
    defexception message: "names cannot contain periods (\".\")"
  end

  import Map, only: [put: 3]

  alias __MODULE__
  alias __MODULE__.{Attribute, GraphedField, Relationship}
  alias Resourceful.Error
  alias Resourceful.Collection.{Filter, Sort}

  @typedoc """
  A field is an attribute or a relationship. They share the same namespace
  within a type.
  """
  @type field() :: %Attribute{} | %Relationship{}

  @type field_graph() :: %{String.t() => %GraphedField{}}

  @type field_name() :: String.t() | [String.t()]

  @type queryable() :: %Attribute{} | %GraphedField{field: %Attribute{}}

  @enforce_keys [
    :cache,
    :fields,
    :id,
    :max_filters,
    :max_sorters,
    :meta,
    :name,
    :max_depth
  ]

  defstruct @enforce_keys ++ [:registry]

  @doc """
  Creates a new `Resourceful.Type` with valid attributes.

  See functions of the same name for more information on key functionality.
  For fields, see `Resourceful.Type.Attribute` and
  `Resourceful.Type.Relationship`.
  """
  @spec new(String.t(), keyword()) :: %Type{}
  def new(name, opts \\ []) do
    fields = opt_fields(Keyword.get(opts, :fields, []))

    %Type{
      cache: %{},
      fields: fields,
      id: opt_id(Keyword.get(opts, :id, default_id(fields))),
      meta: opt_meta(Keyword.get(opts, :meta, %{})),
      max_depth: opt_max(Keyword.get(opts, :max_depth, 1)),
      max_filters: opt_max_or_nil(Keyword.get(opts, :max_filters, 4)),
      max_sorters: opt_max_or_nil(Keyword.get(opts, :max_sorters, 2)),
      name: validate_name!(name)
    }
  end

  defp default_id(%{"id" => %Attribute{}}), do: "id"

  defp default_id(_), do: nil

  defp opt_field(%mod{} = field)
       when mod in [Attribute, Relationship],
       do: field

  defp opt_fields(%{} = fields) do
    fields
    |> Map.values()
    |> opt_fields()
  end

  defp opt_fields(fields) do
    fields
    |> Enum.map(&opt_field/1)
    |> Enum.reduce(%{}, fn field, map -> put(map, field.name, field) end)
  end

  defp opt_id(nil), do: nil

  defp opt_id([id_attribute | []]), do: opt_id(id_attribute)

  defp opt_id(id_attribute) when is_atom(id_attribute), do: to_string(id_attribute)

  defp opt_id(id_attribute) when is_binary(id_attribute), do: id_attribute

  defp opt_max(int) when is_integer(int) and int >= 0, do: int

  defp opt_max_or_nil(nil), do: nil

  defp opt_max_or_nil(int), do: opt_max(int)

  defp opt_meta(%{} = map), do: map

  defp opt_with_name({new_name, %{name: current_name} = attr_or_rel}) do
    case new_name == current_name do
      true -> attr_or_rel
      _ -> %{attr_or_rel | name: new_name}
    end
  end

  @doc """
  Sets a key in the `cache` map. Because types generally intended to be static
  at compile time, it can make sense to cache certain values and have functions
  look for cached values in the cache map.

  For instance, `finalize/1` creates a `MapSet` for `related_types` which
  `related_types/1` will use instead of computed the `MapSet`.

  Caches are not meant to be memoized, rather set on a type once it is
  considered complete.
  """
  @spec cache(%Type{}, atom(), any()) :: %Type{}
  def cache(type, key, value) when is_atom(key) do
    put_in_struct(type, :cache, key, value)
  end

  @doc """
  Fetches a local attribute or, if a registry is set, a graphed attribute.
  """
  @spec fetch_attribute(%Type{}, field_name()) ::
          {:ok, %Attribute{} | %GraphedField{field: %Attribute{}}} | Error.t()
  def fetch_attribute(type, name) do
    fetch_field(type, name, error_type: :attribute_not_found, field_type: [Attribute])
  end

  @doc """
  Fetches a local field or, if a registry is set, a graphed field.
  """
  @spec fetch_field(%Type{}, field_name(), keyword()) ::
          {:ok, field() | %GraphedField{}} | Error.t()
  def fetch_field(type, name, opts \\ [])

  def fetch_field(%{registry: nil} = type, name, opts) do
    fetch_local_field(type, name, opts)
  end

  def fetch_field(type, name, opts), do: fetch_graphed_field(type, name, opts)

  @doc """
  Same as `fetch_field/2` but raises `FieldError` if the field isn't present.
  """
  @spec fetch_field!(%Type{}, field_name()) :: field() | %GraphedField{}
  def fetch_field!(type, name), do: fetch!(name, fetch_field(type, name))

  @doc """
  Fetches a field with related graph data using the resource's field graphs.

  Unless you have a specific reason for fetching only graphed fields, use
  `fetch_field/3` instead.
  """
  @spec fetch_graphed_field(%Type{}, field_name(), keyword()) ::
          {:ok, %GraphedField{}} | Error.t()
  def fetch_graphed_field(type, name, opts \\ [])

  def fetch_graphed_field(type, name, opts) when is_list(name) do
    fetch_graphed_field(type, string_name(name), opts)
  end

  def fetch_graphed_field(type, name, opts) do
    with {:ok, field_graph} <- field_graph(type),
         {:ok, graphed_field} = ok <- Map.fetch(field_graph, name),
         true <- field_is?(graphed_field.field, opts) do
      ok
    else
      _ -> not_found_error(type, name, opts)
    end
  end

  @doc """
  Same as `fetch_graphed_field/2` but raises `FieldError` if the graphed field
  isn't present.

  Unless you have a specific reason for fetching only graphed fields, use
  `fetch_field!/3` instead.
  """
  @spec fetch_graphed_field!(%Type{}, field_name()) :: %GraphedField{}
  def fetch_graphed_field!(type, name), do: fetch!(name, fetch_graphed_field(type, name))

  @doc """
  Fetches a local field by name.

  Unless you have a specific reason for fetching local fields, use
  `fetch_field/3` instead.
  """
  @spec fetch_local_field(%Type{}, String.t(), keyword()) :: {:ok, field()} | Error.t()
  def fetch_local_field(type, name, opts \\ []) do
    with {:ok, field} = ok <- Map.fetch(type.fields, name),
         true <- field_is?(field, opts) do
      ok
    else
      _ -> not_found_error(type, name, opts)
    end
  end

  @doc """
  Same as `fetch_local_field/2` but raises `FieldError` if the local field isn't
  present.

  Unless you have a specific reason for fetching local fields, use
  `fetch_field@/3` instead.
  """
  @spec fetch_local_field!(%Type{}, field_name()) :: %GraphedField{}
  def fetch_local_field!(type, name, opts \\ []) do
    fetch!(name, fetch_local_field(type, name, opts))
  end

  @doc """
  Fetches another type by name from a type's registry.
  """
  @spec fetch_related_type(%Type{}, String.t()) :: {:ok, %Type{}} | Error.t()
  def fetch_related_type(%Type{name: name} = type, type_name)
      when type_name == name,
      do: {:ok, type}

  def fetch_related_type(%Type{} = type, type_name) do
    with {:ok, registry} <- fetch_registry(type), do: registry.fetch(type_name)
  end

  @doc """
  Fetches a local relationship or, if a registry is set, a graphed relationship.
  """
  @spec fetch_relationship(%Type{}, field_name()) ::
          {:ok, %Relationship{} | %GraphedField{field: %Relationship{}}} | Error.t()
  def fetch_relationship(type, name) do
    fetch_field(type, name, error_type: :relationship_not_found, field_type: [Relationship])
  end

  @doc """
  Fetches the field graph for a given type if the type exists and has a
  registry.
  """
  @spec field_graph(%Type{}) :: field_graph()
  def field_graph(type) do
    with {:ok, registry} <- fetch_registry(type),
         do: registry.fetch_field_graph(type.name)
  end

  @doc """
  Checks if a type has a local field.
  """
  @spec has_local_field?(%Type{}, String.t()) :: boolean()
  def has_local_field?(%Type{} = type, name), do: Map.has_key?(type.fields, name)

  @doc """
  Sets the attribute to be used as the ID attribute for a given type. The ID
  field has slightly special usage in that extensions will use it for both
  identification and equality. There are also conveniences for working directly
  with IDs such as `get_id/2`.

  A limitation of types is that currently composite ID fields are not supported.
  """
  @spec id(%Type{}, String.t()) :: %Type{}
  def id(type, id_attribute), do: put(type, :id, opt_id(id_attribute))

  @doc """
  Validates and returns the mapped names from a graph
  """
  @spec map_field(%Type{}, field_name()) ::
          {:ok, [atom() | String.t()]} | Error.t()
  def map_field(type, name) do
    with {:ok, field_or_graph} <- fetch_field(type, name),
         do: {:ok, field_or_graph.map_to}
  end

  @doc """
  Maps the ID value for a given resource. This is just shorthand for using
  `map_value/3` on whatever field is designated as the ID.
  """
  @spec map_id(any(), %Type{}) :: any()
  def map_id(resource, type), do: map_value(resource, type, type.id)

  @doc """
  Maps a value for a given field name for a resource.
  """
  @spec map_value(map(), %Type{}, field_name()) :: any()
  def map_value(resource, %Type{} = type, name) do
    case map_field(type, name) do
      {:ok, path} when is_list(path) -> get_with_path(resource, path)
      {:ok, key} -> Map.get(resource, key)
      _ -> nil
    end
  end

  defp get_with_path(resource, []), do: resource

  defp get_with_path(%{} = resource, [key | path]) do
    resource
    |> Map.get(key)
    |> get_with_path(path)
  end

  defp get_with_path(_, _), do: nil

  @doc """
  Takes mappable resource, a type, and a list of fields. Returns a list of
  tuples with the field name and the mapped value. This is returned instead
  of a map to preserve the order of the input list. If order is irrelevant, use
  `to_map/2` instead.
  """
  @spec map_values(map(), %Type{}, [field_name()]) :: [{any(), any()}]
  def map_values(resource, type, fields \\ [])

  def map_values(resource, type, []) do
    map_values(resource, type, Map.keys(type.fields))
  end

  def map_values(resource, type, fields) when is_list(fields) do
    Enum.map(fields, &{&1, map_value(resource, type, &1)})
  end

  @doc """
  Sets `max_depth` on a type.

  `max_depth` is specifically a reference to the depth of relationships that
  will be transversed. This means the default `max_depth` of `1` would expose
  all immediate relationships and their attributes.

  For example, a song type with a `max_depth` of `1` would be able to graph
  through `album` and query against `album.title` but would not be able to
  access `album.artist` or any of its attributes. Increasing the `max_depth` to
  `2` would expose `album.artist.name`.
  """
  @spec max_depth(%Type{}, integer()) :: %Type{}
  def max_depth(type, max_depth), do: put(type, :max_depth, opt_max(max_depth))

  @doc """
  Sets `max_filters` on a type. This is the total number of filters allowed in
  a single query.
  """
  @spec max_filters(%Type{}, integer()) :: %Type{}
  def max_filters(type, max_filters) do
    put(type, :max_filters, opt_max_or_nil(max_filters))
  end

  @doc """
  Sets `max_sorters` on a type. This is the total number of sorts allowed in a
  single query.
  """
  @spec max_sorters(%Type{}, integer()) :: %Type{}
  def max_sorters(type, max_sorters) do
    put(type, :max_sorters, opt_max_or_nil(max_sorters))
  end

  @doc """
  Adds a value to the `meta` map. Meta information is not used by types directly
  in this module. It is intended to add more information that can be used by
  extensions and other implementations. For example, JSON:API resources provide
  linkage and describing that linkage is an appropriate use of the meta map.

  Cached values should _not_ be put in the meta map. Though both `cache` and
  `meta` could essentially be used for the same thing, caches are expected to be
  set specially when registering a type in `Resourceful.Registry` because
  `without_cache/1` is called before finalizing a type.
  """
  @spec meta(%Type{}, atom(), any()) :: %Type{}
  def meta(type, key, value) when is_atom(key), do: put_in_struct(type, :meta, key, value)

  @doc """
  Sets `name` on a type. Name must be strings and _cannot_ contain periods.
  Atoms will be automatically converted to strings.
  """
  @spec name(%Type{}, String.t()) :: %Type{}
  def name(type, name), do: put(type, :name, validate_name!(name))

  @doc """
  Puts a new field in the `fields` map using the field's name as the
  key. This will replace a field of the same name if present.
  """
  @spec put_field(%Type{}, field()) :: %Type{}
  def put_field(%Type{} = type, %module{} = field)
      when module in [Attribute, Relationship],
      do: put_in_struct(type, :fields, field.name, field)

  @doc """
  Sets the `registry` module for a type. In general, this functional will be
  called by a `Resourceful.Registry` and not directly.
  """
  @spec register(%Type{}, module()) :: %Type{}
  def register(type, module) when is_atom(module), do: put(type, :registry, module)

  @doc """
  Returns a name as a dot-separated string.
  """
  @spec string_name(field_name()) :: String.t()
  def string_name(name) when is_binary(name), do: name

  def string_name(name), do: Enum.join(name, ".")

  @doc """
  Like `map_values/3` only returns a map with keys in the name of the attributes
  with with values of the mapped values.
  """
  @spec to_map(any(), %Type{}, list()) :: map()
  def to_map(resource, type, field_names \\ []) do
    type
    |> map_values(resource, field_names)
    |> Map.new()
  end

  @doc """
  Validates a single filter on an attribute.
  """
  @spec validate_filter(%Type{}, any()) :: {:ok, Filter.t()} | Error.t()
  def validate_filter(type, filter) do
    with {:ok, {field_name, op, val}} <- Filter.cast(filter),
         {:ok, attr_or_graph} <- fetch_attribute(type, field_name),
         {:ok, _} = ok <- Attribute.validate_filter(attr_or_graph, op, val),
         do: ok
  end

  @doc """
  Validates that the max number of filters hasn't been exceeded.
  """
  @spec validate_max_filters(list(), %Type{}, map()) :: list()
  def validate_max_filters(list, type, context \\ %{}) do
    check_max(list, type.max_filters, :max_filters_exceeded, context)
  end

  @doc """
  Validates that the max number of sorters hasn't been exceeded.
  """
  @spec validate_max_sorters(list(), %Type{}, map()) :: list()
  def validate_max_sorters(list, type, context \\ %{}) do
    check_max(list, type.max_sorters, :max_sorters_exceeded, context)
  end

  @doc """
  Validates a single sorter on an attribute.
  """
  @spec validate_sorter(%Type{}, any()) :: {:ok, Sort.t()} | Error.t()
  def validate_sorter(type, sorter) do
    with {:ok, {order, field_name}} <- Sort.cast(sorter),
         {:ok, attr_or_graph} <- fetch_attribute(type, field_name),
         {:ok, _} = ok <- Attribute.validate_sorter(attr_or_graph, order),
         do: ok
  end

  @doc """
  Returns a valid string name for a type or field. Technically any string
  without a period is valid, but like most names, don't go nuts with URL
  characters, whitespace, etc.
  """
  @spec validate_name!(String.t() | atom()) :: String.t()
  def validate_name!(name) when is_atom(name) do
    name
    |> to_string()
    |> validate_name!()
  end

  def validate_name!(name) when is_binary(name) do
    if String.match?(name, ~r/\./), do: raise(InvalidName)
    name
  end

  @doc """
  Returns an existing type with an empty `cache` key.
  """
  @spec without_cache(%Type{}) :: %Type{}
  def without_cache(%Type{} = type), do: put(type, :cache, %{})

  defp check_max(list, max, error_type, context) when length(list) > max do
    [Error.with_context(error_type, put(context, :max_allowed, max)) | list]
  end

  defp check_max(list, _, _, _), do: list

  defp fetch!(_, {:ok, ok}), do: ok

  defp fetch!(name, {:error, _}) do
    raise FieldError, message: "field #{inspect(name)} not found"
  end

  defp fetch_registry(%{registry: nil} = type) do
    type_error(:no_type_registry, type)
  end

  defp field_is?(%module{}, opts) do
    module in Keyword.get(opts, :field_type, [Attribute, Relationship])
  end

  defp field_error(error, type, name, context \\ %{}) do
    type_error(error, type, Map.put(context, :key, string_name(name)))
  end

  defp fetch_registry(%{registry: registry}), do: {:ok, registry}

  defp not_found_error(type, name, opts) do
    opts
    |> Keyword.get(:error_type, :field_not_found)
    |> field_error(type, name)
  end

  defp put_in_struct(type, struct_key, map_key, value) do
    put_in(type, [Access.key(struct_key), map_key], value)
  end

  defp type_error(error, type, context \\ %{}) do
    Error.with_context(error, Map.put(context, :resource_type, type.name))
  end
end
