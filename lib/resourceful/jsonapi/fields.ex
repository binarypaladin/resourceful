defmodule Resourceful.JSONAPI.Fields do
  @moduledoc """
  Functions for validating fields, primarily for use with JSON:API
  [sparse fieldsets](https://jsonapi.org/format/#fetching-sparse-fieldsets].
  Fields are provided by type type_name in requests and not inferred from root or
  relationship names. This means that if a type has multiple relationships
  pointing to a single type or a self-referential relationships, these will
  be applied to all instances of that type type_name regardless of its location
  in the graph.

  Since this is specific to JSON:API, field names are not converted to atoms in
  the generation options after successful validation. There's no need since
  these prevent any mapping from occurring and never make it to the data layer.

  It's also important to note that a "field" is
  [specifically defined](https://jsonapi.org/format/#document-type-object-fields)
  and is a collection of attribute names and relationship names. It specifically
  _excludes_ `id` and `type` despite all identifiers sharing a common namespace.

  NOTE: Relationships are currently not supported.
  """

  alias Resourceful.{Error, JSONAPI, Type}

  @doc """
  Returns a `MapSet` of attributes excluding `id`. Will return a cached version
  if available on the type.
  """
  def from_attributes(%{meta: %{jsonapi: %{attributes: attributes}}}), do: attributes

  def from_attributes(%Type{} = type) do
    type.attributes
    |> Map.delete(type.id)
    |> Map.keys()
    |> MapSet.new()
  end

  @doc """
  Currently does the same thing as `from_attributes/1` except that it uses a
  difference cache. This function should be used instead of `from_attributes/1`
  in almost all cases because it will expand with support for relationship
  fields in the future.
  """
  def from_type(%{meta: %{jsonapi: %{fields: fields}}}), do: fields

  def from_type(%Type{} = type), do: from_attributes(type)

  @doc """
  Takes a map of fields by type type_name (e.g.
  `%{"albums" => ["releaseDate", "title"]}`) and validates said fields against
  the provided type. If fields are included that are not part of a
  particular type, errors will be returned.
  """
  def validate(%Type{} = type, %{} = fields_by_type) do
    Map.new(
      fields_by_type,
      fn {type_name, fields} ->
        {
          type_name,
          List.wrap(
            with {:ok, _} <- validate_field_type(type, type_name),
                 do: validate_fields_with_type(type, type_name, fields)
          )
        }
      end
    )
  end

  defp invalid_field_error(field), do: Error.with_key(:invalid_jsonapi_field, field)

  defp valid_field_with_type?(nil, _), do: false

  defp valid_field_with_type?(type, field) do
    type
    |> from_type()
    |> Enum.member?(field)
  end

  defp valid_field_with_type?(type, type_name, field) do
    type
    |> Type.with_name(type_name)
    |> valid_field_with_type?(field)
  end

  defp valid_field_type?(type, type_name), do: type.name == type_name

  defp validate_field_type(type, type_name) do
    case valid_field_type?(type, type_name) do
      true -> {:ok, type_name}
      _ -> Error.with_key(:invalid_jsonapi_field_type, type_name)
    end
  end

  defp validate_fields_with_type(type, type_name, fields, context \\ %{})

  defp validate_fields_with_type(type, type_name, fields, _)
       when is_binary(fields) do
    validate_fields_with_type(
      type,
      type_name,
      JSONAPI.Params.split_string_list(fields),
      %{input: fields, source: ["fields", type_name]}
    )
  end

  defp validate_fields_with_type(type, type_name, fields, context)
       when is_list(fields) do
    fields
    |> Stream.with_index()
    |> Enum.map(fn {field, index} ->
      case valid_field_with_type?(type, type_name, field) do
        true ->
          {:ok, field}

        _ ->
          invalid_field_error(field)
          |> Error.with_context(:resource_type, type_name)
          |> Error.with_source(Map.get(context, :source) || ["fields", type_name, index])
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
