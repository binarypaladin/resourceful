defmodule Resourceful.Collection.Ecto.Filters do
  import Ecto.Query, warn: false

  def equal(queryable, col, nil), do: where(queryable, [q], is_nil(field(q, ^col)))

  def equal(queryable, col, val), do: where(queryable, [q], field(q, ^col) == ^val)

  def greater_than(queryable, col, val), do: where(queryable, [q], field(q, ^col) > ^val)

  def greater_than_or_equal(queryable, col, val) do
    where(queryable, [q], field(q, ^col) >= ^val)
  end

  def exclude(queryable, col, val) when is_list(val) do
    where(queryable, [q], field(q, ^col) not in ^val)
  end

  def include(queryable, col, val) when is_list(val) do
    where(queryable, [q], field(q, ^col) in ^val)
  end

  def less_than(queryable, col, val), do: where(queryable, [q], field(q, ^col) < ^val)

  def less_than_or_equal(queryable, col, val) do
    where(queryable, [q], field(q, ^col) <= ^val)
  end

  def not_equal(queryable, col, nil), do: where(queryable, [q], not is_nil(field(q, ^col)))

  def not_equal(queryable, col, val), do: where(queryable, [q], field(q, ^col) != ^val)

  def starts_with(queryable, col, val) when is_binary(val) do
    where(queryable, [q], like(field(q, ^col), ^"#{String.replace(val, "%", "\\%")}%"))
  end
end
