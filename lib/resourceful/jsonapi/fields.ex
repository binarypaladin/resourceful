defmodule Resourceful.JSONAPI.Fields do
  @moduledoc """
  Functions for validating fields, primarily for use with JSON:API
  [sparse fieldsets](https://jsonapi.org/format/#fetching-sparse-fieldsets).
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
            with {:ok, related_type} <- validate_field_type(type, type_name),
                 do: validate_fields_with_type(related_type, fields)
          )
        }
      end
    )
  end

  defp invalid_field_error(field), do: Error.with_key(:invalid_field, field)

  defp validate_field_type(type, type_name) do
    case Type.fetch_related_type(type, type_name) do
      :error -> Error.with_key(:invalid_field_type, type_name)
      ok -> ok
    end
  end

  defp validate_fields_with_type(type, fields, context \\ %{})

  defp validate_fields_with_type(type, fields, _) when is_binary(fields) do
    validate_fields_with_type(
      type,
      JSONAPI.Params.split_string_list(fields),
      %{input: fields, source: ["fields", type.name]}
    )
  end

  defp validate_fields_with_type(type, fields, context) when is_list(fields) do
    fields
    |> Stream.with_index()
    |> Enum.map(fn {field, index} ->
      case Type.has_field?(type, field) do
        true ->
          {:ok, field}

        _ ->
          field
          |> invalid_field_error()
          |> Error.with_context(:resource_type, type.name)
          |> Error.with_source(Map.get(context, :source) || ["fields", type.name, index])
          |> Error.with_input(Map.get(context, :input) || field)
      end
    end)
  end

  defp validate_fields_with_type(_, field, _) do
    field
    |> invalid_field_error()
    |> Error.with_input(inspect(field))
  end
end
