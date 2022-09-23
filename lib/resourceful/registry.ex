defmodule Resourceful.Registry do
  @doc """
  Instances of `Resourceful.Type` are intended to be used in conjunction with a
  registry in most circumstances. The application, and even the client, will
  likely understand a resource type by its string name/identifier. Types
  themselves, when associated with a registry, will be able to reference each
  other as well, which forms the basis for relationships.

  A module using the `Registry` behaviour becomes a key/value store.
  `defresourcefultype/1` allows the types to be evaluated entirely at compile
  time.
  """

  defmodule DuplicateTypeNameError do
    defexception message: "type with name already exists"
  end

  defmodule InvalidType do
    defexception message: "result of block must be a `Resourceful.Type`"
  end

  defmodule NotRegisteredError do
    defexception message: "type is not registered"
  end

  alias Resourceful.{Error, Type}
  alias Resourceful.Type.{GraphedField, Relationship}

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: [type: 1, type: 2]

      import Resourceful.Type,
        only: [
          id: 2,
          max_depth: 2,
          max_filters: 2,
          max_sorters: 2,
          meta: 3,
          name: 2,
          new: 1,
          new: 2
        ]

      import Resourceful.Type.Builders

      import Resourceful.Type.Ecto, only: [type_with_schema: 1, type_with_schema: 2]

      @before_compile {unquote(__MODULE__), :__before_compile__}

      @rtypes %{}

      def fetch(name), do: unquote(__MODULE__).fetch(all(), name)

      def fetch!(name), do: unquote(__MODULE__).fetch!(all(), name)

      def fetch_field_graph(name), do: unquote(__MODULE__).fetch(field_graphs(), name)

      def fetch_field_graph!(name), do: unquote(__MODULE__).fetch!(field_graphs(), name)

      def has_type?(name), do: Map.has_key?(all(), name)
    end
  end

  @doc """
  Builds a field graph for a `Resourceful.Type`. Since types have a `max_depth`,
  all possible graphed fields can be computed and cached at compile time when
  using a registry. This allows nested fields to be treated like local fields in
  the sense that they are available in a flat map.

  For example, a song type would have a `title` field. Once graphed, it would
  also have an `album.title` field. If the depth was set to 2, access to a field
  like `album.artist.name` would also be available.

  This prevents a lot of recursion logic from being applied at every lookup and
  by instecting the field graph for a type it's easy to see all of the possible
  mappings.

  Graphed fields are wrapped in a `Resourceful.Type.GraphedField` struct which
  contains relational information about the field in addition to the field data
  itself.

  See `Resourceful.Type.max_depth/2` for information about what is intended to
  be included in a field graph based on the depth setting.
  """
  @spec build_field_graph(%{String.t() => %Type{}}, String.t()) :: Type.field_graph()
  def build_field_graph(types_map, type_name) do
    type = Map.get(types_map, type_name)
    do_build_field_graph(%{}, types_map, type, type.max_depth, nil, nil, [])
  end

  def do_build_field_graph(field_graph, _, _, -1, _, _, _), do: field_graph

  def do_build_field_graph(
        field_graph,
        types_map,
        %Type{} = type,
        depth,
        parent,
        name_prefix,
        map_to_prefix
      ) do
    Enum.reduce(type.fields, field_graph, fn {name, field}, new_field_graph ->
      new_map_to = map_to_prefix ++ [field.map_to]
      new_name = qualify_name(name_prefix, name)

      field_data = GraphedField.new(field, new_name, new_map_to, parent)
      new_field_graph = maybe_put_field_data(new_field_graph, field_data, depth)

      case field do
        %Relationship{embedded?: embedded?, graph?: true} ->
          new_depth = if embedded?, do: depth, else: depth - 1

          do_build_field_graph(
            new_field_graph,
            types_map,
            Map.fetch!(types_map, field.related_type),
            new_depth,
            field_data,
            new_name,
            new_map_to
          )

        _ ->
          new_field_graph
      end
    end)
  end

  defp maybe_put_field_data(
         field_graph,
         %GraphedField{field: %Relationship{embedded?: false}},
         0
       ) do
    field_graph
  end

  defp maybe_put_field_data(field_graph, graphed_field, _) do
    Map.put(field_graph, graphed_field.name, graphed_field)
  end

  defp qualify_name(nil, name), do: name

  defp qualify_name(prefix, name), do: "#{prefix}.#{name}"

  @doc """
  A name can be optionally passed to the `type/2` macro. If provided, this name
  will override the name of the resource created in provided block.
  """
  @spec maybe_put_name(%Type{}, String.t() | nil) :: %Type{}
  def maybe_put_name(%Type{} = type, nil), do: type

  def maybe_put_name(%Type{} = type, name) when is_binary(name) do
    Type.name(type, name)
  end

  @spec fetch(map(), String.t()) :: {:ok, %Type{}} | Error.contextual()
  def fetch(rtypes, name) do
    case Map.get(rtypes, name) do
      nil -> Error.with_key(:resource_type_not_registered, name)
      type -> {:ok, type}
    end
  end

  @spec fetch!(map(), String.t()) :: %Type{}
  def fetch!(rtypes, name) do
    case Map.get(rtypes, name) do
      nil -> raise NotRegisteredError, "type with name `#{name}` is not registered"
      type -> type
    end
  end

  @spec fetch_field_graph(map(), String.t() | %Type{}) ::
          {:ok, %{String.t() => %GraphedField{}}} | Error.contextual()
  def fetch_field_graph(field_graphs, %Type{name: name}) do
    fetch_field_graph(field_graphs, name)
  end

  def fetch_field_graph(field_graphs, name) do
    case Map.get(field_graphs, name) do
      nil -> Error.with_key(:field_graphs_not_registered, name)
      graphed_field -> {:ok, graphed_field}
    end
  end

  @spec fetch_field_graph!(map(), String.t() | %Type{}) ::
          %{String.t() => %GraphedField{}}
  def fetch_field_graph!(field_graphs, name) do
    case Map.get(field_graphs, name) do
      nil -> raise NotRegisteredError, "field graph for `#{name}` is not registered"
      field_graph -> field_graph
    end
  end

  @doc """
  Ensures a value is a `Resourceful.Type` and that no type of the same name
  exists in the map. Raises an exception if both conditions are not met.
  """
  @spec validate_type!(any(), %{String.t() => %Type{}}) :: %Type{}
  def validate_type!(%Type{} = type, types) do
    if Map.has_key?(types, type.name) do
      raise __MODULE__.DuplicateTypeNameError,
        message: "type with name `#{type.name}` already exists"
    end

    type
  end

  def validate_type!(_, _), do: raise(__MODULE__.InvalidType)

  @doc """
  Assigns the resource specified in the `block` and makes it part of the
  registry. If `name` is provided, it will rename the resource and use that
  `name` as the key.

  If `block` does not result in a `Resourceful.Type` an exception will be
  raised.
  """
  defmacro type(name \\ nil, do: block) do
    quote do
      @rtype unquote(block)
             |> Resourceful.Type.finalize()
             |> Resourceful.Type.register(__MODULE__)
             |> unquote(__MODULE__).maybe_put_name(unquote(name))
             |> unquote(__MODULE__).validate_type!(@rtypes)

      @rtypes Map.put(@rtypes, @rtype.name, @rtype)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def all(), do: @rtypes

      @rtype_field_graphs Map.new(@rtypes, fn {name, _} ->
                            {name, unquote(__MODULE__).build_field_graph(@rtypes, name)}
                          end)

      def field_graphs(), do: @rtype_field_graphs

      @rtype_names Map.keys(@rtypes)

      def names(), do: @rtype_names
    end
  end
end
