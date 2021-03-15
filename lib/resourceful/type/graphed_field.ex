defmodule Resourceful.Type.GraphedField do
  @moduledoc """
  A graphed field is a field (an attribute or a relationship) bundled with graph
  data dictating how it is to be mapped in a graph from the perspective of a
  type.

  For example, while the attribute `title` on an album will always be the same
  value. However, when that attribute is viewed from the perspective of a song
  or an artist graph information needs to be included. On it's own the attribute
  might map to `:title` but from a song it would map to `[:album, :title]`.

  The `query_alias` is used for Ecto to idenify a join with the `:as` option
  used.
  """

  alias __MODULE__
  alias Resourceful.Type

  @enforce_keys [
    :field,
    :map_to,
    :name,
    :query_alias
  ]

  defstruct @enforce_keys ++ [parent: nil]

  @doc """
  Creates a new graphed field.

  This function will almost never be called directly but rather as part of
  `Resourceful.Registry.build_field_graph/2`.
  """
  @spec new(Type.field(), String.t(), list(), %GraphedField{} | nil) :: %GraphedField{}
  def new(field, name, map_to, parent \\ nil) do
    %GraphedField{
      field: field,
      map_to: map_to,
      name: name,
      parent: parent,
      query_alias: query_alias_with(map_to, field)
    }
  end

  defp query_alias_with(map_to, %Type.Attribute{map_to: attr_map_to}) do
    map_to
    |> Enum.drop(-1)
    |> query_alias_with(attr_map_to)
  end

  defp query_alias_with(map_to, %Type.Relationship{}) do
    query_alias_with(map_to, nil)
  end

  defp query_alias_with([], attr_name), do: attr_name

  defp query_alias_with(map_to, attr_name) do
    {maybe_atomize(map_to), attr_name}
  end

  defp maybe_atomize(map_to) do
    map_to
    |> Enum.map(&to_string/1)
    |> Enum.join(".")
    |> String.to_atom()
  end
end
