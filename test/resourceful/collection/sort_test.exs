defmodule Resourceful.Collection.SortTest do
  use ExUnit.Case

  alias Resourceful.Collection.{List,Sort}
  alias Resourceful.Test.Fixtures

  test "delegates sorting a list" do
    assert Sort.call(Fixtures.albums, ~w[artist -release_date]) ==
           List.Sort.call(Fixtures.albums, artist: :asc, release_date: :desc)
  end

  test "converts key input into keyword lists" do
    assert Sort.to_sorter("+artist") == {:artist, :asc}
    assert Sort.to_sorter("-artist") == {:artist, :desc}
    assert Sort.to_sorter("artist") == {:artist, :asc}

    assert Sort.to_sorters("artist") == [{:artist, :asc}]
    assert Sort.to_sorters(["-tracks", "+artist", "title"]) ==
           [{:tracks, :desc}, {:artist, :asc}, {:title, :asc}]
  end
end
