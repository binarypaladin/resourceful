defmodule Resourceful.Test.Album do
  use Ecto.Schema
  import Ecto.Changeset

  schema "albums" do
    field :artist, :string
    field :release_date, :date
    field :title, :string
    field :tracks, :integer
  end

  def create_changeset(album, attrs) do
    album |> cast(attrs, [:id, :artist, :release_date, :title, :tracks])
  end
end
