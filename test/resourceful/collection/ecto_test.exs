defmodule Resourceful.Collection.EctoTest do
  use Resourceful.Test.DatabaseCase

  import Ecto.Query, warn: false

  alias Resourceful.Collection

  @opts [ecto_repo: Repo]

  test "all" do
    assert Collection.Ecto.all(Album, @opts) == Repo.all(Album)
  end

  test "any?" do
    assert Collection.Ecto.any?(Album, @opts) == true

    query = where(Album, title: "")

    assert Collection.Ecto.any?(query, @opts) == false
  end

  test "total" do
    assert Collection.Ecto.total(Album, @opts) == length(Fixtures.albums())
  end
end
