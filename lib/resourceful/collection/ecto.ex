defmodule Resourceful.Collection.Ecto do
  defmodule NoRepoError do
    defexception message:
                   "No Ecto.Repo has been specified! You must either " <>
                     "pass one explicity using the :ecto_repo option or you can specify a " <>
                     "global default by setting the config option :ecto_repo for :resourceful."
  end

  import Ecto.Query, only: [limit: 2], warn: false

  alias Resourceful.Collection.Ecto.NoRepoError

  @default_ecto_repo Application.get_env(:resourceful, :ecto_repo)

  def all(queryable, opts), do: repo(opts).all(queryable)

  def any?(queryable, opts), do: queryable |> limit(1) |> all(opts) |> Enum.any?()

  def total(queryable, opts), do: repo(opts).aggregate(queryable, :count)

  defp repo(opts), do: Keyword.get(opts, :ecto_repo) || @default_ecto_repo || raise(NoRepoError)
end

defimpl Resourceful.Collection.Delegate, for: Ecto.Query do
  import Ecto.Query, warn: false

  def cast_filter(_, {field, op, val}),
    do: {String.to_existing_atom(field), op, val}

  def cast_sorter(_, {order, field}), do: {order, String.to_existing_atom(field)}

  def collection(_), do: Resourceful.Collection.Ecto

  def filters(_), do: Resourceful.Collection.Ecto.Filters

  def paginate(queryable, _, -1), do: queryable

  def paginate(queryable, page, per), do: by_limit(queryable, per, (page - 1) * per)

  def sort(queryable, sorters), do: queryable |> exclude(:order_by) |> order_by(^sorters)

  defp by_limit(queryable, limit, offset), do: queryable |> limit(^limit) |> offset(^offset)
end

defimpl Resourceful.Collection.Delegate, for: Atom do
  alias Resourceful.Collection.Delegate

  def cast_filter(module, filter),
    do: module |> to_query() |> Delegate.cast_filter(filter)

  def cast_sorter(module, sorter),
    do: module |> to_query() |> Delegate.cast_sorter(sorter)

  def collection(module), do: module |> to_query() |> Delegate.collection()

  def filters(module), do: module |> to_query() |> Delegate.filters()

  def paginate(module, page, per),
    do: module |> to_query() |> Delegate.paginate(page, per)

  def sort(module, sorters), do: module |> to_query() |> Delegate.sort(sorters)

  defp to_query(module), do: Ecto.Queryable.to_query(module)
end
