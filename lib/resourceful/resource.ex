defmodule Resourceful.Resource do
  alias __MODULE__
  alias __MODULE__.Attribute
  alias Resourceful.Error
  alias Resourceful.Collection.{Filter, Sort}

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

  def attribute(resource, %Attribute{} = attr),
    do: put(resource, :attributes, resource.attributes |> Map.put(attr.name, attr))

  def attribute(%Resource{} = resource, name) do
    case Map.fetch(resource.attributes, name) do
      {:ok, _} = ok -> ok
      _ -> Error.with_key(:attribute_not_found, name)
    end
  end

  def attribute!(%Resource{} = resource, name), do: Map.fetch!(resource.attributes, name)

  def get(%Resource{} = resource, attribute_name, data) do
    case attribute(resource, attribute_name) do
      {:ok, attr} -> Attribute.get(attr, data)
      _ -> nil
    end
  end

  def get_id(resource, data), do: get(resource, resource.id, data)

  def id(resource, id_attribute), do: resource |> put(:id, opt_id(id_attribute))

  def max_filters(resource, max_filters),
    do: resource |> put(:max_filters, opt_max(max_filters))

  def max_sorters(resource, max_sorters),
    do: resource |> put(:max_sorters, opt_max(max_sorters))

  def meta(resource, key, value) when is_atom(key),
    do: resource |> put(:meta, Map.put(resource.meta, key, value))

  def resource_type(resource, resource_type),
    do: resource |> put(:resource_type, opt_resource_type(resource_type))

  def validate_filter(resource, filter) do
    with {:ok, {field, op, val}} <- Filter.cast(filter),
         {:ok, attr} <- attribute(resource, field),
         {:ok, _} = ok <- Attribute.validate_filter(attr, op, val),
         do: ok
  end

  def validate_max_filters(list, resource, context \\ %{}),
    do: check_max(list, resource.max_filters, :max_filters_exceeded, context)

  def validate_max_sorters(list, resource, context \\ %{}),
    do: check_max(list, resource.max_sorters, :max_sorters_exceeded, context)

  def validate_sorter(resource, sorter) do
    with {:ok, {order, field}} <- Sort.cast(sorter),
         {:ok, attr} <- attribute(resource, field),
         {:ok, _} = ok <- Attribute.validate_sorter(attr, order),
         do: ok
  end

  defp check_max(list, max, error_type, context) when length(list) > max do
    [
      error_type |> Error.with_context(Map.put(context, :max_allowed, max))
    ] ++ list
  end

  defp check_max(list, _, _, _), do: list

  defp default_id(%{"id" => _}), do: "id"

  defp default_id(_), do: nil

  defp opt_attr(%Attribute{} = attr), do: attr

  defp opt_attr({name, %Attribute{} = attr}) do
    case name == attr.name do
      true -> attr
      _ -> attr |> Attribute.name(name)
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

  defp put(%Resource{} = resource, key, value) when is_atom(key),
    do: resource |> Map.put(key, value)
end
