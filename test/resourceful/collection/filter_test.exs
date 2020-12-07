defmodule Resourceful.Collection.FilterTest do
  use ExUnit.Case

  alias Resourceful.Collection.Filter
  alias Resourceful.Collection.List
  alias Resourceful.Test.Fixtures

  test "call/1" do
    assert Fixtures.albums()
           |> Filter.call([{"artist", "Duran Duran"}, ["release_date gt", ~D[2000-01-01]]]) ==
             Fixtures.albums()
             |> List.Filters.equal("artist", "Duran Duran")
             |> List.Filters.greater_than("release_date", ~D[2000-01-01])
  end

  test "cast/1" do
    assert Filter.cast(["release_date gte", ~D[2000-01-01]]) ==
             {:ok, {"release_date", "gte", ~D[2000-01-01]}}

    assert Filter.cast({"title", "Rio"}) == {:ok, {"title", "eq", "Rio"}}

    assert Filter.cast("title Rio") == {:error, {:invalid_filter, %{filter: "title Rio"}}}
  end

  test "cast!/1" do
    assert Filter.cast!({"title", "Rio"}) == {"title", "eq", "Rio"}
    assert_raise(ArgumentError, fn -> Filter.cast!("title Rio") end)
  end

  test "valid_operator?/1" do
    assert Filter.valid_operator?("sw") == true
    assert Filter.valid_operator?("wat") == false
  end

  test "valid_operator?/2" do
    assert Filter.valid_operator?("sw", "D") == true
    assert Filter.valid_operator?("sw", 1) == false
  end
end
