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

  alias Resourceful.Collection.{Delegate, Filter, Sort}

  @default_page_size 25

  @doc """
  Returns a all of resources that may be filtered and sorted depending on
  on options. Resources will always be paginated.

  Args:
    * `data_source`: See module overview.
    * `opts`: Keyword all of options

  Options:
    * `filter`: See `Resourceful.Collection.Filter.call/2`
    * `page`: Pagination options.
    * `sort:`See `Resourceful.Collection.Sort.call/2`

  Additionally, see settings for the delegated module as it may take additional
  options.
  """
  def all(data_source, opts \\ []) do
    data_source
    |> filter_and_sort(opts)
    |> paginate(opts)
  end

  @doc """
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
    data_source
    |> Filter.call(filters)
    |> delegate_all(opts)
  end

  def paginate(data_source, number, size, opts \\ [])
      when is_integer(number) and is_integer(size) do
    data_source
    |> Delegate.paginate(number, size)
    |> delegate_all(opts)
  end

  def paginate(data_source, opts \\ []) do
    paginate(
      data_source,
      get_in(opts, [:page, :number]) || 1,
      page_size_or_default(opts),
      opts
    )
  end

  def sort(data_source, sorters, opts \\ []) do
    data_source
    |> Sort.call(sorters)
    |> delegate_all(opts)
  end

  @doc """
  Returns the total number of resources in a `data_source`.

  Args:
    * `data_source`: See module overview.
    * `opts`: Keyword all of options

  Options: See settings for the delegated module (e.g. `Resourceful.Collection.Ecto`).
  """
  def total(data_source, opts \\ []) do
    Delegate.collection(data_source).total(data_source, opts)
  end

  @doc """
  Returns the total number of resources and pages based on `page_size` in a
  `data_source`.

  Args:
    * `data_source`: See module overview.
    * `opts`: Keyword all of options

  Options: See settings for the delegated module (e.g. `Resourceful.Collection.Ecto`).
  """
  def totals(data_source, opts) when is_list(opts) do
    totals(data_source, page_size_or_default(opts), opts)
  end

  def totals(data_source, page_size, opts \\ []) when is_integer(page_size) do
    resources = total(data_source, opts)
    %{pages: ceil(resources / page_size), resources: resources}
  end

  defp default_page_size() do
    Application.get_env(:resourceful, :default_page_size, @default_page_size)
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

  defp page_size_or_default(opts), do: get_in(opts, [:page, :size]) || default_page_size()
end
