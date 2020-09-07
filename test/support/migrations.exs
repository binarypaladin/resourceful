defmodule Resourceful.Test.Repo.Migrations.CreateAlbums do
  use Ecto.Migration

  def change do
    create table(:albums, primary_key: false) do
      add :id, :integer, primary_key: true
      add :artist, :string
      add :release_date, :date
      add :title, :string
      add :tracks, :integer
    end
  end
end
