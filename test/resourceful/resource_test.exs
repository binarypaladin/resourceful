defmodule Resourceful.ResourceTest do
  use ExUnit.Case

  alias Resourceful.Resource
  alias Resourceful.Resource.Attribute

  defp attributes() do
    %{
      "id" => Attribute.new("id", :integer),
      "name" => Attribute.new("name", :string)
    }
  end

  defp ecto_resource() do
    Resource.Ecto.resource(
      Resourceful.Test.Album,
      query: true,
      transform_names: &Inflex.camelize(&1, :lower)
    )
  end

  defp resource(), do: Resource.new("artist", attributes: attributes())

  test "new" do
    resource = Resource.new("object")
    assert resource.attributes == %{}
    assert resource.id == nil
    assert resource.max_filters == 4
    assert resource.max_sorts == 2
    assert resource.resource_type == "object"
  end

  test "new with keywords" do
    attributes = attributes()

    resource =
      Resource.new(
        "artist",
        attributes: attributes |> Map.values(),
        max_filters: nil,
        max_sorts: 10
      )

    assert resource.attributes == attributes
    assert resource.id == "id"
    assert resource.max_filters == nil
    assert resource.max_sorts == 10
    assert resource.resource_type == "artist"

    resource = Resource.new("artist", attributes: attributes, id: "name")
    assert resource.attributes == attributes
    assert resource.id == "name"
  end

  test "attribute" do
    attr = Attribute.new("id", :integer)
    resource = Resource.new("object")

    assert resource.attributes |> map_size() == 0

    resource = resource |> Resource.attribute(attr)

    assert resource.attributes |> map_size() == 1
    assert resource |> Resource.attribute("id") == {:ok, attr}

    assert resource |> Resource.attribute("ID") ==
             {:error, {:attribute_not_found, %{name: "ID"}}}

    assert resource |> Resource.attribute!("id") == attr
  end

  test "attribute_names" do
    assert resource() |> Resource.attribute_names() == ["id", "name"]
  end

  test "filter" do
    resource = ecto_resource()

    map_result = [ok: {:artist, "eq", "Duran Duran"}]

    assert resource |> Resource.filter(%{"artist" => "Duran Duran"}) == map_result
    assert resource |> Resource.filter(%{"artist eq" => "Duran Duran"}) == map_result

    assert resource |> Resource.filter(%{"invalid" => "Duran Duran"}) ==
             [error: {:attribute_not_found, %{name: "invalid"}}]

    list_result = [
      ok: {:artist, "eq", "Duran Duran"},
      ok: {:release_date, "gte", ~D[2000-01-01]}
    ]

    filter = [
      "artist eq Duran Duran",
      "releaseDate gte 2000-01-01"
    ]

    assert resource |> Resource.filter(filter) == list_result

    assert resource |> Resource.max_filters(1) |> Resource.filter(filter) ==
             [error: {:max_filters_exceeded, %{max_allowed: 1}}] ++ list_result
  end

  test "id" do
    assert Resource.id(resource(), "name").id == "name"
  end

  test "max_filters" do
    assert Resource.max_filters(resource(), 10).max_filters == 10
    assert Resource.max_filters(resource(), nil).max_filters == nil
  end

  test "max_sorts" do
    assert Resource.max_sorts(resource(), 10).max_sorts == 10
    assert Resource.max_sorts(resource(), nil).max_sorts == nil
  end

  test "resource_type" do
    assert Resource.resource_type(resource(), "object").resource_type == "object"
  end

  test "sort" do
    resource = ecto_resource()

    ok = [ok: {:asc, :artist}, ok: {:desc, :release_date}]
    sort = "artist, -releaseDate"

    assert resource |> Resource.sort(sort) == ok

    assert resource |> Resource.max_sorts(1) |> Resource.sort(sort) ==
             [error: {:max_sorts_exceeded, %{max_allowed: 1}}] ++ ok
  end
end
