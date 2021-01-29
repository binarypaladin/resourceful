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
    assert Collection.Ecto.all(Album, @opts) == Repo.all(Album)
  end

  test "any?" do
    assert Collection.Ecto.any?(Album, @opts) == true

    Repo.delete_all(Album)

    assert Collection.Ecto.any?(Album, @opts) == false
  end

  test "total" do
    assert Collection.Ecto.total(Album, @opts) == length(Fixtures.albums())
  end
end
