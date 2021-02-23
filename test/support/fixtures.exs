defmodule Resourceful.Test.Fixtures do
  alias Resourceful.Test.{Album, Repo}
  alias Resourceful.Type

  def albums do
    [
      %{
        "id" => 1,
        "artist" => "David Bowie",
        "release_date" => ~D[1972-06-16],
        "title" => "The Rise and Fall of Ziggy Stardust and the Spiders from Mars",
        "tracks" => 11
      },
      %{
        "id" => 2,
        "title" => "Excitable Boy",
        "artist" => "Warren Zevon",
        "release_date" => ~D[1978-01-18],
        "tracks" => 9
      },
      %{
        "id" => 3,
        "artist" => "Duran Duran",
        "release_date" => ~D[1982-05-12],
        "title" => "Rio",
        "tracks" => 9
      },
      %{
        "id" => 4,
        "artist" => "David Bowie",
        "release_date" => ~D[1977-10-14],
        "title" => "\"Heroes\"",
        "tracks" => 10
      },
      %{
        "id" => 5,
        "title" => "News of the World",
        "artist" => "Queen",
        "release_date" => ~D[1977-10-28],
        "tracks" => 11
      },
      %{
        "id" => 6,
        "artist" => "Duran Duran",
        "release_date" => ~D[2015-09-11],
        "title" => "Paper Gods",
        "tracks" => 12
      },
      %{
        "id" => 7,
        "artist" => "David Bowie",
        "release_date" => ~D[1980-09-12],
        "title" => "Scary Monsters (and Super Creeps)",
        "tracks" => 10
      },
      %{
        "id" => 8,
        "artist" => "Duran Duran",
        "release_date" => ~D[1981-06-15],
        "title" => "Duran Duran",
        "tracks" => 9
      },
      %{
        "id" => 9,
        "title" => "Low-Life",
        "artist" => "New Order",
        "release_date" => ~D[1985-05-13],
        "tracks" => 8
      },
      %{
        "id" => 10,
        "artist" => "Duran Duran",
        "release_date" => ~D[1986-11-18],
        "title" => "Notorious",
        "tracks" => 10
      },
      %{
        "id" => 11,
        "artist" => "David Bowie",
        "release_date" => ~D[1976-01-23],
        "title" => "Station to Station",
        "tracks" => 6
      },
      %{
        "id" => 12,
        "artist" => "Duran Duran",
        "release_date" => ~D[1993-02-11],
        "title" => "Duran Duran",
        "tracks" => 13
      },
      %{
        "id" => 13,
        "artist" => "David Bowie",
        "release_date" => ~D[2016-01-08],
        "title" => "Blackstar",
        "tracks" => 7
      },
      %{
        "id" => 14,
        "artist" => "Duran Duran",
        "release_date" => ~D[2004-10-28],
        "title" => "Astronaut",
        "tracks" => 12
      },
      %{
        "id" => 15,
        "artist" => "David Bowie",
        "release_date" => ~D[1971-12-17],
        "title" => "Hunky Dory",
        "tracks" => 11
      }
    ]
  end

  def albums_query, do: Ecto.Queryable.to_query(Album)

  def jsonapi_type do
    Album
    |> Type.Ecto.type(query: true, transform_names: &Inflex.camelize(&1, :lower))
    |> Type.meta(:links, %{"self" => "albums/{id}"})
  end

  def seed_database do
    Enum.map(albums(), fn album_map ->
      %Album{}
      |> Album.create_changeset(album_map)
      |> Repo.insert()
    end)
  end

  def sorters, do: [asc: "artist", desc: "tracks", asc: "title"]
end
