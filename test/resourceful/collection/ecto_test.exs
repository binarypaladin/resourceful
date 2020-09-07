defmodule Resourceful.Collection.EctoTest do
  use ExUnit.Case

  alias Resourceful.Collection
  alias Resourceful.Test.Album
  alias Resourceful.Test.Fixtures
  alias Resourceful.Test.Repo

  @opts [ecto_repo: Repo]

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Fixtures.seed_database()
  end

  test "all" do
    assert Album |> Collection.Ecto.all(@opts) == Album |> Repo.all()
  end

  test "any?" do
    assert Album |> Collection.Ecto.any?(@opts) == true

    Album |> Repo.delete_all()

    assert Album |> Collection.Ecto.any?(@opts) == false
  end

  test "total" do
    assert Album |> Collection.Ecto.total(@opts) == length(Fixtures.albums())
  end
end
