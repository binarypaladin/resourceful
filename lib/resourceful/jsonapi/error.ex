defmodule Resourceful.JSONAPI.Error do
  @moduledoc """
  Tools for converting errors formatted in accordance with `Resourceful.Error`
  into [JSON API-style errors](https://jsonapi.org/format/#errors).

  JSON API errors have a number of reserved top-level names:

    * `code`
    * `detail`
    * `id`
    * `links`
    * `meta`
    * `source`
    * `status`
    * `title`

  Resourceful errors map to JSON API errors as follows:

  An error's `type` symbol is converted to a string for `code`. With the
  exception of `meta` and `status` the remainder of keys in an error's `context`
  are mapped to either the top-level attribute of the same name or, in the event
  the name is not a reserved name, it will be placed in `meta` which, if
  present, will always be a map.

  `status` is a bit of a special case as "status" in a JSON API error always
  refers to an HTTP status code, but it's quite possible many errors might have
  a `status` attribute in their context that has nothing to do with HTTP. As
  such, `:http_status` may be passed either as an option or as a key in a
  context map.
  """

  @default_source_type "pointer"

  @error_type_defaults Application.get_env(:resourceful, :error_type_defaults)

  @reserved_names ~w[
    code
    detail
    id
    links
    meta
    source
    status
    title
  ]a

  @doc """
  Takes a list of errors, or an `:error` tuple with a list as the second
  element, and converts that list to JSON API errors.
  """
  def all(errors, opts \\ [])

  def all({:error, errors}, opts), do: all(errors, opts)

  def all(errors, opts) when is_list(errors),
    do: errors |> Enum.map(&to_map(&1, opts))

  @doc """
  Returns a map of all non-reserved attributes from a context map.
  """
  def meta(error, opts \\ [])

  def meta({:error, {_, %{} = context}}, opts), do: meta(context, opts)

  def meta(%{} = context, _) do
    meta = context |> Map.drop(@reserved_names) |> stringify_keys()

    case Enum.any?(meta) do
      true -> meta
      _ -> nil
    end
  end

  def meta({:error, _}, _), do: nil

  @doc """
  Returns a JSON API source map based on the `:source` attribute in a an error's
  context map.
  """
  def source(error, source_type \\ @default_source_type)

  def source(error, opts) when is_list(opts),
    do: source(error, Keyword.get(opts, :source_type, @default_source_type))

  def source({:error, {_, %{source: source}}}, source_type),
    do: %{source_type => source |> source_string(source_type)}

  def source({:error, _}, _), do: nil

  @doc """
  Returns a JSON API source map. Either:
    1. `%{"pointer" => "/data/attributes/problem"}`
    2. `%{"parameter" => "fields[resource]"}`
  """
  def source_string(source, source_type) when is_list(source) do
    str_sources = source |> Enum.map(&to_string/1)

    case source_type do
      "parameter" -> str_sources |> parameter_source()
      "pointer" -> str_sources |> pointer_source()
    end
  end

  @doc """
  Returns the appropriate `status` attribute based on either the context map or
  an explicitly passed `:http_status` option. The value in a context takes
  precedence. The reason for this is that the keyword will often be used in
  conjunction with `all/2` to apply a default but certain errors, when a
  situation allows for mixed errors with statuses, will want to be set
  explicitly apart from the default.
  """
  def status(error, opts \\ [])

  def status({:error, {_, %{http_status: status}}}, _), do: status |> to_string()

  def status({:error, {type, _}}, opts), do: status(type, opts)

  def status({:error, type}, opts), do: status(type, opts)

  def status(type, opts) when is_atom(type) do
    (Keyword.get(opts, :http_status) ||
       get_in(@error_type_defaults, [type, :http_status]))
    |> to_status()
  end

  def status(_, _), do: nil

  @doc """
  Converts a Resourceful error into a JSON API error map which can then be
  converted to JSON. See module overview for details on conventions.
  """
  def to_map(error, opts \\ [])

  def to_map({:error, {_, %{}}} = error, opts) do
    [:meta, :source, :status]
    |> Enum.reduce(base_error(error, opts), fn key, jerr ->
      apply_jsonapi_error_key(jerr, key, error, opts)
    end)
  end

  def to_map({:error, _} = error, opts),
    do: error |> Resourceful.Error.with_context() |> to_map(opts)

  defp apply_jsonapi_error_key(jsonapi_error, key, {:error, _} = error, opts) do
    case apply(__MODULE__, key, [error, opts]) do
      nil -> jsonapi_error
      value -> jsonapi_error |> Map.put(to_string(key), value)
    end
  end

  defp base_error({:error, {type, %{}}} = error, opts) do
    error
    |> Resourceful.Error.humanize(opts)
    |> Resourceful.Error.context()
    |> Map.take(@reserved_names)
    |> stringify_keys()
    |> Map.put("code", to_string(type))
  end

  defp parameter_source([]), do: nil

  defp parameter_source(source) do
    Enum.reduce(
      source |> tl(),
      source |> hd(),
      fn src, str -> "#{str}[#{src}]" end
    )
  end

  defp pointer_source([]), do: ""

  defp pointer_source(source), do: "/#{Enum.join(source, "/")}"

  defp stringify_keys(map), do: map |> Map.new(fn {k, v} -> {to_string(k), v} end)

  defp to_status(nil), do: nil

  defp to_status(status), do: status |> to_string()
end
