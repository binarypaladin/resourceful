defmodule Resourceful.Test.Types do
  use Resourceful.Registry

  alias Resourceful.Test.{Artist, Album, Song}

  type("artists") do
    Artist
    |> type_with_schema(query: true, transform_names: &Inflex.camelize(&1, :lower))
    |> has_many("albums")
    |> meta(:links, %{"self" => "artists/{id}"})
  end

  type("albums") do
    Album
    |> type_with_schema(
      except: [:artist_id],
      query: true,
      transform_names: &Inflex.camelize(&1, :lower)
    )
    |> has_one("artist", related_type: "artists")
    |> has_many("songs")
    |> meta(:links, %{"self" => "albums/{id}"})
  end

  type("songs") do
    Song
    |> type_with_schema(
      except: [:album_id],
      query: true,
      transform_names: &Inflex.camelize(&1, :lower)
    )
    |> has_one("album", related_type: "albums")
    |> meta(:links, %{"self" => "songs/{id}"})
    |> max_depth(2)
  end
end
