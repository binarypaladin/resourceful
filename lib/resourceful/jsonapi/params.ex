defmodule Resourceful.JSONAPI.Params do
  @moduledoc """
  Functions for converting URL parameters into `Resourceful` queries.
  Additionally validates parameters when JSON:API-specific parameters are
  provided such as `fields`.

  While JSON:API specifically designates the format for sparse fieldsets and
  sorting, filtering and pagination is left up to the implementation. Filtering
  is build around the generic queries in Resourceful and is therefore
  opinionated in format. Pagination supports a page number and limit/offset
  strategies.

  There is currently no support for `include`.

  ## Comma-Separated Lists and Arrays

  The JSONAPI spec shows examples of
  [sparse fieldsets](https://jsonapi.org/format/#fetching-sparse-fieldsets) and
  [sorting](https://jsonapi.org/format/#fetching-sorting) using comma-separated
  strings to represent arrays of fields. In addition to the standard form, this
  library will also accept an actual array of strings. The errors that are
  returned will differ depending on the form--specifically, the `:input` and
  `:source` values. This is intentional behavior.

  For example, `sort=-field1,field2` and `sort[]=-field1&sort[]=field2` will
  return identitcal results if the fields are correct for the resource, however
  if `field1` is invalid the errors will look slightly different:

  String list:
  `{:invalid_jsonapi_field, %{input: "field1,field2", key: "field1", source: ["sort"]}}`

  Array:
  `{:invalid_jsonapi_field, %{input: "field1", key: "field1", source: ["sort", 0]}}`
  """

  alias Resourceful.{Error, Resource}
  alias Resourceful.JSONAPI.{Fields, Pagination}

  def split_string_list(input), do: String.split(input, ~r/, */)

  def validate(%Resource{} = resource, %{} = params, opts \\ []) do
    %{
      fields: validate_fields(resource, params),
      filter: validate_filter(resource, params),
      page: validate_page(params, opts),
      sort: validate_sort(resource, params)
    }
    |> Error.or_ok()
    |> case do
      {:ok, opts_map} ->
        {:ok,
         opts_map
         |> Stream.reject(fn {_, v} -> is_nil(v) end)
         |> Keyword.new()}

      errors ->
        errors
    end
  end

  def validate_fields(%Resource{} = resource, %{"fields" => %{} = fields_by_type}) do
    Fields.validate(resource, fields_by_type)
  end

  def validate_fields(_, %{"fields" => invalid}), do: invalid_input("fields", invalid)

  def validate_fields(_, _), do: nil

  def validate_filter(%Resource{} = resource, %{"filter" => %{} = filters}) do
    filters
    |> Enum.map(fn {source, input} = filter ->
      with {:error, _} = error <- Resource.validate_filter(resource, filter),
           do: Error.with_source(error, ["filter", source], %{input: input})
    end)
    |> Resource.validate_max_filters(resource, %{source: ["filter"]})
  end

  def validate_filter(_, %{"filter" => invalid}), do: invalid_input("filter", invalid)

  def validate_filter(_, _), do: nil

  def validate_page(params, opts \\ [])

  def validate_page(%{"page" => %{} = params}, opts) do
    case Pagination.validate(params, opts) do
      %{valid?: false} = changeset ->
        changeset
        |> Error.from_changeset()
        |> Error.prepend_source(:page)

      opts ->
        opts
    end
  end

  def validate_page(%{"page" => invalid}, _), do: invalid_input("page", invalid)

  def validate_page(_, _), do: nil

  def validate_sort(resource, params, context \\ %{})

  def validate_sort(resource, %{"sort" => sorters} = params, context)
      when is_binary(sorters) do
    validate_sort(
      resource,
      Map.put(params, "sort", split_string_list(sorters)),
      Map.merge(context, %{input: sorters, source: ["sort"]})
    )
  end

  def validate_sort(%Resource{} = resource, %{"sort" => sorters}, context)
      when is_list(sorters) do
    sorters
    |> Stream.with_index()
    |> Enum.map(fn {sorter, index} ->
      with {:error, _} = error <- Resource.validate_sorter(resource, sorter) do
        error
        |> Error.with_source(Map.get(context, :source) || ["sort", index])
        |> Error.with_input(Map.get(context, :input, sorter))
      end
    end)
    |> Resource.validate_max_sorters(resource, %{source: ["sort"]})
  end

  def validate_sort(_, %{"sort" => invalid}, _), do: invalid_input("sort", invalid)

  def validate_sort(_, _, _), do: nil

  defp invalid_input(param, input) do
    Error.with_input({:error, {:invalid_jsonapi_parameter, %{source: [param]}}}, input)
  end
end
