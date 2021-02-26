defmodule Resourceful.Type do
  alias __MODULE__
  alias __MODULE__.Attribute
  alias Resourceful.Error
  alias Resourceful.Collection.{Filter, Sort}

  import Map, only: [put: 3]

  @enforce_keys [
    :attributes,
    :id,
    :meta,
    :max_filters,
    :max_sorters,
    :name
  ]

  defstruct @enforce_keys ++ [:registry]

  def new(name, opts \\ []) do
    attributes = opt_attrs(Keyword.get(opts, :attributes, %{}))

    %Type{
      attributes: attributes,
      id: opt_id(Keyword.get(opts, :id, default_id(attributes))),
      meta: opt_meta(Keyword.get(opts, :meta, %{})),
      max_filters: opt_max(Keyword.get(opts, :max_filters, 4)),
      max_sorters: opt_max(Keyword.get(opts, :max_sorters, 2)),
      name: opt_name(name)
    }
  end

  def fetch_attribute(%Type{} = type, name) do
    case Map.fetch(type.attributes, name) do
      {:ok, _} = ok ->
        ok

      _ ->
        Error.with_context(
          :attribute_not_found,
          %{key: name, resource_type: type.name}
        )
    end
  end

  def get_attribute(%Type{} = type, name), do: Map.get(type.attributes, name)

  def get_id(type, resource), do: map_value(type, resource, type.id)

  def id(type, id_attribute), do: put(type, :id, opt_id(id_attribute))

  def map_value(%Type{} = type, resource, attribute_name) do
    case fetch_attribute(type, attribute_name) do
      {:ok, attr} -> Attribute.map_value(attr, resource)
      _ -> nil
    end
  end

  @doc """
  Takes a type, mappable resource, and a list of attributes. Returns a list of
  tuples with the attribute name and the mapped value. This is returned instead
  of a map to preserve the order of the input list. If order is irrelevant, use
  `to_map/2` instead.
  """
  @spec to_map(%Type{}, any(), list()) :: [{any(), any()}]
  def map_values(type, resource, attribute_names \\ [])

  def map_values(type, resource, []) do
    map_values(type, resource, Map.keys(type.attributes))
  end

  def map_values(type, resource, attribute_names) when is_list(attribute_names) do
    Enum.map(attribute_names, &{&1, map_value(type, resource, &1)})
  end

  def max_filters(type, max_filters) do
    put(type, :max_filters, opt_max(max_filters))
  end

  def max_sorters(type, max_sorters) do
    put(type, :max_sorters, opt_max(max_sorters))
  end

  def meta(type, key, value) when is_atom(key) do
    put(type, :meta, Map.put(type.meta, key, value))
  end

  def name(type, name) do
    put(type, :name, opt_name(name))
  end

  def put_attribute(%Type{} = type, %Attribute{} = attr) do
    put_in(type, [Access.key(:attributes), attr.name], attr)
  end

  def registry(type, module) when is_atom(module) do
    put(type, :registry, module)
  end

  @doc """
  Like `map_values/3` only returns a map with keys in the name of the attributes
  with with values of the mapped values.
  """
  @spec to_map(%Type{}, any(), list()) :: map()
  def to_map(type, resource, attribute_names \\ []) do
    type
    |> map_values(resource, attribute_names)
    |> Map.new()
  end

  def validate_filter(type, filter) do
    with {:ok, {field, op, val}} <- Filter.cast(filter),
         {:ok, attr} <- fetch_attribute(type, field),
         {:ok, _} = ok <- Attribute.validate_filter(attr, op, val),
         do: ok
  end

  def validate_max_filters(list, type, context \\ %{}) do
    check_max(list, type.max_filters, :max_filters_exceeded, context)
  end

  def validate_max_sorters(list, type, context \\ %{}) do
    check_max(list, type.max_sorters, :max_sorters_exceeded, context)
  end

  def validate_sorter(type, sorter) do
    with {:ok, {order, field}} <- Sort.cast(sorter),
         {:ok, attr} <- fetch_attribute(type, field),
         {:ok, _} = ok <- Attribute.validate_sorter(attr, order),
         do: ok
  end

  # This is currently something of a placeholder function that will make much
  # more sense when relationships actually work.
  def with_name(%Type{} = type, name) do
    if type.name == name, do: type, else: nil
  end

  defp check_max(list, max, error_type, context) when length(list) > max do
    [Error.with_context(error_type, Map.put(context, :max_allowed, max)) | list]
  end

  defp check_max(list, _, _, _), do: list

  defp default_id(%{"id" => _}), do: "id"

  defp default_id(_), do: nil

  defp opt_attr(%Attribute{} = attr), do: attr

  defp opt_attr({name, %Attribute{} = attr}) do
    case name == attr.name do
      true -> attr
      _ -> Attribute.name(attr, name)
    end
  end

  defp opt_attrs(attrs) do
    attrs
    |> Enum.map(&opt_attr/1)
    |> Enum.reduce(%{}, fn attr, map -> Map.put(map, attr.name, attr) end)
  end

  defp opt_id(nil), do: nil

  defp opt_id([id_attribute | []]), do: opt_id(id_attribute)

  defp opt_id(id_attribute) when is_atom(id_attribute), do: to_string(id_attribute)

  defp opt_id(id_attribute) when is_binary(id_attribute), do: id_attribute

  defp opt_max(nil), do: nil

  defp opt_max(int) when is_integer(int) and int >= 0, do: int

  defp opt_meta(%{} = map), do: map

  defp opt_name(name) when is_atom(name), do: to_string(name)

  defp opt_name(name) when is_binary(name), do: name
end
