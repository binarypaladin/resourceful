defmodule Resourceful.Type.Attribute do
  import Map, only: [put: 3]

  alias __MODULE__
  alias Resourceful.Error
  alias Resourceful.Collection.Filter

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
      name: opt_name(name),
      sort?: opt_bool(Keyword.get(opts, :sort)),
      type: as_atom(type)
    }
  end

  def cast(%Attribute{name: name, type: type}, input) do
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

  def error(%Attribute{name: name}, type, context \\ %{}) do
    Error.with_context(type, Map.merge(context, %{attribute: name}))
  end

  def filter(attr, filter), do: put(attr, :filter?, opt_bool(filter))

  def map_to(attr, map_to), do: put(attr, :map_to, map_to)

  def name(attr, name), do: put(attr, :name, opt_name(name))

  def query(attr, query) do
    attr
    |> filter(query)
    |> sort(query)
  end

  def sort(attr, sort), do: put(attr, :sort?, opt_bool(sort))

  def type(attr, type), do: put_atom(attr, :type, type)

  def validate_filter(%Attribute{filter?: true} = attr, op, val) do
    with {:ok, cast_val} <- cast(attr, val),
         {:ok, _} = ok <- validate_filter_operator(attr, op, cast_val),
         do: ok
  end

  def validate_filter(%Attribute{} = attr, _, _) do
    error(attr, :cannot_filter_by_attribute)
  end

  def validate_sorter(attr, order \\ :asc)

  def validate_sorter(%Attribute{map_to: map_to, sort?: true}, order) do
    {:ok, {order, map_to}}
  end

  def validate_sorter(%Attribute{} = attr, _) do
    error(attr, :cannot_sort_by_attribute)
  end

  defp as_atom(value) when is_atom(value), do: value

  defp as_atom(value) when is_binary(value), do: String.to_existing_atom(value)

  defp opt_bool(nil), do: false

  defp opt_bool(bool) when is_boolean(bool), do: bool

  defp opt_name(name) when is_atom(name), do: to_string(name)

  defp opt_name(name) when is_binary(name), do: name

  defp opts_with_query(opts) do
    cond do
      Keyword.get(opts, :query) -> Keyword.merge(opts, filter: true, sort: true)
      true -> opts
    end
  end

  defp put_atom(attr, key, value) when is_atom(value), do: put(attr, key, value)

  defp put_atom(attr, key, value) when is_binary(value), do: put(attr, key, as_atom(value))

  defp validate_filter_operator(attr, op, val) do
    case Filter.valid_operator?(op, val) do
      true -> {:ok, {attr.map_to, op, val}}
      _ -> error(attr, :invalid_filter_operator, %{operator: op, value: val})
    end
  end
end
