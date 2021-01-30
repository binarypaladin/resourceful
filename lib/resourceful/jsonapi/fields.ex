defmodule Resourceful.JSONAPI.Fields do
  @moduledoc """
  Functions for validating fields, primarily for use with JSON:API
  [sparse fieldsets](https://jsonapi.org/format/#fetching-sparse-fieldsets].
  Fields are provided by resource type in requests and not inferred from root or
  relationship names. This means that if a resource has multiple relationships
  pointing to a single resource or a self-referential relationships, these will
  be applied to all instances of that resource type regardless of its location
  in the graph.

  Since this is specific to JSON:API, field names are not converted to atoms in
  the generation options after successful validation. There's no need since
  these prevent any mapping from occurring and never make it to the data layer.

  It's also important to note that a "field" is
  [specifically defined](https://jsonapi.org/format/#document-resource-object-fields)
  and is a collection of attribute names and relationship names. It specifically
  _excludes_ `id` and `type` despite all identifiers sharing a common namespace.

  NOTE: Relationships are current not supported.
  """

  alias Resourceful.{Error, JSONAPI, Resource}

  @doc """
  Returns a `MapSet` of attributes excluding `id`. Will return a cached version
  if available on the resource.
  """
  def from_attributes(%{meta: %{jsonapi: %{attributes: attributes}}}), do: attributes

  def from_attributes(%Resource{} = resource) do
    resource.attributes
    |> Map.delete(resource.id)
    |> Map.keys()
    |> MapSet.new()
  end

  @doc """
  Currently does the same thing as `from_attributes/1` except that it uses a
  difference cache. This function should be used instead of `from_attributes/1`
  in almost all cases because it will expand with support for relationship
  fields in the future.
  """
  def from_resource(%{meta: %{jsonapi: %{fields: fields}}}), do: fields

  def from_resource(%Resource{} = resource), do: from_attributes(resource)

  @doc """
  Takes a map of fields by resource type (e.g.
  `%{"albums" => ["releaseDate", "title"]}`) and validates said fields against
  the provided resource. If fields are included that are not part of a
  particular resource, errors will be returned.
  """
  def validate(%Resource{} = resource, %{} = fields_by_type) do
    Map.new(
      fields_by_type,
      fn {type, fields} ->
        {
          type,
          List.wrap(
            with {:ok, _} <- validate_field_type(resource, type),
                 do: validate_fields_with_type(resource, type, fields)
          )
        }
      end
    )
  end

  defp invalid_field_error(field), do: Error.with_key(:invalid_jsonapi_field, field)

  defp valid_field_with_type?(nil, _), do: false

  defp valid_field_with_type?(resource, field) do
    resource
    |> from_resource()
    |> Enum.member?(field)
  end

  defp valid_field_with_type?(resource, type, field) do
    resource
    |> Resource.with_resource_type(type)
    |> valid_field_with_type?(field)
  end

  defp valid_field_type?(resource, type), do: resource.resource_type == type

  defp validate_field_type(resource, type) do
    case valid_field_type?(resource, type) do
      true -> {:ok, type}
      _ -> Error.with_key(:invalid_jsonapi_field_type, type)
    end
  end

  defp validate_fields_with_type(resource, type, fields, context \\ %{})

  defp validate_fields_with_type(resource, type, fields, _)
       when is_binary(fields) do
    validate_fields_with_type(
      resource,
      type,
      JSONAPI.Params.split_string_list(fields),
      %{input: fields, source: ["fields", type]}
    )
  end

  defp validate_fields_with_type(resource, type, fields, context)
       when is_list(fields) do
    fields
    |> Stream.with_index()
    |> Enum.map(fn {field, index} ->
      case valid_field_with_type?(resource, type, field) do
        true ->
          {:ok, field}

        _ ->
          invalid_field_error(field)
          |> Error.with_context(:resource_type, type)
          |> Error.with_source(Map.get(context, :source) || ["fields", type, index])
          |> Error.with_input(Map.get(context, :input) || field)
      end
    end)
  end

  defp validate_fields_with_type(_, _, field, _) do
    field
    |> invalid_field_error()
    |> Error.with_input(IO.inspect(field))
  end
end
