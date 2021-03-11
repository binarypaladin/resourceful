ExUnit.start()

alias Resourceful.Test.Repo

Application.put_env(
  :ecto,
  Repo,
  adapter: Ecto.Adapters.Postgres,
  url:
    System.get_env(
      "RESOURCEFUL_TEST_DATABASE_URL",
      "ecto://postgres@localhost/resourceful_test"
    ),
  pool: Ecto.Adapters.SQL.Sandbox
)

Code.require_file("support/repo.exs", __DIR__)

{:ok, _} = Ecto.Adapters.Postgres.ensure_all_started(Repo, :temporary)

_ = Ecto.Adapters.Postgres.storage_down(Repo.config())
:ok = Ecto.Adapters.Postgres.storage_up(Repo.config())

{:ok, _pid} = Repo.start_link()

Code.require_file("support/migrations.exs", __DIR__)

:ok = Ecto.Migrator.up(Repo, 0, Resourceful.Test.Repo.Migrations.CreateArtists, log: false)
:ok = Ecto.Migrator.up(Repo, 1, Resourceful.Test.Repo.Migrations.CreateAlbums, log: false)
:ok = Ecto.Migrator.up(Repo, 2, Resourceful.Test.Repo.Migrations.CreateSongs, log: false)

Ecto.Adapters.SQL.Sandbox.mode(Repo, :manual)
Process.flag(:trap_exit, true)

Code.require_file("support/schemas.exs", __DIR__)
Code.require_file("support/fixtures.exs", __DIR__)
Code.require_file("support/types.exs", __DIR__)
Code.require_file("support/helpers.exs", __DIR__)
Code.require_file("support/database_case.exs", __DIR__)
