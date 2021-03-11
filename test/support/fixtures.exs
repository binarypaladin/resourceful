defmodule Resourceful.Test.Fixtures do
  alias Resourceful.Test.{Artist, Album, Repo, Song}

  def albums do
    artists = map_by_id(artists())

    Enum.map(albums_only(), fn album ->
      Map.put(album, "artist", artists[album["artist_id"]])
    end)
  end

  def albums_only do
    [
      %{
        "id" => 1,
        "artist_id" => 1,
        "release_date" => ~D[1972-06-16],
        "title" => "The Rise and Fall of Ziggy Stardust and the Spiders from Mars",
        "tracks" => 11
      },
      %{
        "id" => 2,
        "artist_id" => 5,
        "release_date" => ~D[1978-01-18],
        "title" => "Excitable Boy",
        "tracks" => 9
      },
      %{
        "id" => 3,
        "artist_id" => 2,
        "release_date" => ~D[1982-05-12],
        "title" => "Rio",
        "tracks" => 9
      },
      %{
        "id" => 4,
        "artist_id" => 1,
        "release_date" => ~D[1977-10-14],
        "title" => "\"Heroes\"",
        "tracks" => 10
      },
      %{
        "id" => 5,
        "artist_id" => 4,
        "release_date" => ~D[1977-10-28],
        "title" => "News of the World",
        "tracks" => 11
      },
      %{
        "id" => 6,
        "artist_id" => 2,
        "release_date" => ~D[2015-09-11],
        "title" => "Paper Gods",
        "tracks" => 12
      },
      %{
        "id" => 7,
        "artist_id" => 1,
        "release_date" => ~D[1980-09-12],
        "title" => "Scary Monsters (and Super Creeps)",
        "tracks" => 10
      },
      %{
        "id" => 8,
        "artist_id" => 2,
        "release_date" => ~D[1981-06-15],
        "title" => "Duran Duran",
        "tracks" => 9
      },
      %{
        "id" => 9,
        "artist_id" => 3,
        "release_date" => ~D[1985-05-13],
        "title" => "Low-Life",
        "tracks" => 8
      },
      %{
        "id" => 10,
        "artist_id" => 2,
        "release_date" => ~D[1986-11-18],
        "title" => "Notorious",
        "tracks" => 10
      },
      %{
        "id" => 11,
        "artist_id" => 1,
        "release_date" => ~D[1976-01-23],
        "title" => "Station to Station",
        "tracks" => 6
      },
      %{
        "id" => 12,
        "artist_id" => 2,
        "release_date" => ~D[1993-02-11],
        "title" => "Duran Duran",
        "tracks" => 13
      },
      %{
        "id" => 13,
        "artist_id" => 1,
        "release_date" => ~D[2016-01-08],
        "title" => "Blackstar",
        "tracks" => 7
      },
      %{
        "id" => 14,
        "artist_id" => 2,
        "release_date" => ~D[2004-10-28],
        "title" => "Astronaut",
        "tracks" => 12
      },
      %{
        "id" => 15,
        "artist_id" => 1,
        "release_date" => ~D[1971-12-17],
        "title" => "Hunky Dory",
        "tracks" => 11
      }
    ]
  end

  def artists do
    [
      %{
        "id" => 1,
        "name" => "David Bowie",
        "year_founded" => 1969
      },
      %{
        "id" => 2,
        "name" => "Duran Duran",
        "year_founded" => 1978
      },
      %{
        "id" => 3,
        "name" => "New Order",
        "year_founded" => 1980
      },
      %{
        "id" => 4,
        "name" => "Queen",
        "year_founded" => 1970
      },
      %{
        "id" => 5,
        "name" => "Warren Zevon",
        "year_founded" => 1965
      }
    ]
  end

  def songs_only do
    [
      %{
        "id" => 1,
        "album_id" => 1,
        "title" => "Five Years",
        "track" => 1
      },
      %{
        "id" => 2,
        "album_id" => 1,
        "title" => "Starman",
        "track" => 4
      },
      %{
        "id" => 3,
        "album_id" => 1,
        "title" => "Suffragette City",
        "track" => 10
      },
      %{
        "id" => 4,
        "album_id" => 2,
        "title" => "Accidentally Like a Martyr",
        "track" => 5
      },
      %{
        "id" => 5,
        "album_id" => 2,
        "title" => "Lawyers, Guns and Money",
        "track" => 9
      },
      %{
        "id" => 6,
        "album_id" => 2,
        "title" => "Werewolves of London",
        "track" => 11
      },
      %{
        "id" => 7,
        "album_id" => 3,
        "title" => "Rio",
        "track" => 1
      },
      %{
        "id" => 8,
        "album_id" => 3,
        "title" => "Hungry Like the Wolf",
        "track" => 4
      },
      %{
        "id" => 9,
        "album_id" => 3,
        "title" => "New Religion",
        "track" => 6
      },
      %{
        "id" => 10,
        "album_id" => 4,
        "title" => "Beauty and the Beast",
        "track" => 1
      },
      %{
        "id" => 11,
        "album_id" => 4,
        "title" => "\"Heroes\"",
        "track" => 3
      },
      %{
        "id" => 12,
        "album_id" => 4,
        "title" => "The Secret Life of Arabia",
        "track" => 10
      },
      %{
        "id" => 13,
        "album_id" => 5,
        "title" => "We Will Rock You",
        "track" => 1
      },
      %{
        "id" => 14,
        "album_id" => 5,
        "title" => "We Are the Champions",
        "track" => 2
      },
      %{
        "id" => 15,
        "album_id" => 5,
        "title" => "Get Down, Make Love",
        "track" => 7
      },
      %{
        "id" => 16,
        "album_id" => 6,
        "title" => "Paper Gods",
        "track" => 1
      },
      %{
        "id" => 17,
        "album_id" => 6,
        "title" => "Pressure Off",
        "track" => 4
      },
      %{
        "id" => 18,
        "album_id" => 6,
        "title" => "What Are the Chances?",
        "track" => 7
      },
      %{
        "id" => 19,
        "album_id" => 7,
        "title" => "Scary Monsters (and Super Creeps)",
        "track" => 3
      },
      %{
        "id" => 20,
        "album_id" => 7,
        "title" => "Ashes to Ashes",
        "track" => 4
      },
      %{
        "id" => 21,
        "album_id" => 7,
        "title" => "Fashion",
        "track" => 5
      },
      %{
        "id" => 22,
        "album_id" => 8,
        "title" => "Girls on Film",
        "track" => 1
      },
      %{
        "id" => 23,
        "album_id" => 8,
        "title" => "Planet Earth",
        "track" => 2
      },
      %{
        "id" => 24,
        "album_id" => 8,
        "title" => "Careless Memories",
        "track" => 5
      },
      %{
        "id" => 25,
        "album_id" => 9,
        "title" => "The Perfect Kiss",
        "track" => 2
      },
      %{
        "id" => 26,
        "album_id" => 9,
        "title" => "Sunrise",
        "track" => 4
      },
      %{
        "id" => 27,
        "album_id" => 9,
        "title" => "Sub-culture",
        "track" => 7
      },
      %{
        "id" => 28,
        "album_id" => 10,
        "title" => "Notorious",
        "track" => 1
      },
      %{
        "id" => 29,
        "album_id" => 10,
        "title" => "Skin Trade",
        "track" => 3
      },
      %{
        "id" => 30,
        "album_id" => 10,
        "title" => "A Matter of Feeling",
        "track" => 4
      },
      %{
        "id" => 31,
        "album_id" => 11,
        "title" => "Station to Station",
        "track" => 1
      },
      %{
        "id" => 32,
        "album_id" => 11,
        "title" => "Golden Years",
        "track" => 2
      },
      %{
        "id" => 33,
        "album_id" => 11,
        "title" => "TVC15",
        "track" => 4
      },
      %{
        "id" => 34,
        "album_id" => 12,
        "title" => "Ordinary World",
        "track" => 2
      },
      %{
        "id" => 35,
        "album_id" => 12,
        "title" => "Some Undone",
        "track" => 6
      },
      %{
        "id" => 36,
        "album_id" => 12,
        "title" => "None of the Above",
        "track" => 10
      },
      %{
        "id" => 37,
        "album_id" => 13,
        "title" => "Blackstar",
        "track" => 1
      },
      %{
        "id" => 38,
        "album_id" => 13,
        "title" => "Lazarus",
        "track" => 3
      },
      %{
        "id" => 39,
        "album_id" => 13,
        "title" => "I Can't Give Everything Away",
        "track" => 7
      },
      %{
        "id" => 40,
        "album_id" => 14,
        "title" => "(Reach Up For The) Sunrise",
        "track" => 1
      },
      %{
        "id" => 41,
        "album_id" => 14,
        "title" => "What Happens Tomorrow",
        "track" => 3
      },
      %{
        "id" => 42,
        "album_id" => 14,
        "title" => "Chains",
        "track" => 9
      },
      %{
        "id" => 43,
        "album_id" => 15,
        "title" => "Changes",
        "track" => 1
      },
      %{
        "id" => 44,
        "album_id" => 15,
        "title" => "Life on Mars?",
        "track" => 4
      },
      %{
        "id" => 45,
        "album_id" => 15,
        "title" => "Queen Bitch",
        "track" => 10
      }
    ]
  end

  def songs do
    albums = map_by_id(albums())

    Enum.map(songs_only(), fn song ->
      Map.put(song, "album", albums[song["album_id"]])
    end)
  end

  def albums_with_artist() do
    import Ecto.Query, warn: false

    join(Album, :inner, [q], assoc(q, :artist), as: :artist)
  end

  def seed_database do
    seed_table(artists(), Artist)
    seed_table(albums_only(), Album)
    seed_table(songs_only(), Song)
    :ok
  end

  defp map_by_id(list), do: Map.new(list, fn v -> {v["id"], v} end)

  defp seed_table(list, schema) do
    Enum.map(list, fn attrs ->
      attrs
      |> schema.create_changeset()
      |> Repo.insert()
    end)
  end
end
