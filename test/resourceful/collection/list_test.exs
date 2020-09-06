defmodule Resourceful.Collection.ListTest do
  use ExUnit.Case

  alias Resourceful.Collection.List
  alias Resourceful.Test.Fixtures

  test "any?" do
    assert List.any?(Fixtures.albums) == true
    assert List.any?([]) == false
  end

  test "all" do
    assert List.all(Fixtures.albums) == Fixtures.albums
  end

  test "total" do
    assert List.total(Fixtures.albums) == length(Fixtures.albums)
  end
end
