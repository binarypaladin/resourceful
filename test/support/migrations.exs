defmodule Resourceful.Test.Repo.Migrations.CreateArtists do
  use Ecto.Migration

  def change do
    create table(:artists, primary_key: false) do
      add(:id, :integer, primary_key: true)
      add(:name, :string)
      add(:year_founded, :integer)
    end
  end
end

defmodule Resourceful.Test.Repo.Migrations.CreateAlbums do
  use Ecto.Migration

  def change do
    create table(:albums, primary_key: false) do
      add(:id, :integer, primary_key: true)
      add(:artist_id, references(:artists))
      add(:release_date, :date)
      add(:title, :string)
      add(:tracks, :integer)
    end

    create(index(:albums, [:artist_id]))
  end
end

defmodule Resourceful.Test.Repo.Migrations.CreateSongs do
  use Ecto.Migration

  def change do
    create table(:songs, primary_key: false) do
      add(:id, :integer, primary_key: true)
      add(:album_id, references(:albums))
      add(:title, :string)
      add(:track, :integer)
    end

    create(index(:songs, [:album_id]))
    create(unique_index(:songs, [:album_id, :track]))
  end
end
