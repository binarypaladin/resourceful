defmodule Resourceful.Collection.Sort do
  @moduledoc """
  Provides a common interface for sorting collections. See `call/2` for use and
  examples.

  This module is intended to dispatch arguments to the appropriate `Sort` module
  for the underlying data source.
  """

  alias Resourceful.Collection.Delegate
  alias Resourceful.Error

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
  def call(data_source, sorters) do
    sorters =
      sorters
      |> all()
      |> Enum.map(&Delegate.cast_sorter(data_source, &1))

    Delegate.sort(data_source, sorters)
  end

  def all(fields) when is_list(fields), do: Enum.map(fields, &cast!/1)

  def all(string) when is_binary(string), do: string |> string_list() |> all()

  def all(field), do: all([field])

  def cast("+" <> field), do: cast({:asc, field})

  def cast("-" <> field), do: cast({:desc, field})

  def cast({order, _} = sorter) when order in [:asc, :desc], do: {:ok, sorter}

  def cast(sorter) when is_binary(sorter) or is_atom(sorter), do: cast({:asc, sorter})

  def cast(sorter), do: :invalid_sorter |> Error.with_context(%{sorter: sorter})

  def cast!(sorter) do
    case cast(sorter) do
      {:ok, sorter} ->
        sorter

      {:error, {_, %{sorter: sorter}}} ->
        raise ArgumentError, message: "Cannot cast sorter: #{Kernel.inspect(sorter)}"
    end
  end

  def string_list(string) when is_binary(string), do: string |> String.split(~r/, */)
end
