defmodule Resourceful.Collection.EctoTest do
  use Resourceful.Test.DatabaseCase

  alias Resourceful.Collection

  @opts [ecto_repo: Repo]

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
