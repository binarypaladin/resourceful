defmodule Resourceful.Test.Helpers do
  alias Resourceful.Test.Repo

  def all_by(%Ecto.Query{} = queryable, key), do: queryable |> Repo.all() |> all_by(key)

  def all_by(list, key), do: list |> Enum.map(fn(map) -> map |> Map.get(key) end)

  def at(list, index), do: list |> Enum.at(index)

  def first(list) when is_list(list), do: list |> List.first()

  def first(list, key) when is_atom(key), do: first(list) |> Map.get(key)

  def ids(data_source), do: data_source |> all_by(:id)

  def last(list) when is_list(list), do: list |> List.last()

  def last(list, key) when is_atom(key), do: last(list) |> Map.get(key)
end
