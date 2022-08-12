defmodule Resourceful.TypeTest do
  use ExUnit.Case

  alias Resourceful.Test.Types
  alias Resourceful.Type
  alias Resourceful.Type.{Attribute, GraphedField, Relationship}

  def attributes do
    %{
      "id" => Attribute.new("id", :integer),
      "title" => Attribute.new("title", :string),
      "tracks" => Attribute.new("tracks", :integer)
    }
  end

  def registered_type, do: Types.fetch!("albums")

  def type, do: Type.new("albums", fields: attributes())

  test "new/2" do
    type = Type.new("object")
    assert type.fields == %{}
    assert type.id == nil
    assert type.max_filters == 4
    assert type.max_sorters == 2
    assert type.name == "object"
  end

  test "new/2 with keywords" do
    attributes = attributes()

    type =
      Type.new(
        "albums",
        fields: Map.values(attributes),
        max_filters: nil,
        max_sorters: 10
      )

    assert type.fields == attributes
    assert type.id == "id"
    assert type.max_filters == nil
    assert type.max_sorters == 10
    assert type.name == "albums"

    type = Type.new("albums", fields: attributes, id: "title")
    assert type.fields == attributes
    assert type.id == "title"
  end

  test "cache/2" do
    type = Type.cache(type(), :key1, "value1")

    assert type.cache == %{key1: "value1"}

    assert Type.cache(type, :key2, "value2").cache ==
             %{key1: "value1", key2: "value2"}
  end

  test "fetch_attribute/2" do
    rtype = registered_type()

    assert Type.fetch_attribute(rtype, "title") == Type.fetch_field(rtype, "title")
    assert {:error, {:attribute_not_found, _}} = Type.fetch_attribute(rtype, "artist")
  end

  test "fetch_field/3" do
    type = type()
    rtype = registered_type()

    not_found_err = {:error, {:field_not_found, %{key: "notPresent", resource_type: "albums"}}}

    assert Type.fetch_field(type, "notPresent") == not_found_err
    assert Type.fetch_field(rtype, "notPresent") == not_found_err

    assert Type.fetch_field(type, "tracks") == {:ok, attributes()["tracks"]}

    assert Type.fetch_field(rtype, "tracks") ==
             {:ok, rtype.registry.fetch_field_graph!("albums")["tracks"]}

    assert {:ok, %GraphedField{field: %Attribute{name: "name"}, name: "artist.name"}} =
             Type.fetch_field(rtype, "artist.name")

    assert {:ok, %GraphedField{field: %Relationship{name: "artist"}, name: "artist"}} =
             Type.fetch_field(rtype, "artist")
  end

  test "fetch_field!/3" do
    type = type()
    assert {:ok, Type.fetch_field!(type, "tracks")} == Type.fetch_field(type, "tracks")

    assert_raise Type.FieldError, fn ->
      Type.fetch_field!(type, "notPresent")
    end
  end

  test "fetch_graphed_field/3" do
    type = type()
    rtype = registered_type()

    assert Type.fetch_graphed_field(type, "tracks") ==
             {:error, {:field_not_found, %{key: "tracks", resource_type: "albums"}}}

    assert Type.fetch_graphed_field(rtype, "tracks") ==
             Type.fetch_field(rtype, "tracks")
  end

  test "fetch_graphed_field!/3" do
    rtype = registered_type()

    assert {:ok, Type.fetch_graphed_field!(rtype, "artist.name")} ==
             Type.fetch_graphed_field(rtype, "artist.name")

    assert_raise Type.FieldError, fn ->
      Type.fetch_graphed_field!(rtype, "artist.notPresent")
    end
  end

  test "fetch_local_field/3" do
    type = type()
    rtype = registered_type()

    assert Type.fetch_local_field(type, "tracks") == Type.fetch_field(type, "tracks")

    assert Type.fetch_local_field(rtype, "tracks") ==
             {:ok, Type.fetch_field!(rtype, "tracks").field}

    assert {:error, {:field_not_found, _}} = Type.fetch_local_field(rtype, "artist.name")
  end

  test "fetch_local_field!/3" do
    type = type()

    assert {:ok, Type.fetch_local_field!(type, "tracks")} ==
             Type.fetch_local_field(type, "tracks")

    assert_raise Type.FieldError, fn ->
      Type.fetch_local_field!(type, "notPresent")
    end
  end

  test "fetch_related_type/2" do
    type = type()
    rtype = registered_type()

    assert Type.fetch_related_type(type, "artists") ==
             {:error, {:no_type_registry, %{resource_type: "albums"}}}

    assert Type.fetch_related_type(rtype, "artists") == Types.fetch("artists")

    assert Type.fetch_related_type(rtype, "publishers") ==
             {:error, {:resource_type_not_registered, %{key: "publishers"}}}
  end

  test "fetch_relationship/2" do
    rtype = registered_type()

    assert Type.fetch_relationship(rtype, "artist") == Type.fetch_field(rtype, "artist")
    assert {:error, {:relationship_not_found, _}} = Type.fetch_relationship(rtype, "title")
  end

  test "field_graph/2" do
    assert Type.field_graph(type()) ==
             {:error, {:no_type_registry, %{resource_type: "albums"}}}

    assert {:ok, %{}} = Type.field_graph(registered_type())
  end

  test "has_local_field?/2" do
    type = type()
    rtype = registered_type()

    assert Type.has_local_field?(type, "tracks")
    assert Type.has_local_field?(rtype, "tracks")

    refute Type.has_local_field?(type, "artist")
    assert Type.has_local_field?(rtype, "artist")

    refute Type.has_local_field?(rtype, "artist.name")
  end

  test "id/2", do: assert(Type.id(type(), "name").id == "name")

  test "map_field/2" do
    assert Type.map_field(type(), "tracks") == {:ok, :tracks}
    assert Type.map_field(registered_type(), "tracks") == {:ok, [:tracks]}
  end

  test "map_id/2" do
    assert Type.map_id(%{id: 1}, type()) == 1
    assert Type.map_id(%{id: 1}, registered_type()) == 1
  end

  test "map_value/3" do
    assert Type.map_value(%{tracks: 2}, type(), "tracks") == 2
    assert Type.map_value(%{tracks: 2}, registered_type(), "tracks") == 2
  end

  test "map_values/3" do
    assert Type.map_values(
             %{artist: %{name: "Queen"}, title: "Queen II", tracks: 2},
             registered_type(),
             ["title", "artist.name"]
           ) == [{"title", "Queen II"}, {"artist.name", "Queen"}]
  end

  test "max_depth/2" do
    assert Type.max_depth(type(), 2).max_depth == 2
  end

  test "max_filters/2" do
    assert Type.max_filters(type(), 10).max_filters == 10
    assert Type.max_filters(type(), nil).max_filters == nil
  end

  test "max_sorters/2" do
    assert Type.max_sorters(type(), 10).max_sorters == 10
    assert Type.max_sorters(type(), nil).max_sorters == nil
  end

  test "meta/3" do
    type = Type.meta(type(), :key1, "value1")

    assert type.meta == %{key1: "value1"}

    assert Type.meta(type, :key2, "value2").meta ==
             %{key1: "value1", key2: "value2"}
  end

  test "name/2" do
    assert Type.name(type(), "object").name == "object"
  end

  test "put_field/2" do
    type = Type.new("object")
    refute Map.has_key?(type.fields, "number")

    attr = Attribute.new("number", :integer)

    type = Type.put_field(type, attr)
    assert Map.get(type.fields, "number") == attr
  end

  test "register/2" do
    type = type()

    refute type.registry

    rtype = Type.register(type, __MODULE__)

    assert rtype.registry == __MODULE__
  end

  test "string_name/1" do
    name = "albums.artist.name"
    assert Type.string_name(name) == name
    assert Type.string_name(~w[albums artist name]) == name
  end

  test "to_map/3" do
    assert Type.to_map(
             registered_type(),
             %{artist: %{name: "Queen"}, title: "Queen II", tracks: 2},
             ["artist.name", "title"]
           ) == %{"artist.name" => "Queen", "title" => "Queen II"}
  end

  test "validate_filter/2" do
    rtype = registered_type()
    field = Type.fetch_field!(rtype, "artist.name")
    ok = {:ok, {field, "eq", "Duran Duran"}}

    assert Type.validate_filter(rtype, {"artist.name", "Duran Duran"}) == ok
    assert Type.validate_filter(rtype, {"artist.name eq", "Duran Duran"}) == ok

    assert Type.validate_filter(rtype, {"artist.nam", "Duran Duran"}) ==
             {:error, {:attribute_not_found, %{key: "artist.nam", resource_type: "albums"}}}

    assert Type.validate_filter(rtype, {"artist.name et", "Duran Duran"}) ==
             {:error,
              {:invalid_filter_operator,
               %{attribute: "artist.name", operator: "et", value: "Duran Duran"}}}
  end

  test "validate_map_to!/1" do
    assert Type.validate_map_to!(:name) == :name
    assert Type.validate_map_to!("name") == "name"

    assert_raise Type.InvalidMapTo, fn ->
      Type.validate_map_to!([])
    end
  end

  test "validate_max_filters/3" do
    type = Type.max_filters(registered_type(), 1)
    filters = [Type.validate_filter(type, {"artist", "Duran Duran"})]

    assert Type.validate_max_filters(filters, type, %{source: ["filter"]}) == filters

    type = Type.max_filters(type, 0)

    assert Type.validate_max_filters(filters, type, %{source: ["filter"]}) ==
             [error: {:max_filters_exceeded, %{max_allowed: 0, source: ["filter"]}}] ++ filters
  end

  test "validate_max_sorters/3" do
    type = Type.max_sorters(registered_type(), 1)
    sorters = [Type.validate_sorter(type, "+artist")]

    assert Type.validate_max_sorters(sorters, type, %{source: ["sort"]}) == sorters

    type = Type.max_sorters(type, 0)

    assert Type.validate_max_sorters(sorters, type, %{source: ["sort"]}) ==
             [error: {:max_sorters_exceeded, %{max_allowed: 0, source: ["sort"]}}] ++ sorters
  end

  test "validate_name!/1" do
    assert Type.validate_name!("name") == "name"

    assert_raise Type.InvalidName, fn ->
      Type.validate_name!("name.with_dot")
    end
  end

  test "validate_sorter/2" do
    type = registered_type()
    field = Type.fetch_field!(type, "releaseDate")

    ok = {:ok, {:desc, field}}

    assert Type.validate_sorter(type, "-releaseDate") == ok

    assert Type.validate_sorter(type, "-releaseDat") ==
             {:error, {:attribute_not_found, %{key: "releaseDat", resource_type: "albums"}}}
  end

  test "without_cache/1" do
    type =
      type()
      |> Type.cache(:key, "value")
      |> Type.without_cache()

    assert type.cache == %{}
  end
end
