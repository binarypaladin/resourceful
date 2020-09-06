defmodule Resourceful.Collection.Sort do
  @moduledoc """
  Provides a common interface for sorting collections. See `call/2` for use and
  examples.

  This module is intended to dispatch arguments to the appropriate `Sort` module
  for the underlying data source.
  """

  alias Resourceful.Collection.Delegate

  @doc ~S"""
  Returns a data source that is sorted in accordance with `sorters`.

  If `data_source` is not an actual list of resources (e.g. an Ecto Queryable)
  underlying modules should not return a list of resources, but rather a sorted
  version of `data_source`.

  ## Args
    * `data_source`: See `Resourceful.Collection` module overview.
    * `sorters`: A list or comma separated string of sort parameters. Sort
      parameters should be the string name of a field preceded by, optionally, a
      `+` for ascending order (the default) or a `-` for descending order or.
      Examples of `sorters`:
      - `"name,-age"`
      - `["+name", "-age"]`
  """
  def call(data_source, sorters) when sorters in [nil, [], ""], do: data_source

  def call(data_source, sorters) do
    Delegate.sort(data_source).call(data_source, to_sorters(sorters))
  end

  def to_sorter("+" <> field), do: to_sorter({field, :asc})

  def to_sorter("-" <> field), do: to_sorter({field, :desc})

  def to_sorter(field) when is_binary(field), do: to_sorter({field, :asc})

  def to_sorter({field, order} = t) when order in ~w[asc desc]a and is_atom(field), do: t

  def to_sorter({field, order}) when is_binary(field) do
    {String.to_existing_atom(field), order} |> to_sorter()
  end

  def to_sorters(fields) when is_list(fields), do: Enum.map(fields, &to_sorter/1)

  def to_sorters(field), do: to_sorters([field])
end
