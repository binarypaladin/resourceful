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

  defmodule DuplicateTypeNameError do
    defexception message: "type with name already exists"
  end

  defmodule InvalidType do
    defexception message: "result of block must be a `Resourceful.Type`"
  end

  alias Resourceful.Type

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: [type: 1, type: 2]

      import Resourceful.Type,
        only: [
          id: 2,
          max_depth: 2,
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

      @rtypes %{}

      def fetch(name), do: Map.fetch(all(), name)

      def fetch!(name), do: Map.fetch!(all(), name)

      def get(name), do: Map.get(all(), name)

      def get_field_graph(name), do: Map.get(field_graphs(), name)

      def fetch_field_graph(name), do: Map.fetch(field_graphs(), name)

      def fetch_field_graph!(name), do: Map.fetch!(field_graphs(), name)

      def has_type?(name), do: Map.has_key?(all(), name)
    end
  end

  @doc """

  """
  @spec build_field_graph(%{String.t() => %Type{}}, String.t()) :: Type.field_graph()
  def build_field_graph(types_map, type_name) do
    type = Map.get(types_map, type_name)
    do_build_field_graph(%{}, types_map, type, type.max_depth, nil, nil, [])
  end

  def do_build_field_graph(field_graph, _, _, -1, _, _, _), do: field_graph

  def do_build_field_graph(
        field_graph,
        types_map,
        %Type{} = type,
        depth,
        parent,
        name_prefix,
        map_to_prefix
      ) do
    Enum.reduce(type.fields, field_graph, fn {name, field}, new_field_graph ->
      new_map_to = map_to_prefix ++ [field.map_to]
      new_name = qualify_name(name_prefix, name)

      field_data = Type.GraphedField.new(field, new_name, new_map_to, parent)

      new_field_graph = Map.put(new_field_graph, new_name, field_data)

      case field do
        %Type.Relationship{graph?: true} ->
          do_build_field_graph(
            new_field_graph,
            types_map,
            Map.fetch!(types_map, field.related_type),
            depth - 1,
            field_data,
            new_name,
            new_map_to
          )

        _ ->
          new_field_graph
      end
    end)
  end

  defp qualify_name(nil, name), do: name

  defp qualify_name(prefix, name), do: "#{prefix}.#{name}"

  @doc """

  """
  @spec maybe_put_name(%Type{}, String.t() | nil) :: %Type{}
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
      raise __MODULE__.DuplicateTypeNameError,
        message: "type with name `#{type.name}` already exists"
    end

    type
  end

  def validate_type!(_, _), do: raise(__MODULE__.InvalidType)

  defmacro type(name \\ nil, do: block) do
    quote do
      @rtype unquote(block)
             |> Resourceful.Type.register(__MODULE__)
             |> unquote(__MODULE__).maybe_put_name(unquote(name))
             |> unquote(__MODULE__).validate_type!(@rtypes)

      @rtypes Map.put(@rtypes, @rtype.name, @rtype)
    end
  end

  defmacro before_compile(_) do
    quote do
      def all(), do: @rtypes

      @rtype_field_graphs Map.new(@rtypes, fn {name, _} ->
                            {name, unquote(__MODULE__).build_field_graph(@rtypes, name)}
                          end)

      def field_graphs(), do: @rtype_field_graphs

      @rtype_names Map.keys(@rtypes)

      def names(), do: @rtype_names
    end
  end
end
