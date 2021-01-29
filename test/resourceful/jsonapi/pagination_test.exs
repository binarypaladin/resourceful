defmodule Resourceful.JSONAPI.PaginationTest do
  use ExUnit.Case

  alias Resourceful.JSONAPI.Pagination

  test "validate/2 with `number_size` strategy" do
    page = Pagination.validate(%{"number" => "2", "size" => "20"})
    assert Keyword.get(page, :page) == 2
    assert Keyword.get(page, :per) == 20

    refute Pagination.validate(%{"number" => "two", "size" => "twenty"}).valid?
  end

  test "validate/2 checks for max page size" do
    page = Pagination.validate(%{"size" => "99"})
    assert Keyword.get(page, :per) == 99

    refute Pagination.validate(%{"size" => "101"}).valid?

    assert %{"size" => "101"}
           |> Pagination.validate(max_resources_per: 200)
           |> Keyword.get(:per) == 101
  end
end
