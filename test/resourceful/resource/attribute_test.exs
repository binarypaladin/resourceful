defmodule Resourceful.Resource.AttributeTest do
  use ExUnit.Case

  alias Resourceful.Resource.Attribute
  alias Resourceful.Test.Album

  @data %{artist: "David Bowie"}

  defp attr, do: Attribute.new(:artist, :string)

  test "new" do
    attr = attr()
    assert attr.filter? == false
    assert attr.map_to == String.to_atom(attr.name)
    assert attr.name == "artist"
    assert attr.sort? == false
    assert attr.type == :string
    assert attr |> Attribute.get(@data) == "David Bowie"
  end

  test "new with keywords" do
    attr =
      Attribute.new(
        "name",
        :string,
        filter: nil,
        map_to: :artist,
        sort: true
      )

    assert attr.filter? == false
    assert attr.map_to == :artist
    assert attr.name == "name"
    assert attr.sort? == true
    assert attr |> Attribute.get(@data) == "David Bowie"
  end

  test "cast" do
    attr = Attribute.new("tracks", :integer)
    assert Attribute.cast(attr, "5") == {:ok, 5}

    assert Attribute.cast(attr, "X") ==
             {:error, {:type_cast_failure, %{input: "X", source: "tracks", type: :integer}}}
  end

  test "filter" do
    attr = attr() |> Attribute.filter(true)
    assert attr.filter? == true

    attr = attr |> Attribute.filter(nil)
    assert attr.filter? == false
  end

  test "getter" do
    func = fn attr, data ->
      data
      |> Map.get(attr.map_to, "undefined #{attr.name}")
      |> String.upcase()
    end

    attr = attr() |> Attribute.getter(func)
    assert attr |> Attribute.get(@data) == "DAVID BOWIE"
    assert attr |> Attribute.get(%{}) == "UNDEFINED ARTIST"
  end

  test "map_to" do
    attr = attr() |> Attribute.map_to("artist")
    data = %{"artist" => "Duran Duran"}

    assert attr.map_to == "artist"
    assert attr |> Attribute.get(data) == "Duran Duran"
  end

  test "name" do
    attr = attr() |> Attribute.name(:artist_name)
    assert attr.name == "artist_name"
  end

  test "query" do
    attr = attr() |> Attribute.query(true)
    assert attr.filter? == true
    assert attr.sort? == true
  end

  test "sort" do
    attr = attr() |> Attribute.sort(true)
    assert attr.sort? == true

    attr = attr |> Attribute.sort(nil)
    assert attr.sort? == false
  end

  test "type" do
    attr = attr() |> Attribute.type(:text)
    assert attr.type == :text
  end

  test "validate_filter" do
    attr = Resourceful.Resource.Ecto.attribute(Album, :tracks)

    assert Attribute.validate_filter(attr, "gte", "3") ==
             {:error, {:cannot_filter_by_attribute, %{source: "tracks"}}}

    attr = attr |> Attribute.filter(true)

    assert Attribute.validate_filter(attr, "gte", "3") == {:ok, {:tracks, "gte", 3}}

    assert Attribute.validate_filter(attr, "gte", "X") ==
             {:error, {:type_cast_failure, %{input: "X", source: "tracks", type: :integer}}}

    assert Attribute.validate_filter(attr, "sw", "3") ==
             {:error, {:invalid_filter_operator, %{operator: "sw", source: "tracks", value: 3}}}
  end

  test "validate_sort" do
    attr = attr()

    assert Attribute.validate_sort(attr) ==
             {:error, {:cannot_sort_by_attribute, %{source: "artist"}}}

    attr = attr |> Attribute.sort(true)

    assert Attribute.validate_sort(attr, :desc) == {:ok, {:desc, attr.map_to}}
  end
end
