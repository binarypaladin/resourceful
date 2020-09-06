defmodule Resourceful.Collection.List do
  def any?(list, _ \\ []), do: Enum.any?(list)

  def all(list, _ \\ []), do: list

  def total(list, _ \\ []), do: length(list)
end

defimpl Resourceful.Collection.Delegate, for: List do
  alias Resourceful.Collection.List

  def collection(_), do: List

  def filters(_), do: List.Filters

  def paginate(list, _, -1), do: list

  def paginate(list, page, per), do: Enum.slice(list, (page - 1) * per, per)

  def sort(list, sorters) when sorters in [nil, [], ""], do: list

  def sort(list, sorters), do: List.Sort.call(list, sorters)
end
