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
  regular expression filtering are omitted specifically by default. This is
  intentional.
  """

  alias Resourceful.{Collection, Error}
  alias Resourceful.Collection.Delegate

  @type t() :: {Collection.field_name(), String.t(), any()}

  @type coercible() :: t() | {String.t(), any()} | list()

  @shorthand %{
    "eq" => %{func: :equal},
    "ex" => %{func: :exclude, only: [:string, :list]},
    "gt" => %{func: :greater_than},
    "gte" => %{func: :greater_than_or_equal},
    "in" => %{func: :include, only: [:string, :list]},
    "lt" => %{func: :less_than},
    "lte" => %{func: :less_than_or_equal},
    "not" => %{func: :not_equal},
    "sw" => %{func: :starts_with, only: [:string]}
  }

  @default_op "eq"

  @doc """
  Returns a data source that is filtered in accordance with `filters`.

  If `data_source` is not an actual list of resources (e.g. an Ecto Queryable)
  underlying modules should not return a list of resources, but rather a
  filtered version of `data_source`.

  ## Args
    * `data_source`: See `Resourceful.Collection` module overview.
    * `filters`: A list of filters. See `cast/1` for a list of valid
      filters.
  """
  def call(data_source, []), do: data_source

  def call(data_source, filters) when is_list(filters),
    do: Enum.reduce(filters, data_source, &apply_filter!(&2, &1))

  def call(data_source, filters), do: call(data_source, [filters])

  @doc """
  Converts an argument into an appropriate filter parameter. A castd filter
  is a tuple of containing an atom for the field name, an atom of the function
  name that will be called by the deligated module, and the value that will
  be used for comparison.

  Filter parameters can be provded as a tuple, list, or string and will be
  castd to the appropriate format. Invalid operators and their respective
  values will result in an exception. Please see `valid_operator?/2` if you want
  to ensure client provided data is valid first.

  (Note: Should this throw an exception or should it return an :error tuple by
  default?)

  ## Examples
    cast({:age, "gte", 18})

    cast(["age", "gte", 18])

    cast(["age gte", 18])
  """

  def cast({field, op, val}) when is_binary(op), do: {:ok, {field, op, val}}

  def cast({field_and_op, val}) when is_binary(field_and_op) do
    field_and_op
    |> cast_field_and_op()
    |> Enum.concat([val])
    |> cast()
  end

  def cast({field, val}) when is_list(field) do
    cast({field, @default_op, val})
  end

  def cast([field_and_op, val]), do: cast({field_and_op, val})

  def cast(filter) when is_list(filter) and length(filter) == 3 do
    filter
    |> List.to_tuple()
    |> cast()
  end

  def cast(filter), do: Error.with_context(:invalid_filter, %{filter: filter})

  def cast!(filter) do
    case cast(filter) do
      {:ok, filter} ->
        filter

      {:error, {_, %{filter: filter}}} ->
        raise ArgumentError, message: "Cannot cast filter: #{inspect(filter)}"
    end
  end

  @spec cast_as_list?(String.t()) :: boolean()
  def cast_as_list?(op) when op in ["ex", "in"], do: true

  def cast_as_list?(_), do: false

  @doc """
  Checks whether or not an operator is valid.

  ## Args
    * `op`: Intended operator. Valid operators are keys in `@shorthand`.
  """
  def valid_operator?(op) when is_binary(op), do: Map.has_key?(@shorthand, op)

  def valid_operator?(op) when is_atom(op), do: valid_operator?(Atom.to_string(op))

  @doc """
  Checks whether or not an operator is valid in conjunction with an intended
  value. This can be used to validate the data from a client query.

  ## Args
    * `op`: See `valid_operator?/1`.
    * `val`: The value to be used with the operator. Certain operators only work
      on a subset of value types. For instance `sw` is only valid with strings.
  """
  def valid_operator?(op, val), do: valid_operator_with_type?(operator(op), val)

  defp apply_filter!(data_source, filter) do
    {field, op, val} = Delegate.cast_filter(data_source, cast!(filter))

    data_source
    |> Delegate.filters()
    |> apply(operator_func!(op), [data_source, field, val])
  end

  defp cast_field_and_op(field_and_op) when is_binary(field_and_op) do
    field_and_op
    |> String.split(" ", parts: 2)
    |> cast_field_and_op()
  end

  defp cast_field_and_op([field | []]), do: [field, "eq"]

  defp cast_field_and_op(field_and_op), do: field_and_op

  defp operator(op) when is_binary(op), do: Map.get(@shorthand, op)

  defp operator(op) when is_atom(op), do: operator(Atom.to_string(op))

  defp operator_func!(op) when is_binary(op), do: Map.fetch!(@shorthand, op).func

  defp valid_operator_with_type?(nil, _), do: false

  defp valid_operator_with_type?(%{only: only}, val) when is_binary(val) do
    Enum.member?(only, :string)
  end

  defp valid_operator_with_type?(%{only: only}, val) when is_list(val) do
    Enum.member?(only, :list)
  end

  defp valid_operator_with_type?(%{only: _}, _), do: false

  defp valid_operator_with_type?(%{}, _), do: true
end
