defmodule Resourceful.Type.Attribute do
  @moduledoc """
  Attributes represent "value" fields for a given `Resourceful.Type`. This
  governs a few common operations:

  ## Casting Inputs

  Values will often come in the form of strings from the edge. Attributes use
  Ecto's typecasting to cast inputs into proper datatype or return appropriate
  errors.

  ## Mapping to Underlying Resources

  Generally speaking, outside representation of resources will use strings as
  keys on maps whereas internal structures tend to be atoms. Additionally,
  internal structures will often use snake case whereas external structures may
  take multiple forms (e.g. camel case or dasherized when dealing with
  JSON:API). Attributes map values to their appropriate internal keys.

  ## Configuring Queries

  APIs may choose to restrict what attributes can be filtered and sorted. For
  instance, you make wish to only allow public queries against indexed
  attributes or none at all.

  This allows the system restrict access and return meaningful errors when a
  client attempts to query against an attribute.
  """

  import Map, only: [put: 3]

  alias __MODULE__
  alias Resourceful.{Error, Type}
  alias Resourceful.Collection.Filter
  alias Resourceful.Type.GraphedField

  @enforce_keys [
    :filter?,
    :map_to,
    :name,
    :sort?,
    :type
  ]

  defstruct @enforce_keys

  @doc """
  Creates a new attribute, coerces values, and sets defaults.
  """
  @spec new(String.t(), atom(), keyword()) :: %Attribute{}
  def new(name, type, opts \\ []) do
    opts = opts_with_query(opts)
    map_to = Keyword.get(opts, :map_to) || as_atom(name)

    %Attribute{
      filter?: opt_bool(Keyword.get(opts, :filter)),
      map_to: Type.validate_map_to!(map_to),
      name: Type.validate_name!(name),
      sort?: opt_bool(Keyword.get(opts, :sort)),
      type: as_atom(type)
    }
  end

  @doc """
  Casts an input into an attribute's type. If `cast_as_list` is true, it will
  wrap the attribute's type in a list. This is specifically for dealing with
  filters that take a list of values.
  """
  @spec cast(Type.queryable(), any(), boolean()) :: {:ok, any()} | Error.t()
  def cast(attr_or_graph, input, cast_as_list \\ false)

  def cast(%Attribute{name: name, type: type}, input, cast_as_list) do
    do_cast(name, type, input, cast_as_list)
  end

  def cast(%GraphedField{field: %Attribute{type: type}, name: name}, input, cast_as_list) do
    do_cast(name, type, input, cast_as_list)
  end

  defp do_cast(name, type, input, cast_as_list) do
    {type, input} =
      case cast_as_list do
        true -> {{:array, type}, List.wrap(input)}
        _ -> {type, input}
      end

    case Ecto.Type.cast(type, input) do
      {:ok, _} = ok ->
        ok

      _ ->
        Error.with_context(
          :type_cast_failure,
          %{attribute: name, input: input, type: type}
        )
    end
  end

  @doc """
  Creates a contextual error wthe attribute's name in the context.
  """
  @spec error(Type.queryable(), atom(), map()) :: Error.contextual()
  def error(%{name: name}, error_type, context \\ %{}) do
    Error.with_context(error_type, Map.merge(context, %{attribute: name}))
  end

  @doc """
  Sets the `filter?` key for an attribute. Collections cannot be filtered by an
  attribute unless this is set to `true`.
  """
  @spec filter(%Attribute{}, boolean()) :: %Attribute{}
  def filter(attr, filter), do: put(attr, :filter?, opt_bool(filter))

  @doc """
  Sets the `map_to` key for an attribute. `map_to` is the key of the underlying
  map to use in place of the attribute's actual `name`. Unlike a `name` which
  can only be a string, this can be an atom or a string (dots allowed).
  """
  @spec map_to(%Attribute{}, atom() | String.t()) :: %Attribute{}
  def map_to(attr, map_to) when is_atom(map_to) or is_binary(map_to) do
    put(attr, :map_to, Type.validate_map_to!(map_to))
  end

  @doc """
  Sets the name for the attribute. This is the "edge" name that clients will
  interact with. It can be any string as long as it doesn't contain dots. This
  will also serve as its key name if used in conjunction with a
  `Resourceful.Type` which is important in that names must be unique within a
  type.
  """
  @spec name(%Attribute{}, String.t()) :: %Attribute{}
  def name(attr, name), do: put(attr, :name, Type.validate_name!(name))

  @doc """
  A shortcut for setting both `filter?` and `sort?` to the same value.
  """
  @spec query(%Attribute{}, boolean()) :: %Attribute{}
  def query(attr, query) do
    attr
    |> filter(query)
    |> sort(query)
  end

  @doc """
  Sets the `sort?` key for an attribute. Collections cannot be sorted by an
  attribute unless this is set to `true`.
  """
  @spec sort(%Attribute{}, boolean()) :: %Attribute{}
  def sort(attr, sort), do: put(attr, :sort?, opt_bool(sort))

  @doc """
  Sets the data type for casting. This must be an `Ecto.Type` or atom that works
  in its place such as `:string`.
  """
  @spec type(%Attribute{}, atom()) :: %Attribute{}
  def type(attr, type), do: put_atom(attr, :type, type)

  @doc """
  Validates a filter against the attribute and the data given. It ensures the
  data type is correct for the operator and that the attribute allows filtering
  at all.
  """
  @spec validate_filter(Type.queryable(), String.t(), any()) :: {:ok, Filter.t()} | Error.t()
  def validate_filter(attr_or_graph, op, val) do
    with :ok <- check_query_attr(attr_or_graph, :filter?, :cannot_filter_by_attribute),
         {:ok, cast_val} <- cast(attr_or_graph, val, Filter.cast_as_list?(op)),
         {:ok, _} = ok <- validate_filter_with_operator(attr_or_graph, op, cast_val),
         do: ok
  end

  @doc """
  Validates a sorter against the attribute ensuring that sorting is allowed for
  the attribute.
  """
  @spec validate_sorter(Type.queryable(), :asc | :desc) :: {:ok, Sort.t()} | Error.t()
  def validate_sorter(attr_or_graph, order \\ :asc)

  def validate_sorter(attr_or_graph, order) do
    with :ok <- check_query_attr(attr_or_graph, :sort?, :cannot_sort_by_attribute),
         do: {:ok, {order, attr_or_graph}}
  end

  defp as_atom(value) when is_atom(value), do: value

  defp as_atom(value) when is_binary(value), do: String.to_existing_atom(value)

  defp check_query_attr(attr_or_graph, key, error_type) do
    attr =
      case attr_or_graph do
        %Attribute{} = attr -> attr
        %GraphedField{field: %Attribute{} = attr} -> attr
      end

    case Map.get(attr, key) do
      true -> :ok
      _ -> error(attr_or_graph, error_type)
    end
  end

  defp opt_bool(nil), do: false

  defp opt_bool(bool) when is_boolean(bool), do: bool

  defp opts_with_query(opts) do
    cond do
      Keyword.get(opts, :query) -> Keyword.merge(opts, filter: true, sort: true)
      true -> opts
    end
  end

  defp put_atom(attr, key, value) when is_atom(value), do: put(attr, key, value)

  defp put_atom(attr, key, value) when is_binary(value), do: put(attr, key, as_atom(value))

  defp validate_filter_with_operator(attr_or_graph, op, val) do
    case Filter.valid_operator?(op, val) do
      true -> {:ok, {attr_or_graph, op, val}}
      _ -> error(attr_or_graph, :invalid_filter_operator, %{operator: op, value: val})
    end
  end
end
