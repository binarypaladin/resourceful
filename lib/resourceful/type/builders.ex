defmodule Resourceful.Type.Builders do
  @moduledoc """
  Functions for import in `Resourceful.Registry` for building types
  programmatically.
  """
  alias Resourceful.Type

  def attribute(%Type{} = type, attr_name, attr_type, opts \\ []) do
    Type.put_attribute(
      type,
      Type.Attribute.new(attr_name, attr_type, opts)
    )
  end
end
