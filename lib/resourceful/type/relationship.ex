defmodule Resourceful.Type.Relationship do
  @moduledoc """
  Relationships come in one of two types: `:one` or `:many`. Things like
  foreign keys and how the relationships map are up to the underlying data
  source. For the purposes of mapping things in `Resourceful`, it simply needs
  to understand whether it's working with a single thing or multiple things.

  A natural opinion of relationships is that graphing is simply not allowed on
  `:many` relationships. What this means is that you can only do graphed filters
  and sorts against `:one` relationships.

  For example, a song can sort and filter on an album and its artist because a
  song has one album which has one artist. The reverse is not possible because
  an artist has many albums which have many songs. Sorting and filtering on
  relationships  makes sense when data can be represented as a table. In
  situations where it's a tree, multiple queries are necessary and the client is
  responsible for putting the data together.

  It makes sense to filter and sort a song by an album or artist's attribute. It
  does not make sense to sort an artist by a song's attribute.
  """

  # TODO: Indicate if must be present for some query optimization? To
  # distinguish if inner or left join.

  alias __MODULE__
  alias Resourceful.Type

  @type type() :: :many | :one

  @enforce_keys [
    :map_to,
    :name,
    :graph?,
    :related_type,
    :type
  ]

  defstruct @enforce_keys

  @doc """

  """
  @spec new(type(), String.t() | atom(), keyword()) :: %Relationship{}
  def new(type, name, opts \\ []) do
    name = Type.validate_name!(name)
    type = check_type!(type)
    related_type = Keyword.get(opts, :related_type, name)
    graph = type == :one && Keyword.get(opts, :graph?, true)

    %Relationship{
      graph?: graph,
      name: name,
      map_to: Keyword.get(opts, :map_to, String.to_existing_atom(name)),
      related_type: related_type,
      type: type
    }
  end

  @doc """

  """
  @spec name(%Relationship{}, String.t() | atom()) :: %Relationship{}
  def name(%Relationship{} = rel, name), do: Map.put(rel, :name, Type.validate_name!(name))

  defp check_type!(type) when type in [:many, :one], do: type

  defp opt_name(name) when is_binary(name), do: name
end


