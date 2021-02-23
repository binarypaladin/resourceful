defmodule Resourceful.JSONAPI.FieldsTest do
  use ExUnit.Case

  alias Resourceful.JSONAPI.Fields
  alias Resourceful.Test.Fixtures

  @fields MapSet.new(["artist", "releaseDate", "title", "tracks"])
  @cached_fields MapSet.new(["title"])

  test "from_attributes/1" do
    type = Fixtures.jsonapi_type()
    assert Fields.from_attributes(type) == @fields

    type = put_in(type, [Access.key(:meta), :jsonapi], %{attributes: @cached_fields})
    assert Fields.from_attributes(type) == @cached_fields
  end

  test "from_type/1" do
    type = Fixtures.jsonapi_type()
    assert Fields.from_type(type) == @fields

    type = put_in(type, [Access.key(:meta), :jsonapi], %{fields: @cached_fields})
    assert Fields.from_type(type) == @cached_fields
  end

  test "validate/2" do
    type = Fixtures.jsonapi_type()

    assert Fields.validate(type, %{"albums" => "releaseDate,title"}) ==
             %{"albums" => [ok: "releaseDate", ok: "title"]}

    assert Fields.validate(type, %{"albums" => "releaseDate,titl"}) ==
             %{
               "albums" => [
                 ok: "releaseDate",
                 error:
                   {:invalid_jsonapi_field,
                    %{
                      input: "releaseDate,titl",
                      key: "titl",
                      resource_type: "albums",
                      source: ["fields", "albums"]
                    }}
               ]
             }

    assert Fields.validate(type, %{"albums" => ["releaseDate", "titl"]}) ==
             %{
               "albums" => [
                 ok: "releaseDate",
                 error:
                   {:invalid_jsonapi_field,
                    %{
                      input: "titl",
                      key: "titl",
                      resource_type: "albums",
                      source: ["fields", "albums", 1]
                    }}
               ]
             }

    assert Fields.validate(type, %{"records" => "releaseDate,title"}) ==
             %{"records" => [error: {:invalid_jsonapi_field_type, %{key: "records"}}]}
  end
end
