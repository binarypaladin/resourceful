defmodule Resourceful.Collection.Filter do
  @moduledoc """
  Provides a common interface for filtering collections. See `call/2` for use
  and examples.

  This module is intended to dispatch arguments to the appropriate `Filter`
  module for the underlying data source.

  Filtering is not meant to replace and be anything even resembling feature
  complete with more robust querying options provided by various databases. As
  The focus is on edge-facing APIs, generally web-based APIs, filthering is
  meant to be much simpler and more predictable. For instance, wildcard and
  regular expression filtering is omitted specifically by default. This is quite
  intentional.

  For more natural language-centric queries, `Resourceful.Collection.Search`
  should be used instead so that the underlying data sources can be
  appropriately optimized.

  (`Search` doesn't exist yet and as of now, the query options are static, but
  this will change in the future.)
  """

  alias Resourceful.Collection.Delegate

  @shorthand %{
    "eq"  => %{func: :equal},
    "ex"  => %{func: :exclude, only: [:binary, :list]},
    "gt"  => %{func: :greater_than},
    "gte" => %{func: :greater_than_or_equal},
    "in"  => %{func: :include, only: [:binary, :list]},
    "lt"  => %{func: :less_than},
    "lte" => %{func: :less_than_or_equal},
    "not" => %{func: :not_equal},
    "sw"  => %{func: :starts_with, only: [:binary]}
  }

  @doc ~S"""
  Returns a data source that is filtered in accordance with `filters`.

  If `data_source` is not an actual list of resources (e.g. an Ecto Queryable)
  underlying modules should not return a list of resources, but rather a
  filtered version of `data_source`.

  ## Args
    * `data_source`: See `Resourceful.Collection` module overview.
    * `filters`: A list of filters. See `to_filter/1` for a list of valid
      filters.
  """
  def call(data_source, []), do: data_source

  def call(data_source, filters) when is_list(filters) do
    filters |> Enum.reduce(data_source, &(apply_filter(&2, &1)))
  end

  def call(data_source, filters), do: call(data_source, [filters])

  @doc ~S"""
  Converts an argument into an appropriate filter parameter. A to_filterd filter
  is a tuple of containing an atom for the field name, an atom of the function
  name that will be called by the deligated module, and the value that will
  be used for comparison.

  Filter parameters can be provded as a tuple, list, or string and will be
  to_filterd to the appropriate format. Invalid operators and their respective
  values will result in an exception. Please see `valid_operator?/2` if you want
  to ensure client provided data is valid first.

  (Note: Should this throw an exception or should it return an :error tuple by
  default?)

  ## Examples
    to_filter({:age, "gte", 18})

    to_filter(["age", "gte", 18])

    to_filter(["age gte", 18])

    to_filter("age gta 18")
  """
  def to_filter({field, op, _} = filter) when is_atom(field) and is_binary(op), do: filter

  def to_filter({field, op, val}), do: {field(field), operator_func!(op), val}

  def to_filter(filter) when is_list(filter) and length(filter) == 3 do
    List.to_tuple(filter) |> to_filter()
  end

  def to_filter([field_and_op, val]) do
    (String.split(field_and_op, " ", parts: 2) ++ [val]) |> to_filter()
  end

  def to_filter(filter) when is_binary(filter) do
    filter |> String.split(" ", parts: 3) |> to_filter()
  end

  @doc ~S"""
  Checks whether or not an operator is valid.

  ## Args
    * `op`: Intended operator. Valid operators are keys in `@shorthand`.
  """
  def valid_operator?(op) when is_binary(op), do: Map.has_key?(@shorthand, op)

  def valid_operator?(op) when is_atom(op), do: valid_operator?(Atom.to_string(op))

  @doc ~S"""
  Checks whether or not an operator is valid in conjunction with an intended
  value. This can be used to validate the data from a client query.

  ## Args
    * `op`: See `valid_operator?/1`.
    * `val`: The value to be used with the operator. Certain operators only work
      on a subset of value types. For instance `sw` is only valid with strings.
  """
  def valid_operator?(op, val), do: valid_operator_with_type?(operator(op), val)

  defp apply_filter(data_source, filter) do
    {field, operator, val} = to_filter(filter)

    data_source
    |> Delegate.filters
    |> Kernel.apply(operator, [data_source, field, val])
  end

  defp field(f) when is_atom(f), do: f

  defp field(f) when is_binary(f), do: String.to_existing_atom(f)

  defp operator(op) when is_binary(op), do: Map.get(@shorthand, op)

  defp operator(op) when is_atom(op), do: operator(Atom.to_string(op))

  defp operator_func!(op) when is_binary(op), do: Map.fetch!(@shorthand, op).func

  defp operator_func!(op) when is_atom(op), do: operator_func!(Atom.to_string(op))

  defp valid_operator_with_type?(nil, _), do: false

  defp valid_operator_with_type?(%{only: only}, val) when is_binary(val) do
    Enum.member?(only, :binary)
  end

  defp valid_operator_with_type?(%{only: only}, val) when is_list(val) do
    Enum.member?(only, :list)
  end

  defp valid_operator_with_type?(%{only: _}, _), do: false

  defp valid_operator_with_type?(%{}, _), do: true
end
