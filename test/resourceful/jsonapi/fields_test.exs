defmodule Resourceful.JSONAPI.FieldsTest do
  use ExUnit.Case

  alias Resourceful.JSONAPI.Fields
  alias Resourceful.Test.Fixtures

  @fields MapSet.new(["artist", "releaseDate", "title", "tracks"])
  @cached_fields MapSet.new(["title"])

  test "from_attributes/1" do
    resource = Fixtures.jsonapi_resource()
    assert Fields.from_attributes(resource) == @fields

    resource = put_in(resource, [Access.key(:meta), :jsonapi], %{attributes: @cached_fields})
    assert Fields.from_attributes(resource) == @cached_fields
  end

  test "from_resource/1" do
    resource = Fixtures.jsonapi_resource()
    assert Fields.from_resource(resource) == @fields

    resource = put_in(resource, [Access.key(:meta), :jsonapi], %{fields: @cached_fields})
    assert Fields.from_resource(resource) == @cached_fields
  end

  test "validate/2" do
    resource = Fixtures.jsonapi_resource()

    assert Fields.validate(resource, %{"albums" => "releaseDate,title"}) ==
             %{"albums" => [ok: "releaseDate", ok: "title"]}

    assert Fields.validate(resource, %{"albums" => "releaseDate,titl"}) ==
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

    assert Fields.validate(resource, %{"albums" => ["releaseDate", "titl"]}) ==
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

    assert Fields.validate(resource, %{"records" => "releaseDate,title"}) ==
             %{"records" => [error: {:invalid_jsonapi_field_type, %{key: "records"}}]}
  end
end
