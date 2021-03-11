defmodule Resourceful.Collection.List.Sort do
  def call(list, sorters) do
    list
    |> Enum.sort(fn x, y ->
      sorters
      |> to_sorters()
      |> Enum.any?(&sort_with_sorters(&1, x, y))
    end)
  end

  def asc(%module{} = x, %module{} = y), do: module.compare(x, y) == :lt

  def asc(x, y), do: x < y

  def desc(%module{} = x, %module{} = y), do: module.compare(x, y) == :gt

  def desc(x, y), do: x > y

  def eq(%module{} = x, %module{} = y), do: module.compare(x, y) == :eq

  def eq(x, y), do: x == y

  def get_val(resource, keys) when is_list(keys), do: get_in(resource, keys)

  def get_val(resource, keys), do: Map.get(resource, keys)

  def to_sorter([head | []]), do: [head]

  def to_sorter([{_, key} | tail]), do: [{:eq, key}] ++ to_sorter(tail)

  def to_sorters(sorters, all \\ [])

  def to_sorters([], all), do: Enum.reverse(all)

  def to_sorters(sorters, all) when is_list(all) do
    sorters
    |> Enum.drop(-1)
    |> to_sorters(all ++ [to_sorter(sorters)])
  end

  defp apply_sorter({op, keys}, x, y) do
    apply(__MODULE__, op, [get_val(x, keys), get_val(y, keys)])
  end

  defp sort_with_sorters(sorters, x, y), do: Enum.all?(sorters, &apply_sorter(&1, x, y))
end
