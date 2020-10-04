defmodule Resourceful.Resource do
  alias __MODULE__
  alias __MODULE__.Attribute
  alias Resourceful.Collection.{Filter, Sort}

  @enforce_keys [
    :attributes,
    :id,
    :max_filters,
    :max_sorts,
    :resource_type
  ]

  defstruct @enforce_keys

  def new(resource_type, opts \\ []) do
    attributes = opt_attrs(Keyword.get(opts, :attributes, %{}))

    %Resource{
      attributes: attributes,
      id: opt_id(Keyword.get(opts, :id, default_id(attributes))),
      max_filters: opt_max(Keyword.get(opts, :max_filters, 4)),
      max_sorts: opt_max(Keyword.get(opts, :max_sorts, 2)),
      resource_type: opt_resource_type(resource_type)
    }
  end

  def attribute(resource, %Attribute{} = attr),
    do: resource |> put(:attributes, Map.put(resource.attributes, attr.name, attr))

  def attribute(%Resource{} = resource, name) do
    case Map.fetch(resource.attributes, name) do
      {:ok, _} = ok -> ok
      _ -> {:error, {:attribute_not_found, %{name: name}}}
    end
  end

  def attribute!(%Resource{} = resource, name), do: Map.fetch!(resource.attributes, name)

  def attribute_names(%Resource{} = resource), do: Map.keys(resource.attributes)

  def filter(resource, filter) when is_binary(filter), do: filter(resource, [filter])

  def filter(%Resource{} = resource, filters)
      when is_map(filters) or is_list(filters) do
    filters
    |> Enum.map(&validate_filter(resource, &1))
    |> check_max(resource.max_filters, :max_filters_exceeded)
  end

  def id(resource, id_attribute), do: resource |> put(:id, opt_id(id_attribute))

  def max_filters(resource, max_filters),
    do: resource |> put(:max_filters, opt_max(max_filters))

  def max_sorts(resource, max_sorts),
    do: resource |> put(:max_sorts, opt_max(max_sorts))

  def resource_type(resource, resource_type),
    do: resource |> put(:resource_type, opt_resource_type(resource_type))

  def sort(resource, sorters) when is_list(sorters) do
    sorters
    |> Enum.map(&validate_sort(resource, &1))
    |> check_max(resource.max_sorts, :max_sorts_exceeded)
  end

  def sort(resource, sorters) when is_binary(sorters),
    do: resource |> sort(Sort.string_list(sorters))

  defp check_max(list, max, error_type) when length(list) > max,
    do: [{:error, {error_type, %{max_allowed: max}}}] ++ list

  defp check_max(list, _, _), do: list

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

  defp opt_resource_type(rtype) when is_atom(rtype), do: to_string(rtype)

  defp opt_resource_type(rtype) when is_binary(rtype), do: rtype

  defp put(%Resource{} = resource, key, value) when is_atom(key),
    do: resource |> Map.put(key, value)

  defp validate_filter(resource, filter) do
    with {:ok, {field, op, val}} <- Filter.cast(filter),
         {:ok, attr} <- attribute(resource, field),
         {:ok, _} = ok <- Attribute.validate_filter(attr, op, val),
         do: ok
  end

  defp validate_sort(resource, sorter) do
    with {:ok, {order, field}} <- Sort.cast(sorter),
         {:ok, attr} <- attribute(resource, field),
         {:ok, _} = ok <- Attribute.validate_sort(attr, order),
         do: ok
  end
end
