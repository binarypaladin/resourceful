defmodule Resourceful.Type.Attribute do
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

  def new(name, type, opts \\ []) do
    opts = opts_with_query(opts)

    %Attribute{
      filter?: opt_bool(Keyword.get(opts, :filter)),
      map_to: Keyword.get(opts, :map_to) || as_atom(name),
      name: Type.validate_name!(name),
      sort?: opt_bool(Keyword.get(opts, :sort)),
      type: as_atom(type)
    }
  end

  def cast(attr_or_graph, input, cast_as_list \\ false)

  def cast(%Attribute{name: name, type: type}, input, cast_as_list) do
    do_cast(name, type, input, cast_as_list)
  end

  def cast(%GraphedField{field: %Attribute{type: type}, name: name}, input, cast_as_list) do
    do_cast(name, type, input, cast_as_list)
  end

  defp do_cast(name, type, input, cast_as_list) do
    cast_type = if cast_as_list, do: {:array, type}, else: type

    case Ecto.Type.cast(cast_type, input) do
      {:ok, _} = ok ->
        ok

      _ ->
        Error.with_context(
          :type_cast_failure,
          %{attribute: name, input: input, type: type}
        )
    end
  end

  def error(%{name: name}, error_type, context \\ %{}) do
    Error.with_context(error_type, Map.merge(context, %{attribute: name}))
  end

  def filter(attr, filter), do: put(attr, :filter?, opt_bool(filter))

  def map_to(attr, map_to), do: put(attr, :map_to, map_to)

  def name(attr, name), do: put(attr, :name, Type.validate_name!(name))

  def query(attr, query) do
    attr
    |> filter(query)
    |> sort(query)
  end

  def sort(attr, sort), do: put(attr, :sort?, opt_bool(sort))

  def type(attr, type), do: put_atom(attr, :type, type)

  def validate_filter(attr_or_graph, op, val) do
    with :ok <- check_query_attr(attr_or_graph, :filter?, :cannot_filter_by_attribute),
         {:ok, cast_val} <- cast(attr_or_graph, val, Filter.cast_as_list?(op)),
         {:ok, _} = ok <- validate_filter_with_operator(attr_or_graph, op, cast_val),
         do: ok
  end

  def validate_sorter(attr, order \\ :asc)

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
