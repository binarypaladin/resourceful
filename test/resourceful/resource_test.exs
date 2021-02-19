defmodule Resourceful.ResourceTest do
  use ExUnit.Case

  alias Resourceful.Resource
  alias Resourceful.Resource.Attribute

  def attributes do
    %{
      "id" => Attribute.new("id", :integer),
      "name" => Attribute.new("name", :string)
    }
  end

  def ecto_resource do
    Resource.Ecto.resource(
      Resourceful.Test.Album,
      query: true,
      transform_names: &Inflex.camelize(&1, :lower)
    )
  end

  def resource, do: Resource.new("artist", attributes: attributes())

  test "new/2" do
    resource = Resource.new("object")
    assert resource.attributes == %{}
    assert resource.id == nil
    assert resource.max_filters == 4
    assert resource.max_sorters == 2
    assert resource.resource_type == "object"
  end

  test "new/2 with keywords" do
    attributes = attributes()

    resource =
      Resource.new(
        "artist",
        attributes: Map.values(attributes),
        max_filters: nil,
        max_sorters: 10
      )

    assert resource.attributes == attributes
    assert resource.id == "id"
    assert resource.max_filters == nil
    assert resource.max_sorters == 10
    assert resource.resource_type == "artist"

    resource = Resource.new("artist", attributes: attributes, id: "name")
    assert resource.attributes == attributes
    assert resource.id == "name"
  end

  test "fetch_attribute/2" do
    attr = Attribute.new("number", :integer)
    resource = Resource.new("object", attributes: [attr])

    assert Resource.fetch_attribute(resource, "number") == {:ok, attr}

    assert Resource.fetch_attribute(resource, "NUMBER") ==
             {:error, {:attribute_not_found, %{key: "NUMBER", resource_type: "object"}}}
  end

  test "get_attribute/2" do
    attr = Attribute.new("number", :integer)
    resource = Resource.new("object", attributes: [attr])

    assert Resource.get_attribute(resource, "number") == attr

    refute Resource.get_attribute(resource, "NUMBER")
  end

  test "id/2", do: assert(Resource.id(resource(), "name").id == "name")

  test "map_value/3" do
    assert Resource.map_value(ecto_resource(), %{tracks: 2}, "tracks") == 2
  end

  test "map_values/3" do
    assert Resource.map_values(
             ecto_resource(),
             %{artist: "Queen", title: "Queen II", tracks: 2},
             ["title", "artist"]
           ) == [{"title", "Queen II"}, {"artist", "Queen"}]
  end

  test "max_filters/2" do
    assert Resource.max_filters(resource(), 10).max_filters == 10
    assert Resource.max_filters(resource(), nil).max_filters == nil
  end

  test "max_sorters/2" do
    assert Resource.max_sorters(resource(), 10).max_sorters == 10
    assert Resource.max_sorters(resource(), nil).max_sorters == nil
  end

  test "put_attribute/2" do
    resource = Resource.new("object")
    refute Map.has_key?(resource.attributes, "number")

    attr = Attribute.new("number", :integer)

    resource = Resource.put_attribute(resource, attr)
    assert Map.get(resource.attributes, "number") == attr
  end

  test "resource_type/2" do
    assert Resource.resource_type(resource(), "object").resource_type == "object"
  end

  test "to_map/3" do
    assert Resource.to_map(
             ecto_resource(),
             %{artist: "Queen", title: "Queen II", tracks: 2},
             ["title", "artist"]
           ) == %{"artist" => "Queen", "title" => "Queen II"}
  end

  test "validate_filter/2" do
    resource = ecto_resource()

    ok = {:ok, {:artist, "eq", "Duran Duran"}}

    assert Resource.validate_filter(resource, {"artist", "Duran Duran"}) == ok
    assert Resource.validate_filter(resource, {"artist eq", "Duran Duran"}) == ok

    assert Resource.validate_filter(resource, {"invalid", "Duran Duran"}) ==
             {:error, {:attribute_not_found, %{key: "invalid", resource_type: "albums"}}}

    assert Resource.validate_filter(resource, {"artist et", "Duran Duran"}) ==
             {:error,
              {:invalid_filter_operator,
               %{attribute: "artist", operator: "et", value: "Duran Duran"}}}
  end

  test "validate_max_filters/3" do
    resource = Resource.max_filters(ecto_resource(), 1)
    filters = [Resource.validate_filter(resource, {"artist", "Duran Duran"})]

    assert Resource.validate_max_filters(filters, resource, %{source: ["filter"]}) == filters

    resource = Resource.max_filters(resource, 0)

    assert Resource.validate_max_filters(filters, resource, %{source: ["filter"]}) ==
             [error: {:max_filters_exceeded, %{max_allowed: 0, source: ["filter"]}}] ++ filters
  end

  test "validate_max_sorters/3" do
    resource = Resource.max_sorters(ecto_resource(), 1)
    sorters = [Resource.validate_sorter(resource, "+artist")]

    assert Resource.validate_max_sorters(sorters, resource, %{source: ["sort"]}) == sorters

    resource = Resource.max_sorters(resource, 0)

    assert Resource.validate_max_sorters(sorters, resource, %{source: ["sort"]}) ==
             [error: {:max_sorters_exceeded, %{max_allowed: 0, source: ["sort"]}}] ++ sorters
  end

  test "validate_sorter/2" do
    resource = ecto_resource()

    ok = {:ok, {:desc, :release_date}}

    assert Resource.validate_sorter(resource, "-releaseDate") == ok

    assert Resource.validate_sorter(resource, "-releaseDat") ==
             {:error, {:attribute_not_found, %{key: "releaseDat", resource_type: "albums"}}}
  end
end
