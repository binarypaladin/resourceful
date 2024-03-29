defmodule Resourceful.Collection do
  @moduledoc """
  Provides a common interface for querying and retrieving collections.

  Deligated modules designed to interact directly with the underlying data or
  data sources must return alls of resources. For instance, when using `Ecto`,
  this module should return alls of structs or maps and not queries that have
  not been executed yet.

  ## Data Sources

  A `data_source` can be another from an Ecto schema, to a module that
  intteracts with a remote API, to a list as long as there is an underlying
  module to support the common interfaces. (For now, that's just Ecto.)
  """

  alias Resourceful.Collection.{Delegate, Filter, Sort}

  @default_page_size 25

  @type name() :: atom() | String.t()

  @type queryable() :: name() | {name(), name()} | Resourceful.Type.queryable()

  @type page_info() :: %{
          number: integer(),
          resources: integer(),
          size: integer(),
          total: integer()
        }

  @type with_page_info() :: {[any()], page_info()}

  @type with_page_info(type) :: {[type], page_info()}

  @doc """
  Returns a list of resources that may be filtered and sorted depending on
  on options. Resources will always be paginated.

  Args:
    * `data_source`: See module overview.
    * `opts`: Keyword list of options

  Options:
    * `filter`: See `Resourceful.Collection.Filter.call/2`
    * `page`: Pagination options.
    * `sort:`See `Resourceful.Collection.Sort.call/2`

  Additionally, see settings for the delegated module as it may take additional
  options.
  """
  @spec all(any(), keyword()) :: [any()]
  def all(data_source, opts \\ []) do
    data_source
    |> query(opts)
    |> paginate(opts)
  end

  @spec all_with_page_info(any(), keyword()) :: with_page_info()
  def all_with_page_info(data_source, opts \\ []) do
    data_source
    |> query(opts)
    |> paginate_with_info(opts)
  end

  @doc """
  Checks if `data_source` contains any resources.

  Args:
    * `data_source`: See module overview.
    * `opts`: Keyword list of options

  Options: See settings for the delegated module (e.g. `Resourceful.Collection.Ecto`).
  """
  @spec any?(any(), keyword()) :: boolean()
  def any?(data_source, opts \\ []) do
    Delegate.collection(data_source).any?(data_source, opts)
  end

  @spec default_page_size() :: integer()
  def default_page_size do
    Application.get_env(:resourceful, :default_page_size, @default_page_size)
  end

  @spec filter(any(), keyword(), keyword()) :: any()
  def filter(data_source, filters, opts \\ []) do
    data_source
    |> Filter.call(filters)
    |> delegate_all(opts)
  end

  @doc """
  Returns the total number of resources and pages based on `page_size` in a
  `data_source`.

  Args:
    * `data_source`: See module overview.
    * `opts`: Keyword list of options

  Options: See settings for the delegated module (e.g. `Resourceful.Collection.Ecto`).
  """
  @spec page_info(any(), keyword()) :: page_info()
  def page_info(data_source, opts) when is_list(opts) do
    page_info(data_source, page_size_or_default(opts), opts)
  end

  @spec page_info(any(), integer(), keyword()) :: page_info()
  def page_info(data_source, page_size, opts \\ []) when is_integer(page_size) do
    resources = total(data_source, opts)

    %{
      number: page_number_or_default(opts),
      resources: resources,
      size: page_size,
      total: ceil(resources / page_size)
    }
  end

  @spec page_number_or_default(keyword()) :: integer()
  def page_number_or_default(opts), do: get_in(opts, [:page, :number]) || 1

  @spec page_size_or_default(keyword()) :: integer()
  def page_size_or_default(opts), do: get_in(opts, [:page, :size]) || default_page_size()

  @spec paginate(any(), integer(), integer(), keyword()) :: [any()]
  def paginate(data_source, number, size, opts \\ [])
      when is_integer(number) and is_integer(size) do
    data_source
    |> Delegate.paginate(number, size)
    |> delegate_all(opts)
  end

  @spec paginate(any(), keyword()) :: [any()]
  def paginate(data_source, opts \\ []) do
    paginate(
      data_source,
      page_number_or_default(opts),
      page_size_or_default(opts),
      opts
    )
  end

  @spec paginate_with_info(any(), keyword()) :: with_page_info()
  def paginate_with_info(data_source, opts \\ []) do
    {paginate(data_source, opts), page_info(data_source, opts)}
  end

  @spec query(any(), keyword()) :: any()
  def query(data_source, opts) do
    data_source
    |> Filter.call(Keyword.get(opts, :filter, []))
    |> Sort.call(Keyword.get(opts, :sort, []))
  end

  @spec sort(any(), keyword(), keyword()) :: any()
  def sort(data_source, sorters, opts \\ []) do
    data_source
    |> Sort.call(sorters)
    |> delegate_all(opts)
  end

  @doc """
  Returns the total number of resources in a `data_source`.

  Args:
    * `data_source`: See module overview.
    * `opts`: Keyword list of options

  Options: See settings for the delegated module (e.g. `Resourceful.Collection.Ecto`).
  """
  @spec total(any(), keyword()) :: integer()
  def total(data_source, opts \\ []) do
    Delegate.collection(data_source).total(data_source, opts)
  end

  defp delegate_all(data_source, opts) do
    Delegate.collection(data_source).all(data_source, opts)
  end
end
