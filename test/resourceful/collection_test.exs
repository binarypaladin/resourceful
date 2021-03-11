defmodule Resourceful.CollectionTest do
  use Resourceful.Test.DatabaseCase

  alias Resourceful.Collection

  @opts [ecto_repo: Repo]

  test "all/2" do
    opts =
      Keyword.merge(@opts,
        filter: {"artist.name", "Duran Duran"},
        page: [number: 2, size: 2],
        sort: "-release_date"
      )

    ids = [12, 10]

    assert Fixtures.albums()
           |> Collection.all(opts)
           |> ids() == ids

    assert Fixtures.albums_with_artist()
           |> Collection.all(opts)
           |> all_by(:id) == ids
  end

  test "filter/3" do
    filter = {"title", "eq", "Rio"}
    ids = [3]

    assert Fixtures.albums()
           |> Collection.filter(filter)
           |> ids() == ids

    assert Fixtures.albums_with_artist()
           |> Collection.filter(filter, @opts)
           |> all_by(:id) == ids
  end

  test "paginates a list" do
    ids = [4, 5, 6]

    assert Fixtures.albums()
           |> Collection.paginate(2, 3)
           |> ids() == ids

    assert Fixtures.albums_with_artist()
           |> Collection.paginate(2, 3, @opts)
           |> all_by(:id) == ids
  end

  test "sorts a list" do
    sorter = "artist.name, -release_date"
    ids = [13, 7, 4, 11, 1, 15, 6, 14, 12, 10, 3, 8, 9, 5, 2]

    assert Fixtures.albums()
           |> Collection.sort(sorter)
           |> ids() == ids

    assert Fixtures.albums_with_artist()
           |> Collection.sort(sorter, @opts)
           |> all_by(:id) == ids
  end

  test "gets total" do
    total = 15

    assert Collection.total(Fixtures.albums()) == total
    assert Collection.total(Fixtures.albums_with_artist(), @opts) == total
  end

  test "gets pagination info" do
    totals = %{resources: 15, number: 1, size: 3, total: 5}

    assert Collection.page_info(Fixtures.albums(), page: [size: 3]) == totals

    assert Collection.page_info(
             Fixtures.albums_with_artist(),
             Keyword.put(@opts, :page, size: 3)
           ) == totals

    assert Collection.all_with_page_info(Fixtures.albums(), page: [size: 3]) ==
             {Collection.all(Fixtures.albums(), page: [size: 3]), totals}
  end
end
