defmodule Resourceful.Collection.List do
  def all(list, _ \\ []), do: list

  def any?(list, _ \\ []), do: Enum.any?(list)

  def total(list, _ \\ []), do: length(list)
end

defimpl Resourceful.Collection.Delegate, for: List do
  alias Resourceful.Collection.List

  def cast_filter(_, filter), do: filter

  def cast_sorter(_, sorter), do: sorter

  def collection(_), do: List

  def filters(_), do: List.Filters

  def paginate(list, _, -1), do: list

  def paginate(list, number, size), do: Enum.slice(list, (number - 1) * size, size)

  def sort(list, sorters) when sorters in [nil, [], ""], do: list

  def sort(list, sorters), do: List.Sort.call(list, sorters)
end
