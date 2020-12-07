defmodule Resourceful.ResourceTest do
  use ExUnit.Case

  alias Resourceful.Resource
  alias Resourceful.Resource.Attribute

  def attributes() do
    %{
      "id" => Attribute.new("id", :integer),
      "name" => Attribute.new("name", :string)
    }
  end

  def ecto_resource() do
    Resource.Ecto.resource(
      Resourceful.Test.Album,
      query: true,
      transform_names: &Inflex.camelize(&1, :lower)
    )
  end

  def resource(), do: Resource.new("artist", attributes: attributes())

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
        attributes: attributes |> Map.values(),
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

  test "attribute/2" do
    attr = Attribute.new("id", :integer)
    resource = Resource.new("object")

    assert resource.attributes |> map_size() == 0

    resource = resource |> Resource.attribute(attr)

    assert resource.attributes |> map_size() == 1
    assert resource |> Resource.attribute("id") == {:ok, attr}

    assert resource |> Resource.attribute("ID") ==
             {:error, {:attribute_not_found, %{key: "ID"}}}

    assert resource |> Resource.attribute!("id") == attr
  end

  test "attribute!/2" do
    attr = Attribute.new("id", :integer)
    resource = Resource.new("object", attributes: [attr])

    assert resource |> Resource.attribute!("id") == attr
    assert_raise(KeyError, fn -> resource |> Resource.attribute!("ID") end)
  end

  test "id/2", do: assert(Resource.id(resource(), "name").id == "name")

  test "max_filters/2" do
    assert Resource.max_filters(resource(), 10).max_filters == 10
    assert Resource.max_filters(resource(), nil).max_filters == nil
  end

  test "max_sorters/2" do
    assert Resource.max_sorters(resource(), 10).max_sorters == 10
    assert Resource.max_sorters(resource(), nil).max_sorters == nil
  end

  test "resource_type/2" do
    assert Resource.resource_type(resource(), "object").resource_type == "object"
  end

  test "validate_filter/2" do
    resource = ecto_resource()

    ok = {:ok, {:artist, "eq", "Duran Duran"}}

    assert resource |> Resource.validate_filter({"artist", "Duran Duran"}) == ok
    assert resource |> Resource.validate_filter({"artist eq", "Duran Duran"}) == ok

    assert resource |> Resource.validate_filter({"invalid", "Duran Duran"}) ==
             {:error, {:attribute_not_found, %{key: "invalid"}}}

    assert resource |> Resource.validate_filter({"artist et", "Duran Duran"}) ==
             {:error,
              {:invalid_filter_operator,
               %{attribute: "artist", operator: "et", value: "Duran Duran"}}}
  end

  test "validate_max_filters/3" do
    resource = ecto_resource() |> Resource.max_filters(1)
    filters = [resource |> Resource.validate_filter({"artist", "Duran Duran"})]

    assert filters |> Resource.validate_max_filters(resource, %{source: ["filter"]}) == filters

    resource = resource |> Resource.max_filters(0)

    assert filters |> Resource.validate_max_filters(resource, %{source: ["filter"]}) ==
             [error: {:max_filters_exceeded, %{max_allowed: 0, source: ["filter"]}}] ++ filters
  end

  test "validate_max_sorters/3" do
    resource = ecto_resource() |> Resource.max_sorters(1)
    sorters = [resource |> Resource.validate_sorter("+artist")]

    assert sorters |> Resource.validate_max_sorters(resource, %{source: ["sort"]}) == sorters

    resource = resource |> Resource.max_sorters(0)

    assert sorters |> Resource.validate_max_sorters(resource, %{source: ["sort"]}) ==
             [error: {:max_sorters_exceeded, %{max_allowed: 0, source: ["sort"]}}] ++ sorters
  end

  test "validate_sorter/2" do
    resource = ecto_resource()

    ok = {:ok, {:desc, :release_date}}

    assert resource |> Resource.validate_sorter("-releaseDate") == ok

    assert resource |> Resource.validate_sorter("-releaseDat") ==
             {:error, {:attribute_not_found, %{key: "releaseDat"}}}
  end
end
