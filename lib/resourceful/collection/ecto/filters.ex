defmodule Resourceful.Collection.Ecto.Filters do
  @moduledoc """
  Functions for converting Resourceful-style filters into Ecto-style SQL
  filters.

  See `Resourceful.Collection.Filter` for more details on filters.

  There's a lot of duplication here that can, hopefully, be resolved with a
  better understanding of macros.
  """

  import Ecto.Query, warn: false

  def equal(queryable, {alias_name, col}, nil) do
    where(queryable, [_, {^alias_name, q}], is_nil(field(q, ^col)))
  end

  def equal(queryable, {alias_name, col}, val) do
    where(queryable, [_, {^alias_name, q}], field(q, ^col) == ^val)
  end

  def equal(queryable, col, nil), do: where(queryable, [q], is_nil(field(q, ^col)))

  def equal(queryable, col, val), do: where(queryable, [q], field(q, ^col) == ^val)

  def greater_than(queryable, {alias_name, col}, val) do
    where(queryable, [_, {^alias_name, q}], field(q, ^col) > ^val)
  end

  def greater_than(queryable, col, val), do: where(queryable, [q], field(q, ^col) > ^val)

  def greater_than_or_equal(queryable, {alias_name, col}, val) do
    where(queryable, [_, {^alias_name, q}], field(q, ^col) >= ^val)
  end

  def greater_than_or_equal(queryable, col, val) do
    where(queryable, [q], field(q, ^col) >= ^val)
  end

  def exclude(queryable, {alias_name, col}, val) when is_list(val) do
    where(queryable, [_, {^alias_name, q}], field(q, ^col) not in ^val)
  end

  def exclude(queryable, col, val) when is_list(val) do
    where(queryable, [q], field(q, ^col) not in ^val)
  end

  def include(queryable, {alias_name, col}, val) when is_list(val) do
    where(queryable, [_, {^alias_name, q}], field(q, ^col) in ^val)
  end

  def include(queryable, col, val) when is_list(val) do
    where(queryable, [q], field(q, ^col) in ^val)
  end

  def less_than(queryable, {alias_name, col}, val) do
    where(queryable, [_, {^alias_name, q}], field(q, ^col) < ^val)
  end

  def less_than(queryable, col, val), do: where(queryable, [q], field(q, ^col) < ^val)

  def less_than_or_equal(queryable, {alias_name, col}, val) do
    where(queryable, [_, {^alias_name, q}], field(q, ^col) <= ^val)
  end

  def less_than_or_equal(queryable, col, val) do
    where(queryable, [q], field(q, ^col) <= ^val)
  end

  def not_equal(queryable, {alias_name, col}, nil) do
    where(queryable, [_, {^alias_name, q}], not is_nil(field(q, ^col)))
  end

  def not_equal(queryable, {alias_name, col}, val) do
    where(queryable, [_, {^alias_name, q}], field(q, ^col) != ^val)
  end

  def not_equal(queryable, col, nil), do: where(queryable, [q], not is_nil(field(q, ^col)))

  def not_equal(queryable, col, val), do: where(queryable, [q], field(q, ^col) != ^val)

  def starts_with(queryable, {alias_name, col}, val) when is_binary(val) do
    where(
      queryable,
      [_, {^alias_name, q}],
      like(field(q, ^col), ^"#{String.replace(val, "%", "\\%")}%")
    )
  end

  def starts_with(queryable, col, val) when is_binary(val) do
    where(queryable, [q], like(field(q, ^col), ^"#{String.replace(val, "%", "\\%")}%"))
  end
end
