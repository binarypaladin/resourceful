defmodule Resourceful.Test.Helpers do
  alias Resourceful.Test.Repo

  def all_by(%Ecto.Query{} = queryable, key) do
    queryable
    |> Repo.all()
    |> all_by(key)
  end

  def all_by(list, key), do: Enum.map(list, &Map.get(&1, key))

  def at(list, index), do: Enum.at(list, index)

  def first(list) when is_list(list), do: List.first(list)

  def first(list, key) when is_atom(key) do
    list
    |> first()
    |> Map.get(key)
  end

  def id(map), do: Map.fetch!(map, "id")

  def ids(%Ecto.Query{} = queryable), do: all_by(queryable, :id)

  def ids(list), do: all_by(list, "id")

  def last(list) when is_list(list), do: List.last(list)

  def last(list, key) when is_atom(key) do
    list
    |> last()
    |> Map.get(key)
  end
end
