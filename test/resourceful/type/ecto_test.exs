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

    assert Map.keys(type.fields) ==
             ["artistId", "id", "releaseDate", "title", "tracks"]

    assert type.fields
           |> Map.values()
           |> Enum.all?(& &1.filter?) == false

    assert type.fields
           |> Map.values()
           |> Enum.all?(& &1.sort?) == false

    type = Ecto.type_with_schema(Album, query: :all)

    assert type.fields
           |> Map.values()
           |> Enum.all?(& &1.filter?) == true

    assert type.fields
           |> Map.values()
           |> Enum.all?(& &1.sort?) == true

    type = Ecto.type_with_schema(Album, only: [:id, :title], filter: [:title], sort: [:id])

    assert Type.fetch_field!(type, "title").filter? == true
    assert Type.fetch_field!(type, "title").sort? == false
    assert Type.fetch_field!(type, "id").filter? == false
    assert Type.fetch_field!(type, "id").sort? == true
    assert Map.keys(type.fields) == ["id", "title"]

    type = Ecto.type_with_schema(Album, except: [:tracks])
    assert map_size(type.fields) == 4
    assert Map.has_key?(type.fields, "tracks") == false
  end
end
