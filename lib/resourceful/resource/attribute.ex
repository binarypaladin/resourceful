defmodule Resourceful.Resource.Attribute do
  alias __MODULE__
  alias Resourceful.Error
  alias Resourceful.Collection.Filter

  @enforce_keys [
    :filter?,
    :getter,
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
      getter: opt_getter(Keyword.get(opts, :getter)),
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
        :type_cast_failure
        |> Error.with_context(%{attribute: name, input: input, type: type})
    end
  end

  def error(%Attribute{name: name}, type, context \\ %{}),
    do: type |> Error.with_context(Map.merge(context, %{attribute: name}))

  def filter(attr, filter), do: attr |> put(:filter?, opt_bool(filter))

  def get(%Attribute{} = attr, data), do: attr |> attr.getter.(data)

  def getter(attr, getter), do: attr |> put(:getter, opt_getter(getter))

  def map_to(attr, map_to), do: attr |> put(:map_to, map_to)

  def name(attr, name), do: attr |> put(:name, opt_name(name))

  def query(attr, query), do: attr |> filter(query) |> sort(query)

  def sort(attr, sort), do: attr |> put(:sort?, opt_bool(sort))

  def type(attr, type), do: attr |> put_atom(:type, type)

  def validate_filter(%Attribute{filter?: true} = attr, op, val) do
    with {:ok, cast_val} <- cast(attr, val),
         {:ok, _} = ok <- validate_filter_operator(attr, op, cast_val),
         do: ok
  end

  def validate_filter(%Attribute{} = attr, _, _),
    do: error(attr, :cannot_filter_by_attribute)

  def validate_sorter(attr, order \\ :asc)

  def validate_sorter(%Attribute{map_to: map_to, sort?: true}, order),
    do: {:ok, {order, map_to}}

  def validate_sorter(%Attribute{} = attr, _),
    do: error(attr, :cannot_sort_by_attribute)

  defp as_atom(value) when is_atom(value), do: value

  defp as_atom(value) when is_binary(value), do: String.to_existing_atom(value)

  defp default_getter(attr, data), do: data |> Map.fetch!(attr.map_to)

  defp opt_bool(nil), do: false

  defp opt_bool(bool) when is_boolean(bool), do: bool

  defp opt_name(name) when is_atom(name), do: Kernel.to_string(name)

  defp opt_name(name) when is_binary(name), do: name

  defp opt_getter(nil), do: &default_getter/2

  defp opt_getter(func) when is_function(func, 2), do: func

  defp opts_with_query(opts) do
    cond do
      Keyword.get(opts, :query) -> [filter: true, sort: true] ++ opts
      true -> opts
    end
  end

  defp put(%Attribute{} = attr, key, value) when is_atom(key),
    do: attr |> Map.put(key, value)

  defp put_atom(attr, key, value) when is_atom(value), do: put(attr, key, value)

  defp put_atom(attr, key, value) when is_binary(value), do: put(attr, key, as_atom(value))

  defp validate_filter_operator(attr, op, val) do
    case Filter.valid_operator?(op, val) do
      true -> {:ok, {attr.map_to, op, val}}
      _ -> error(attr, :invalid_filter_operator, %{operator: op, value: val})
    end
  end
end
