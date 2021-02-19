defmodule Resourceful.Resource do
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
    :resource_type
  ]

  defstruct @enforce_keys

  def new(resource_type, opts \\ []) do
    attributes = opt_attrs(Keyword.get(opts, :attributes, %{}))

    %Resource{
      attributes: attributes,
      id: opt_id(Keyword.get(opts, :id, default_id(attributes))),
      meta: opt_meta(Keyword.get(opts, :meta, %{})),
      max_filters: opt_max(Keyword.get(opts, :max_filters, 4)),
      max_sorters: opt_max(Keyword.get(opts, :max_sorters, 2)),
      resource_type: opt_resource_type(resource_type)
    }
  end

  def fetch_attribute(%Resource{} = resource, name) do
    case Map.fetch(resource.attributes, name) do
      {:ok, _} = ok ->
        ok

      _ ->
        Error.with_context(
          :attribute_not_found,
          %{key: name, resource_type: resource.resource_type}
        )
    end
  end

  def get_attribute(%Resource{} = resource, name), do: Map.get(resource.attributes, name)

  def get_id(resource, data), do: map_value(resource, data, resource.id)

  def id(resource, id_attribute), do: put(resource, :id, opt_id(id_attribute))

  def map_value(%Resource{} = resource, data, attribute_name) do
    case fetch_attribute(resource, attribute_name) do
      {:ok, attr} -> Attribute.map_value(attr, data)
      _ -> nil
    end
  end

  @doc """
  Takes a resource, mappable data, and a list of attributes. Returns a list of
  tuples with the attribute name and the mapped value. This is returned instead
  of a map to preserve the order of the input list. If order is irrelevant,
  use `to_map/2` instead.
  """
  @spec to_map(%Resource{}, any(), list()) :: [{any(), any()}]
  def map_values(resource, data, attribute_names \\ [])

  def map_values(resource, data, []) do
    map_values(resource, data, Map.keys(resource.attributes))
  end

  def map_values(resource, data, attribute_names) when is_list(attribute_names) do
    Enum.map(attribute_names, &{&1, map_value(resource, data, &1)})
  end

  def max_filters(resource, max_filters) do
    put(resource, :max_filters, opt_max(max_filters))
  end

  def max_sorters(resource, max_sorters) do
    put(resource, :max_sorters, opt_max(max_sorters))
  end

  def meta(resource, key, value) when is_atom(key) do
    put(resource, :meta, Map.put(resource.meta, key, value))
  end

  def put_attribute(%Resource{} = resource, %Attribute{} = attr) do
    put_in(resource, [Access.key(:attributes), attr.name], attr)
  end

  def resource_type(resource, resource_type) do
    put(resource, :resource_type, opt_resource_type(resource_type))
  end

  @doc """
  Like `map_values/3` only returns a map with keys in the name of the attributes
  with the appro
  """
  @spec to_map(%Resource{}, any(), list()) :: map()
  def to_map(resource, data, attribute_names \\ []) do
    resource
    |> map_values(data, attribute_names)
    |> Map.new()
  end

  def validate_filter(resource, filter) do
    with {:ok, {field, op, val}} <- Filter.cast(filter),
         {:ok, attr} <- fetch_attribute(resource, field),
         {:ok, _} = ok <- Attribute.validate_filter(attr, op, val),
         do: ok
  end

  def validate_max_filters(list, resource, context \\ %{}) do
    check_max(list, resource.max_filters, :max_filters_exceeded, context)
  end

  def validate_max_sorters(list, resource, context \\ %{}) do
    check_max(list, resource.max_sorters, :max_sorters_exceeded, context)
  end

  def validate_sorter(resource, sorter) do
    with {:ok, {order, field}} <- Sort.cast(sorter),
         {:ok, attr} <- fetch_attribute(resource, field),
         {:ok, _} = ok <- Attribute.validate_sorter(attr, order),
         do: ok
  end

  # This is currently something of a placeholder function that will make much
  # more sense when relationships actually work.
  def with_resource_type(%Resource{} = resource, type) do
    case resource.resource_type == type do
      true -> resource
      _ -> nil
    end
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

  defp opt_resource_type(rtype) when is_atom(rtype), do: to_string(rtype)

  defp opt_resource_type(rtype) when is_binary(rtype), do: rtype
end
