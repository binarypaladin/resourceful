defmodule Resourceful.Collection.List do
  def all(list, _ \\ []), do: list

  def any?(list, _ \\ []), do: Enum.any?(list)

  def total(list, _ \\ []), do: length(list)
end

defimpl Resourceful.Collection.Delegate, for: List do
  alias Resourceful.Collection.List

  def cast_filter(_, {field, op, val}), do: {cast_field(field), op, val}

  def cast_sorter(_, {order, field}), do: {order, cast_field(field)}

  def collection(_), do: List

  def filters(_), do: List.Filters

  def paginate(list, _, -1), do: list

  def paginate(list, number, size), do: Enum.slice(list, (number - 1) * size, size)

  def sort(list, sorters) when sorters in [nil, [], ""], do: list

  def sort(list, sorters), do: List.Sort.call(list, sorters)

  defp cast_field(%{map_to: map_to}), do: cast_field(map_to)

  defp cast_field(field) when is_list(field), do: Enum.map(field, &Access.key/1)

  defp cast_field(field) when is_binary(field) do
    case String.contains?(field, ".") do
      true ->
        field
        |> String.split(".")
        |> cast_field()

      _ ->
        field
    end
  end

  defp cast_field(field), do: field
end
