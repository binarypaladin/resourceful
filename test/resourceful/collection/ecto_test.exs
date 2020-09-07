defmodule Resourceful.Collection.EctoTest do
  use ExUnit.Case

  alias Resourceful.Collection
  alias Resourceful.Test.Fixtures
  alias Resourceful.Test.Repo

  @opts [ecto_repo: Repo]

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Fixtures.seed_database
  end

  test "all" do
    assert Fixtures.albums_query |> Collection.Ecto.all(@opts) ==
           Fixtures.albums_query |> Repo.all
  end

  test "any?" do
    assert Fixtures.albums_query |>  Collection.Ecto.any?(@opts) == true

    Fixtures.albums_query |> Repo.delete_all

    assert Fixtures.albums_query |> Collection.Ecto.any?(@opts) == false
  end

  test "total" do
    assert Fixtures.albums_query |> Collection.Ecto.total(@opts) ==
           length(Fixtures.albums)
  end
end
