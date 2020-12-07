defmodule Resourceful.Resource.EctoTest do
  use ExUnit.Case

  alias Resourceful.Resource
  alias Resourceful.Resource.Ecto
  alias Resourceful.Test.Album

  test "attribute/3" do
    attr = Ecto.attribute(Album, :tracks, query: true)
    assert attr.filter? == true
    assert attr.map_to == :tracks
    assert attr.name == "tracks"
    assert attr.sort? == true
    assert attr.type == :integer
  end

  test "resource/2" do
    resource = Ecto.resource(Album, transform_names: &Inflex.camelize(&1, :lower))

    assert resource.attributes |> Map.keys() ==
             ["artist", "id", "releaseDate", "title", "tracks"]

    assert resource.attributes |> Map.values() |> Enum.all?(& &1.filter?) == false
    assert resource.attributes |> Map.values() |> Enum.all?(& &1.sort?) == false

    resource = Ecto.resource(Album, query: :all)

    assert resource.attributes |> Map.values() |> Enum.all?(& &1.filter?) == true
    assert resource.attributes |> Map.values() |> Enum.all?(& &1.sort?) == true

    resource = Ecto.resource(Album, only: [:id, :artist], filter: [:artist], sort: [:id])

    assert Resource.attribute!(resource, "artist").filter? == true
    assert Resource.attribute!(resource, "artist").sort? == false
    assert Resource.attribute!(resource, "id").filter? == false
    assert Resource.attribute!(resource, "id").sort? == true
    assert resource.attributes |> Map.keys() == ["artist", "id"]

    resource = Ecto.resource(Album, except: [:tracks])
    assert map_size(resource.attributes) == 4
    assert resource.attributes |> Map.has_key?("tracks") == false
  end
end
