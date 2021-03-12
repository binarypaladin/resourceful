defmodule Resourceful.JSONAPI.IncludeTest do
  use ExUnit.Case

  alias Resourceful.JSONAPI.Include
  alias Resourceful.Test.Types
  alias Resourceful.Type

  test "validate/2" do
    songs = Types.fetch!("songs")

    assert Include.validate(songs, "album,album.artist") ==
             [
               Type.fetch_relationship(songs, "album"),
               Type.fetch_relationship(songs, "album.artist")
             ]

    albums = Types.fetch!("albums")

    assert Include.validate(albums, "artist,publisher,songs") ==
             [
               Type.fetch_relationship(albums, "artist"),
               error:
                 {:relationship_not_found,
                  %{
                    input: "artist,publisher,songs",
                    key: "publisher",
                    resource_type: "albums",
                    source: ["include"]
                  }},
               error:
                 {:cannot_include_relationship,
                  %{
                    input: "artist,publisher,songs",
                    key: "songs",
                    resource_type: "albums",
                    source: ["include"]
                  }}
             ]

    assert Include.validate(albums, ["songs"]) ==
             [
               error:
                 {:cannot_include_relationship,
                  %{
                    input: "songs",
                    key: "songs",
                    resource_type: "albums",
                    source: ["include", 0]
                  }}
             ]
  end
end
