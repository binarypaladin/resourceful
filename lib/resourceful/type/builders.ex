defmodule Resourceful.Type.Builders do
  @moduledoc """
  Functions for import in `Resourceful.Registry` for building types
  programmatically.
  """
  alias Resourceful.Type

  def attribute(%Type{} = type, attr_name, attr_type, opts \\ []) do
    Type.put_field(
      type,
      Type.Attribute.new(attr_name, attr_type, opts)
    )
  end

  def has_many(type, rel_name, opts \\ []) do
    relationship(type, :many, rel_name, opts)
  end

  def has_one(type, rel_name, opts \\ []) do
    relationship(type, :one, rel_name, opts)
  end

  def relationship(%Type{} = type, rel_type, rel_name, opts \\ []) do
    Type.put_field(
      type,
      Type.Relationship.new(rel_type, rel_name, opts)
    )
  end
end
