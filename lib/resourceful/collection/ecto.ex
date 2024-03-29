defmodule Resourceful.Collection.Ecto do
  defmodule NoRepoError do
    defexception message:
                   "No Ecto.Repo has been specified! You must either " <>
                     "pass one explicity using the :ecto_repo option or you " <>
                     "can specify a global default by setting the config " <>
                     "option :ecto_repo for :resourceful."
  end

  import Ecto.Query, only: [limit: 2], warn: false

  def all(queryable, opts), do: repo(opts).all(queryable)

  def any?(queryable, opts) do
    queryable
    |> limit(1)
    |> all(opts)
    |> Enum.any?()
  end

  def total(queryable, opts), do: repo(opts).aggregate(queryable, :count)

  def repo(opts) do
    Keyword.get(opts, :ecto_repo) ||
      Application.get_env(:resourceful, :ecto_repo) ||
      raise(NoRepoError)
  end
end

defimpl Resourceful.Collection.Delegate, for: Ecto.Query do
  import Ecto.Query, warn: false

  def cast_filter(_, {field, op, val}), do: {cast_field(field), op, val}

  def cast_sorter(_, {order, field}), do: {order, cast_field(field)}

  def collection(_), do: Resourceful.Collection.Ecto

  def filters(_), do: Resourceful.Collection.Ecto.Filters

  def paginate(queryable, _, -1), do: queryable

  def paginate(queryable, number, size) do
    by_limit(queryable, size, (number - 1) * size)
  end

  def sort(queryable, sorters) do
    queryable
    |> exclude(:order_by)
    |> do_sort(sorters)
  end

  defp do_sort(queryable, sorters) do
    Enum.reduce(sorters, queryable, fn sorter, q -> apply_sorter(q, sorter) end)
  end

  defp apply_sorter(queryable, {dir, {namespace, col}}) do
    order_by(queryable, [_, {^namespace, q}], {^dir, field(q, ^col)})
  end

  defp apply_sorter(queryable, sorter), do: order_by(queryable, ^sorter)

  defp by_limit(queryable, limit, offset) do
    queryable
    |> limit(^limit)
    |> offset(^offset)
  end

  defp cast_field(%{query_alias: query_alias}), do: query_alias

  defp cast_field(%{map_to: map_to}), do: map_to

  defp cast_field({namespace, field}), do: {to_atom(namespace), to_atom(field)}

  defp cast_field(field) when is_atom(field), do: field

  defp cast_field(field)
       when is_list(field) and length(field) == 1,
       do: to_atom(hd(field))

  defp cast_field(field) when is_list(field) do
    {
      field
      |> Stream.drop(-1)
      |> Stream.map(&to_string/1)
      |> Enum.join(".")
      |> to_atom(),
      field
      |> List.last()
      |> to_atom
    }
  end

  defp cast_field(field) when is_binary(field) do
    case String.contains?(field, ".") do
      true ->
        field
        |> String.split(".")
        |> cast_field()

      _ ->
        to_atom(field)
    end
  end

  defp to_atom(field) when is_binary(field), do: String.to_existing_atom(field)

  defp to_atom(field) when is_atom(field), do: field
end

defimpl Resourceful.Collection.Delegate, for: Atom do
  alias Resourceful.Collection.Delegate

  import Ecto.Queryable, only: [to_query: 1]

  def cast_filter(module, filter) do
    module
    |> to_query()
    |> Delegate.cast_filter(filter)
  end

  def cast_sorter(module, sorter) do
    module
    |> to_query()
    |> Delegate.cast_sorter(sorter)
  end

  def collection(module) do
    module
    |> to_query()
    |> Delegate.collection()
  end

  def filters(module) do
    module
    |> to_query()
    |> Delegate.filters()
  end

  def paginate(module, number, size) do
    module
    |> to_query()
    |> Delegate.paginate(number, size)
  end

  def sort(module, sorters) do
    module
    |> to_query()
    |> Delegate.sort(sorters)
  end
end
