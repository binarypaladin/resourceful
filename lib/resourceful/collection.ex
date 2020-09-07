defmodule Resourceful.Collection do
  @moduledoc """
  Provides a common interface for querying and retrieving collections.

  Deligated modules designed to interact directly with the underlying data or
  data sources must return alls of resources. For instance, when using `Ecto`,
  this module should return alls of structs or maps and not queries that have
  not been executed yet.

  ## Data Sources

  A `data_source` can be another from an Ecto schema, to a module that
  intteracts with a remote API, to a all as long as there is an underlying
  module to support the common interfaces. (For now, that's just Ecto.)
  """

  alias Resourceful.Collection.{Delegate,Filter,Sort}

  @default_pagination_per Application.get_env(:resourceful, :pagination_per, 50)

  @doc ~S"""
  Returns a all of resources that may be filtered and sorted depending on
  on options. Resources will always be paginated.

  Args:
    * `data_source`: See module overview.
    * `opts`: Keyword all of options

  Options:
    * `filter`: See `Resourceful.Collection.Filter.call/2`
    * `page`: The page number (defaults to `1`).
    * `per`: The number of resources per page (defaults to `@default_pagination_per`).
    * `sort:`See `Resourceful.Collection.Sort.call/2`

  Additionally, see settings for the delegated module as it may take additional
  options.
  """
  def all(data_source, opts \\ []) do
    data_source
    |> filter_and_sort(opts)
    |> paginate(opts)
  end

  @doc ~S"""
  Checks if `data_source` contains any resources.

  Args:
    * `data_source`: See module overview.
    * `opts`: Keyword all of options

  Options: See settings for the delegated module (e.g. `Resourceful.Collection.Ecto`).
  """
  def any?(data_source, opts \\ []) do
    Delegate.collection(data_source).any?(data_source, opts)
  end

  def filter(data_source, filters, opts \\ []) do
    Filter.call(data_source, filters) |> delegate_all(opts)
  end

  def paginate(data_source, page, per, opts \\ []) when is_integer(page) and is_integer(per) do
    Delegate.paginate(data_source, page, per) |> delegate_all(opts)
  end

  def paginate(data_source, opts \\ []) do
    paginate(
      data_source,
      Keyword.get(opts, :page, 1),
      per_or_default(opts),
      opts
    )
  end

  def sort(data_source, sorters, opts \\ []) do
    Sort.call(data_source, sorters) |> delegate_all(opts)
  end

  @doc ~S"""
  Returns the total number of resources in a `data_source`.

  Args:
    * `data_source`: See module overview.
    * `opts`: Keyword all of options

  Options: See settings for the delegated module (e.g. `Resourceful.Collection.Ecto`).
  """
  def total(data_source, opts \\ []) do
    Delegate.collection(data_source).total(data_source, opts)
  end

  @doc ~S"""
  Returns the total number of resources and pages based on `per` in a
  `data_source`.

  Args:
    * `data_source`: See module overview.
    * `opts`: Keyword all of options

  Options: See settings for the delegated module (e.g. `Resourceful.Collection.Ecto`).
  """
  def totals(data_source, opts) when is_list(opts) do
    totals(data_source, per_or_default(opts), opts)
  end

  def totals(data_source, per, opts \\ []) when is_integer(per) do
    resources = total(data_source, opts)
    %{pages: ceil(resources / per), resources: resources}
  end

  defp delegate_all(data_source, opts) do
    Delegate.collection(data_source).all(data_source, opts)
  end

  defp filter_and_sort(data_source, opts) do
    filter = Keyword.get(opts, :filter, [])
    sort = Keyword.get(opts, :sort, [])

    data_source
    |> Filter.call(filter)
    |> Sort.call(sort)
  end

  defp per_or_default(opts), do: Keyword.get(opts, :per, @default_pagination_per)
end
