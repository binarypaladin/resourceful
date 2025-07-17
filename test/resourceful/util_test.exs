defmodule Resourceful.UtilTest do
  use ExUnit.Case

  alias Resourceful.Util

  test "except_or_only!/2" do
    set = [:north, :west, :south, :east]

    assert Util.except_or_only!([only: :north], set) == [:north]

    assert Util.except_or_only!([only: [:north, :south]], set) == [:north, :south]

    assert Util.except_or_only!([except: [:north, :south]], set) == [:west, :east]

    assert_raise ArgumentError, ~r/up, down/, fn ->
      Util.except_or_only!([except: [:up, :down]], set)
    end
  end
end
