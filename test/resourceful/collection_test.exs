defmodule Resourceful.CollectionTest do
  use ExUnit.Case

  alias Resourceful.Collection
  alias Resourceful.Test.Fixtures
  alias Resourceful.Test.Repo

  import Resourceful.Test.Helpers

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Fixtures.seed_database()
  end

  @opts [ecto_repo: Repo]

  test "all/2" do
    opts =
      @opts ++
        [
          filter: {"artist", "Duran Duran"},
          page: 2,
          per: 2,
          sort: "-release_date"
        ]

    ids = [12, 10]

    assert Fixtures.albums() |> Collection.all(opts) |> ids() == ids
    assert Fixtures.albums_query() |> Collection.all(opts) |> all_by(:id) == ids
  end

  test "filter/3" do
    filter = {"title", "eq", "Rio"}
    ids = [3]

    assert ids ==
             Fixtures.albums()
             |> Collection.filter(filter)
             |> ids()

    assert ids ==
             Fixtures.albums_query()
             |> Collection.filter(filter, @opts)
             |> all_by(:id)
  end

  test "paginates a list" do
    ids = [4, 5, 6]

    assert Fixtures.albums() |> Collection.paginate(2, 3) |> ids() == ids
    assert Fixtures.albums_query() |> Collection.paginate(2, 3, @opts) |> all_by(:id) == ids
  end

  test "sorts a list" do
    sorter = "artist, -release_date"
    ids = [13, 7, 4, 11, 1, 15, 6, 14, 12, 10, 3, 8, 9, 5, 2]

    assert ids ==
             Fixtures.albums()
             |> Collection.sort(sorter)
             |> ids()

    assert ids ==
             Fixtures.albums_query()
             |> Collection.sort(sorter, @opts)
             |> all_by(:id)
  end

  test "gets total" do
    total = 15

    assert Fixtures.albums() |> Collection.total() == total
    assert Fixtures.albums_query() |> Collection.total(@opts) == total
  end

  test "gets totals with pagination info" do
    totals = %{pages: 5, resources: 15}

    assert Fixtures.albums() |> Collection.totals(per: 3) == totals
    assert Fixtures.albums_query() |> Collection.totals(@opts ++ [per: 3]) == totals
  end
end
