defmodule Resourceful.Type.EctoTest do
  use ExUnit.Case

  alias Resourceful.Type
  alias Resourceful.Type.Ecto
  alias Resourceful.Test.Album

  test "attribute/3" do
    attr = Ecto.attribute(Album, :tracks, query: true)
    assert attr.filter? == true
    assert attr.map_to == :tracks
    assert attr.name == "tracks"
    assert attr.sort? == true
    assert attr.type == :integer
  end

  test "type/2" do
    type = Ecto.type_with_schema(Album, transform_names: &Inflex.camelize(&1, :lower))

    assert Map.keys(type.attributes) ==
             ["artist", "id", "releaseDate", "title", "tracks"]

    assert type.attributes
           |> Map.values()
           |> Enum.all?(& &1.filter?) == false

    assert type.attributes
           |> Map.values()
           |> Enum.all?(& &1.sort?) == false

    type = Ecto.type_with_schema(Album, query: :all)

    assert type.attributes
           |> Map.values()
           |> Enum.all?(& &1.filter?) == true

    assert type.attributes
           |> Map.values()
           |> Enum.all?(& &1.sort?) == true

    type = Ecto.type_with_schema(Album, only: [:id, :artist], filter: [:artist], sort: [:id])

    assert Type.get_attribute(type, "artist").filter? == true
    assert Type.get_attribute(type, "artist").sort? == false
    assert Type.get_attribute(type, "id").filter? == false
    assert Type.get_attribute(type, "id").sort? == true
    assert Map.keys(type.attributes) == ["artist", "id"]

    type = Ecto.type_with_schema(Album, except: [:tracks])
    assert map_size(type.attributes) == 4
    assert Map.has_key?(type.attributes, "tracks") == false
  end
end
