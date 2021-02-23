defmodule Resourceful.Type.AttributeTest do
  use ExUnit.Case

  alias Resourceful.Type.Attribute
  alias Resourceful.Test.Album

  @resource %{artist: "David Bowie"}

  def attr, do: Attribute.new(:artist, :string)

  test "new/3" do
    attr = attr()
    assert attr.filter? == false
    assert attr.map_to == String.to_atom(attr.name)
    assert attr.name == "artist"
    assert attr.sort? == false
    assert attr.type == :string
    assert Attribute.map_value(attr, @resource) == "David Bowie"
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
    assert Attribute.map_value(attr, @resource) == "David Bowie"
  end

  test "cast/2" do
    attr = Attribute.new("tracks", :integer)
    assert Attribute.cast(attr, "5") == {:ok, 5}

    assert Attribute.cast(attr, "X") ==
             {:error, {:type_cast_failure, %{attribute: "tracks", input: "X", type: :integer}}}
  end

  test "error/2" do
    assert Attribute.error(attr(), :err) ==
             {:error, {:err, %{attribute: "artist"}}}

    assert Attribute.error(attr(), :not_musician, %{input: "Harrison Ford"}) ==
             {:error, {:not_musician, %{attribute: "artist", input: "Harrison Ford"}}}
  end

  test "filter/2" do
    attr = Attribute.filter(attr(), true)
    assert attr.filter? == true

    attr = Attribute.filter(attr, nil)
    assert attr.filter? == false
  end

  test "getter/2" do
    func = fn attr, resource ->
      resource
      |> Map.get(attr.map_to, "undefined #{attr.name}")
      |> String.upcase()
    end

    attr = Attribute.getter(attr(), func)
    assert Attribute.map_value(attr, @resource) == "DAVID BOWIE"
    assert Attribute.map_value(attr, %{}) == "UNDEFINED ARTIST"
  end

  test "map_to/2" do
    attr = Attribute.map_to(attr(), "artist")
    resource = %{"artist" => "Duran Duran"}

    assert attr.map_to == "artist"
    assert Attribute.map_value(attr, resource) == "Duran Duran"
  end

  test "name/2" do
    attr = Attribute.name(attr(), :artist_name)
    assert attr.name == "artist_name"
  end

  test "query/2" do
    attr = Attribute.query(attr(), true)
    assert attr.filter? == true
    assert attr.sort? == true
  end

  test "sort/2" do
    attr = Attribute.sort(attr(), true)
    assert attr.sort? == true

    attr = Attribute.sort(attr, nil)
    assert attr.sort? == false
  end

  test "type/2" do
    attr = Attribute.type(attr(), :text)
    assert attr.type == :text
  end

  test "validate_filter/3" do
    attr =
      Album
      |> Resourceful.Type.Ecto.attribute(:tracks)
      |> Map.put(:filter?, false)

    assert Attribute.validate_filter(attr, "gte", "3") ==
             {:error, {:cannot_filter_by_attribute, %{attribute: "tracks"}}}

    attr = %{attr | filter?: true}

    assert Attribute.validate_filter(attr, "gte", "3") == {:ok, {:tracks, "gte", 3}}

    assert Attribute.validate_filter(attr, "gte", "X") ==
             {:error, {:type_cast_failure, %{input: "X", attribute: "tracks", type: :integer}}}

    assert Attribute.validate_filter(attr, "sw", "3") ==
             {:error,
              {:invalid_filter_operator, %{operator: "sw", attribute: "tracks", value: 3}}}
  end

  test "validate_sorter/2" do
    attr = %{attr() | sort?: false}

    assert Attribute.validate_sorter(attr) ==
             {:error, {:cannot_sort_by_attribute, %{attribute: "artist"}}}

    attr = %{attr | sort?: true}
    assert Attribute.validate_sorter(attr, :desc) == {:ok, {:desc, attr.map_to}}
  end
end
