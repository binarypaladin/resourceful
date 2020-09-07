defmodule Resourceful.Collection.FilterTest do
  use ExUnit.Case

  alias Resourceful.Collection.Filter
  alias Resourceful.Collection.List
  alias Resourceful.Test.Fixtures

  test "filters a list" do
    assert Fixtures.albums() |> Filter.call("title sw R") ==
             Fixtures.albums() |> List.Filters.starts_with(:title, "R")

    assert Fixtures.albums()
           |> Filter.call(["artist eq Duran Duran", ["release_date gt", ~D[2000-01-01]]]) ==
             Fixtures.albums()
             |> List.Filters.equal(:artist, "Duran Duran")
             |> List.Filters.greater_than(:release_date, ~D[2000-01-01])
  end

  test "converts client input into filters" do
    assert Filter.to_filter("title eq News of the World") ==
             {:title, :equal, "News of the World"}

    assert Filter.to_filter(["release_date gte", ~D[2000-01-01]]) ==
             {:release_date, :greater_than_or_equal, ~D[2000-01-01]}
  end

  test "validates operator" do
    assert Filter.valid_operator?("sw") == true
    assert Filter.valid_operator?("wat") == false

    assert Filter.valid_operator?("sw", "D") == true
    assert Filter.valid_operator?("sw", 1) == false
  end
end
