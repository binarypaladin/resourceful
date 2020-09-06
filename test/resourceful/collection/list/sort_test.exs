defmodule Resourceful.Collection.List.SortTest do
  use ExUnit.Case

  alias Resourceful.Collection.List.Sort
  alias Resourceful.Test.Fixtures

  import Resourceful.Test.Helpers

  test "sorts a list of maps" do
    sorted = Sort.call(Fixtures.albums, title: :asc)
    assert first(sorted).id == 4
    assert last(sorted).id == 1

    sorted = Sort.call(Fixtures.albums, release_date: :desc)
    assert first(sorted).id == 13
    assert last(sorted).id == 15

    sorted = Sort.call(Fixtures.albums, artist: :desc, tracks: :desc, release_date: :asc)
    assert first(sorted).id == 2
    assert last(sorted).id == 11
    assert at(sorted, 10).id == 1
  end

  test "converts base sorter to an expanded line of sorters" do
    assert Sort.to_sorter(Fixtures.sorters) == [artist: :eq, tracks: :eq, title: :asc]
  end

  test "converts base sorters to list sorters" do
    assert Sort.to_sorters(Fixtures.sorters) ==
           [
             [artist: :asc],
             [artist: :eq, tracks: :desc],
             [artist: :eq, tracks: :eq, title: :asc]
           ]
  end

  test "checks two values for order" do
    d0 = ~D[2020-01-01]
    d1 = ~D[2020-01-02]

    assert Sort.asc(0, 1) == true
    assert Sort.desc(0, 1) == false
    assert Sort.eq(0, 1) == false

    assert Sort.asc(d0, d1) == true
    assert Sort.desc(d0, d1) == false
    assert Sort.eq(d0, d1) == false

    assert Sort.asc(1, 0) == false
    assert Sort.desc(1, 0) == true
    assert Sort.eq(1, 0) == false

    assert Sort.asc(d1, d0) == false
    assert Sort.desc(d1, d0) == true
    assert Sort.eq(d1, d0) == false

    assert Sort.asc(0, 0) == false
    assert Sort.desc(0, 0) == false
    assert Sort.eq(0, 0) == true

    assert Sort.asc(d0, d0) == false
    assert Sort.desc(d0, d0) == false
    assert Sort.eq(d0, d0) == true
  end
end
