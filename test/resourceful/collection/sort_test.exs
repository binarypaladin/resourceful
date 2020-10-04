defmodule Resourceful.Collection.SortTest do
  use ExUnit.Case

  alias Resourceful.Collection.{List, Sort}
  alias Resourceful.Test.Fixtures

  test "delegates sorting a list" do
    assert Sort.call(Fixtures.albums(), ~w[artist -release_date]) ==
             List.Sort.call(Fixtures.albums(), asc: "artist", desc: "release_date")
  end

  test "converts key input into keyword lists" do
    assert Sort.cast("+artist") == {:ok, {:asc, "artist"}}
    assert Sort.cast("-artist") == {:ok, {:desc, "artist"}}
    assert Sort.cast("artist") == {:ok, {:asc, "artist"}}

    assert Sort.cast!("artist") == {:asc, "artist"}

    assert Sort.all("artist,-release_date") == [asc: "artist", desc: "release_date"]

    assert Sort.all(["-tracks", "+artist", "title"]) ==
             [{:desc, "tracks"}, {:asc, "artist"}, {:asc, "title"}]
  end
end
