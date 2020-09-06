defmodule Resourceful.Collection.List.Filter do
  alias Resourceful.Collection.List.Sort

  def equal(list, k, v), do: list |> filter(k, &eq(&1, v))

  def exclude(list, k, v), do: list |> filter(k, &(!Enum.member?(v, &1)))

  def greater_than(list, k, v), do: list |> filter(k, &gt(&1, v))

  def greater_than_or_equal(list, k, v), do: list |> filter(k, &gte(&1, v))

  def include(list, k, v), do: list |> filter(k, &Enum.member?(v, &1))

  def less_than(list, k, v), do: list |> filter(k, &lt(&1, v))

  def less_than_or_equal(list, k, v), do: list |> filter(k, &lte(&1, v))

  def not_equal(list, k, v), do: list |> filter(k, &(!eq(&1, v)))

  def starts_with(list, k, v), do: list |> filter(k, &String.starts_with?(&1, v))

  defp eq(x, y), do: Sort.eq(x, y)

  defp filter(list, k, func), do: list |> Enum.filter(&func.(Map.get(&1, k)))

  defp gt(x, y), do: Sort.desc(x, y)

  defp gte(x, y), do: eq(x, y) or gt(x, y)

  defp lt(x, y), do: Sort.asc(x, y)

  defp lte(x, y), do: eq(x, y) or lt(x, y)
end
