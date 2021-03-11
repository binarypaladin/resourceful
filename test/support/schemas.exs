defmodule Resourceful.Test.Artist do
  use Ecto.Schema
  import Ecto.Changeset

  schema "artists" do
    field(:name, :string)
    field(:year_founded, :integer)

    has_many(:albums, Resourceful.Test.Album)
  end

  def create_changeset(attrs) do
    cast(%__MODULE__{}, attrs, [:id, :name, :year_founded])
  end
end

defmodule Resourceful.Test.Album do
  use Ecto.Schema
  import Ecto.Changeset

  schema "albums" do
    field(:release_date, :date)
    field(:title, :string)
    field(:tracks, :integer)

    belongs_to(:artist, Resourceful.Test.Artist)
  end

  def create_changeset(attrs) do
    cast(%__MODULE__{}, attrs, [:id, :artist_id, :release_date, :title, :tracks])
  end
end

defmodule Resourceful.Test.Song do
  use Ecto.Schema
  import Ecto.Changeset

  schema "songs" do
    field(:title, :string)
    field(:track, :integer)

    belongs_to(:album, Resourceful.Test.Album)
  end

  def create_changeset(attrs) do
    cast(%__MODULE__{}, attrs, [:id, :album_id, :title, :track])
  end
end
