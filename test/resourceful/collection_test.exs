defmodule Resourceful.CollectionTest do
  use ExUnit.Case

  alias Resourceful.Collection
  alias Resourceful.Test.Fixtures

  import Resourceful.Test.Helpers

  test "filters, sorts, and paginates a list" do
    opts = [
      filter: ["artist eq Duran Duran"],
      page: 2,
      per: 2,
      sort: "-release_date"
    ]

    assert Fixtures.albums |> Collection.all(opts) |> ids() == [12, 10]
  end

  test "filters a list" do
    assert Fixtures.albums |> Collection.filter("title eq Rio") |> ids() == [3]
  end

  test "paginates a list" do
    assert Fixtures.albums |> Collection.paginate(2, 3) |> ids() == [4, 5, 6]

  end

  test "sorts a list" do
    assert Fixtures.albums |> Collection.sort(~w[artist -release_date]) |> ids() ==
           [13, 7, 4, 11, 1, 15, 6, 14, 12, 10, 3, 8, 9, 5, 2]
  end

  test "gets total" do
    assert Fixtures.albums |> Collection.total() == 15
  end

  test "gets totals with pagination info" do
    assert Fixtures.albums |> Collection.totals(per: 3) == %{pages: 5, resources: 15}
  end
end
