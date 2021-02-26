defmodule Resourceful.Registry do
  @doc """
  Instances of `Resourceful.Type` are intended to be used in conjunction with a
  registry in most circumstances. The application, and even the client, will
  likely understand a resource type by its string name/identifier. Types
  themselves, when associated with a registry, will be able to reference each
  other as well, which forms the basis for relationships.

  A module using the `Registry` behaviour becomes a key/value store.
  `defresourcefultype/1` allows the types to be evaluated entirely at compile
  time.
  """

  alias Resourceful.Type

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: [type: 1, type: 2]

      import Resourceful.Type,
        only: [
          id: 2,
          max_filters: 2,
          max_sorters: 2,
          meta: 3,
          name: 2,
          new: 1,
          new: 2
        ]

      import Resourceful.Type.Builders

      import Resourceful.Type.Ecto, only: [type_with_schema: 1, type_with_schema: 2]

      @before_compile {unquote(__MODULE__), :before_compile}

      @rtypes_map %{}

      def fetch(name), do: Map.fetch(all(), name)

      def fetch!(name), do: Map.fetch!(all(), name)

      def get(name), do: Map.get(all(), name)

      def has_type?(name), do: Map.has_key?(all(), name)
    end
  end

  def maybe_put_name(%Type{} = type, nil), do: type

  def maybe_put_name(%Type{} = type, name) when is_binary(name) do
    Type.name(type, name)
  end

  @doc """
  Ensures a value is a `Resourceful.Type` and that no type of the same name
  exists in the map. Raises an exception if both conditions are not met.
  """
  @spec validate_type!(any(), %{String.t() => %Type{}}) :: %Type{}
  def validate_type!(%Type{} = type, types) do
    if Map.has_key?(types, type.name) do
      raise Resourceful.Registry.DuplicateTypeNameError,
        message: "type with name `#{type.name}` already exists"
    end

    type
  end

  def validate_type!(_, _), do: raise(Resourceful.Registry.InvalidType)

  defmacro type(name \\ nil, do: block) do
    quote do
      @rtype unquote(block)
             |> Resourceful.Type.registry(__MODULE__)
             |> unquote(__MODULE__).maybe_put_name(unquote(name))
             |> unquote(__MODULE__).validate_type!(@rtypes_map)

      @rtypes_map Map.put(@rtypes_map, @rtype.name, @rtype)
    end
  end

  defmacro before_compile(_) do
    quote do
      @rtype_names Map.keys(@rtypes_map)

      def all(), do: @rtypes_map

      def names(), do: @rtype_names
    end
  end
end

defmodule Resourceful.Registry.DuplicateTypeNameError do
  defexception message: "type with name already exists"
end

defmodule Resourceful.Registry.InvalidType do
  defexception message: "result of block must be a `Resourceful.Type`"
end

