defmodule Resourceful.Collection.Ecto.FiltersTest do
  use Resourceful.Test.DatabaseCase

  alias Resourceful.Collection.Ecto.Filters

  def albums_with_artist() do
    import Ecto.Query, warn: false

    join(Album, :inner, [q], assoc(q, :artist), as: :artist)
  end

  test "equals" do
    assert albums_with_artist()
           |> Filters.equal({:artist, :name}, "Queen")
           |> ids() == [5]
  end

  test "exclude" do
    assert albums_with_artist()
           |> Filters.exclude({:artist, :name}, ["David Bowie", "Duran Duran"])
           |> ids() == [2, 5, 9]

    assert Album
           |> Filters.exclude(:release_date, [~D[1971-12-17], ~D[1972-06-16], ~D[1976-01-23]])
           |> ids() == [2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 13, 14]
  end

  test "greater than" do
    assert Album
           |> Filters.greater_than(:tracks, 12)
           |> ids() == [12]

    assert Album
           |> Filters.greater_than(:release_date, ~D[2000-01-01])
           |> ids() == [6, 13, 14]
  end

  test "greater than or equal" do
    assert Album
           |> Filters.greater_than_or_equal(:tracks, 12)
           |> ids() == [6, 12, 14]

    assert Album
           |> Filters.greater_than_or_equal(:release_date, ~D[2015-09-11])
           |> ids() == [6, 13]
  end

  test "include" do
    assert Album
           |> Filters.include(:title, ["Duran Duran", "Low-Life"])
           |> ids() == [8, 9, 12]

    assert Album
           |> Filters.include(:release_date, [~D[2015-09-11], ~D[2016-01-08]])
           |> ids() == [6, 13]
  end

  test "less than" do
    assert Album
           |> Filters.less_than(:tracks, 8)
           |> ids() == [11, 13]

    assert Album
           |> Filters.less_than(:release_date, ~D[1973-01-01])
           |> ids() == [1, 15]
  end

  test "less than or equal" do
    assert Album
           |> Filters.less_than_or_equal(:tracks, 8)
           |> ids() == [9, 11, 13]

    assert Album
           |> Filters.less_than_or_equal(:release_date, ~D[1976-01-23])
           |> ids() == [1, 11, 15]
  end

  test "not equal" do
    assert albums_with_artist()
           |> Filters.not_equal({:artist, :name}, "David Bowie")
           |> ids() == [2, 3, 5, 6, 8, 9, 10, 12, 14]
  end

  test "starts with" do
    assert albums_with_artist()
           |> Filters.starts_with({:artist, :name}, "Warr")
           |> ids() == [2]
  end
end
