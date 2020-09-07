defmodule Resourceful.Collection.SortTest do
  use ExUnit.Case

  alias Resourceful.Collection.{List, Sort}
  alias Resourceful.Test.Fixtures

  test "delegates sorting a list" do
    assert Sort.call(Fixtures.albums(), ~w[artist -release_date]) ==
             List.Sort.call(Fixtures.albums(), asc: :artist, desc: :release_date)
  end

  test "converts key input into keyword lists" do
    assert Sort.to_sorter("+artist") == {:asc, :artist}
    assert Sort.to_sorter("-artist") == {:desc, :artist}
    assert Sort.to_sorter("artist") == {:asc, :artist}

    assert Sort.to_sorters("artist") == [{:asc, :artist}]

    assert Sort.to_sorters(["-tracks", "+artist", "title"]) ==
             [{:desc, :tracks}, {:asc, :artist}, {:asc, :title}]
  end
end
