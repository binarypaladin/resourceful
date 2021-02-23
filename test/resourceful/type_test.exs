defmodule Resourceful.TypeTest do
  use ExUnit.Case

  alias Resourceful.Type
  alias Resourceful.Type.Attribute

  def attributes do
    %{
      "id" => Attribute.new("id", :integer),
      "name" => Attribute.new("name", :string)
    }
  end

  def ecto_type do
    Type.Ecto.type(
      Resourceful.Test.Album,
      query: true,
      transform_names: &Inflex.camelize(&1, :lower)
    )
  end

  def type, do: Type.new("artist", attributes: attributes())

  test "new/2" do
    type = Type.new("object")
    assert type.attributes == %{}
    assert type.id == nil
    assert type.max_filters == 4
    assert type.max_sorters == 2
    assert type.name == "object"
  end

  test "new/2 with keywords" do
    attributes = attributes()

    type =
      Type.new(
        "artist",
        attributes: Map.values(attributes),
        max_filters: nil,
        max_sorters: 10
      )

    assert type.attributes == attributes
    assert type.id == "id"
    assert type.max_filters == nil
    assert type.max_sorters == 10
    assert type.name == "artist"

    type = Type.new("artist", attributes: attributes, id: "name")
    assert type.attributes == attributes
    assert type.id == "name"
  end

  test "fetch_attribute/2" do
    attr = Attribute.new("number", :integer)
    type = Type.new("object", attributes: [attr])

    assert Type.fetch_attribute(type, "number") == {:ok, attr}

    assert Type.fetch_attribute(type, "NUMBER") ==
             {:error, {:attribute_not_found, %{key: "NUMBER", resource_type: "object"}}}
  end

  test "get_attribute/2" do
    attr = Attribute.new("number", :integer)
    type = Type.new("object", attributes: [attr])

    assert Type.get_attribute(type, "number") == attr

    refute Type.get_attribute(type, "NUMBER")
  end

  test "id/2", do: assert(Type.id(type(), "name").id == "name")

  test "map_value/3" do
    assert Type.map_value(ecto_type(), %{tracks: 2}, "tracks") == 2
  end

  test "map_values/3" do
    assert Type.map_values(
             ecto_type(),
             %{artist: "Queen", title: "Queen II", tracks: 2},
             ["title", "artist"]
           ) == [{"title", "Queen II"}, {"artist", "Queen"}]
  end

  test "max_filters/2" do
    assert Type.max_filters(type(), 10).max_filters == 10
    assert Type.max_filters(type(), nil).max_filters == nil
  end

  test "max_sorters/2" do
    assert Type.max_sorters(type(), 10).max_sorters == 10
    assert Type.max_sorters(type(), nil).max_sorters == nil
  end

  test "name/2" do
    assert Type.name(type(), "object").name == "object"
  end

  test "put_attribute/2" do
    type = Type.new("object")
    refute Map.has_key?(type.attributes, "number")

    attr = Attribute.new("number", :integer)

    type = Type.put_attribute(type, attr)
    assert Map.get(type.attributes, "number") == attr
  end

  test "to_map/3" do
    assert Type.to_map(
             ecto_type(),
             %{artist: "Queen", title: "Queen II", tracks: 2},
             ["title", "artist"]
           ) == %{"artist" => "Queen", "title" => "Queen II"}
  end

  test "validate_filter/2" do
    type = ecto_type()

    ok = {:ok, {:artist, "eq", "Duran Duran"}}

    assert Type.validate_filter(type, {"artist", "Duran Duran"}) == ok
    assert Type.validate_filter(type, {"artist eq", "Duran Duran"}) == ok

    assert Type.validate_filter(type, {"invalid", "Duran Duran"}) ==
             {:error, {:attribute_not_found, %{key: "invalid", resource_type: "albums"}}}

    assert Type.validate_filter(type, {"artist et", "Duran Duran"}) ==
             {:error,
              {:invalid_filter_operator,
               %{attribute: "artist", operator: "et", value: "Duran Duran"}}}
  end

  test "validate_max_filters/3" do
    type = Type.max_filters(ecto_type(), 1)
    filters = [Type.validate_filter(type, {"artist", "Duran Duran"})]

    assert Type.validate_max_filters(filters, type, %{source: ["filter"]}) == filters

    type = Type.max_filters(type, 0)

    assert Type.validate_max_filters(filters, type, %{source: ["filter"]}) ==
             [error: {:max_filters_exceeded, %{max_allowed: 0, source: ["filter"]}}] ++ filters
  end

  test "validate_max_sorters/3" do
    type = Type.max_sorters(ecto_type(), 1)
    sorters = [Type.validate_sorter(type, "+artist")]

    assert Type.validate_max_sorters(sorters, type, %{source: ["sort"]}) == sorters

    type = Type.max_sorters(type, 0)

    assert Type.validate_max_sorters(sorters, type, %{source: ["sort"]}) ==
             [error: {:max_sorters_exceeded, %{max_allowed: 0, source: ["sort"]}}] ++ sorters
  end

  test "validate_sorter/2" do
    type = ecto_type()

    ok = {:ok, {:desc, :release_date}}

    assert Type.validate_sorter(type, "-releaseDate") == ok

    assert Type.validate_sorter(type, "-releaseDat") ==
             {:error, {:attribute_not_found, %{key: "releaseDat", resource_type: "albums"}}}
  end
end
