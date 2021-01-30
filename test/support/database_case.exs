defmodule Resourceful.Test.DatabaseCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Resourceful.Test.{Album, Fixtures, Repo}
      import Resourceful.Test.DatabaseCase
      import Resourceful.Test.Helpers
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Resourceful.Test.Repo)
    Resourceful.Test.Fixtures.seed_database()
  end
end
