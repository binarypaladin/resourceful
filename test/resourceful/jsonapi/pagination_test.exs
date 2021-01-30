defmodule Resourceful.JSONAPI.PaginationTest do
  use ExUnit.Case

  alias Resourceful.JSONAPI.Pagination

  test "validate/2 with `number_size` strategy" do
    page = Pagination.validate(%{"number" => "2", "size" => "20"})
    assert Keyword.get(page, :number) == 2
    assert Keyword.get(page, :size) == 20

    refute Pagination.validate(%{"number" => "two", "size" => "twenty"}).valid?
  end

  test "validate/2 checks for max page size" do
    page = Pagination.validate(%{"size" => "99"})
    assert Keyword.get(page, :size) == 99

    refute Pagination.validate(%{"size" => "101"}).valid?

    assert %{"size" => "101"}
           |> Pagination.validate(max_page_size: 200)
           |> Keyword.get(:size) == 101
  end
end
