defmodule Resourceful.Resource.AttributeTest do
  use ExUnit.Case

  alias Resourceful.Resource.Attribute
  alias Resourceful.Test.Album

  @data %{artist: "David Bowie"}

  def attr, do: Attribute.new(:artist, :string)

  test "new/3" do
    attr = attr()
    assert attr.filter? == false
    assert attr.map_to == String.to_atom(attr.name)
    assert attr.name == "artist"
    assert attr.sort? == false
    assert attr.type == :string
    assert attr |> Attribute.get(@data) == "David Bowie"
  end

  test "new/3 with keywords" do
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

  test "cast/2" do
    attr = Attribute.new("tracks", :integer)
    assert Attribute.cast(attr, "5") == {:ok, 5}

    assert Attribute.cast(attr, "X") ==
             {:error, {:type_cast_failure, %{attribute: "tracks", input: "X", type: :integer}}}
  end

  test "error/2" do
    assert attr() |> Attribute.error(:err) ==
             {:error, {:err, %{attribute: "artist"}}}

    assert attr() |> Attribute.error(:not_musician, %{input: "Harrison Ford"}) ==
             {:error, {:not_musician, %{attribute: "artist", input: "Harrison Ford"}}}
  end

  test "filter/2" do
    attr = attr() |> Attribute.filter(true)
    assert attr.filter? == true

    attr = attr |> Attribute.filter(nil)
    assert attr.filter? == false
  end

  test "getter/2" do
    func = fn attr, data ->
      data
      |> Map.get(attr.map_to, "undefined #{attr.name}")
      |> String.upcase()
    end

    attr = attr() |> Attribute.getter(func)
    assert attr |> Attribute.get(@data) == "DAVID BOWIE"
    assert attr |> Attribute.get(%{}) == "UNDEFINED ARTIST"
  end

  test "map_to/2" do
    attr = attr() |> Attribute.map_to("artist")
    data = %{"artist" => "Duran Duran"}

    assert attr.map_to == "artist"
    assert attr |> Attribute.get(data) == "Duran Duran"
  end

  test "name/2" do
    attr = attr() |> Attribute.name(:artist_name)
    assert attr.name == "artist_name"
  end

  test "query/2" do
    attr = attr() |> Attribute.query(true)
    assert attr.filter? == true
    assert attr.sort? == true
  end

  test "sort/2" do
    attr = attr() |> Attribute.sort(true)
    assert attr.sort? == true

    attr = attr |> Attribute.sort(nil)
    assert attr.sort? == false
  end

  test "type/2" do
    attr = attr() |> Attribute.type(:text)
    assert attr.type == :text
  end

  test "validate_filter/3" do
    attr = Resourceful.Resource.Ecto.attribute(Album, :tracks) |> Attribute.filter(false)

    assert Attribute.validate_filter(attr, "gte", "3") ==
             {:error, {:cannot_filter_by_attribute, %{attribute: "tracks"}}}

    attr = attr |> Attribute.filter(true)

    assert Attribute.validate_filter(attr, "gte", "3") == {:ok, {:tracks, "gte", 3}}

    assert Attribute.validate_filter(attr, "gte", "X") ==
             {:error, {:type_cast_failure, %{input: "X", attribute: "tracks", type: :integer}}}

    assert Attribute.validate_filter(attr, "sw", "3") ==
             {:error,
              {:invalid_filter_operator, %{operator: "sw", attribute: "tracks", value: 3}}}
  end

  test "validate_sorter/2" do
    attr = attr() |> Attribute.sort(false)

    assert Attribute.validate_sorter(attr) ==
             {:error, {:cannot_sort_by_attribute, %{attribute: "artist"}}}

    attr = attr |> Attribute.sort(true)

    assert Attribute.validate_sorter(attr, :desc) == {:ok, {:desc, attr.map_to}}
  end
end
