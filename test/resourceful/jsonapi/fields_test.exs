defmodule Resourceful.JSONAPI.FieldsTest do
  use ExUnit.Case

  alias Resourceful.JSONAPI.Fields
  alias Resourceful.Test.Types

  test "validate/2" do
    type = Types.get("albums")

    assert Fields.validate(type, %{"albums" => "releaseDate,title", "artists" => "name"}) ==
             %{"albums" => [ok: "releaseDate", ok: "title"], "artists" => [ok: "name"]}

    assert Fields.validate(type, %{"artists" => "nam,yearFounded"}) ==
             %{
               "artists" => [
                 error:
                   {:invalid_field,
                    %{
                      input: "nam,yearFounded",
                      key: "nam",
                      resource_type: "artists",
                      source: ["fields", "artists"]
                    }},
                 ok: "yearFounded"
               ]
             }

    assert Fields.validate(type, %{"albums" => ["releaseDate", "titl"]}) ==
             %{
               "albums" => [
                 ok: "releaseDate",
                 error:
                   {:invalid_field,
                    %{
                      input: "titl",
                      key: "titl",
                      resource_type: "albums",
                      source: ["fields", "albums", 1]
                    }}
               ]
             }

    assert Fields.validate(type, %{"records" => "releaseDate,title"}) ==
             %{"records" => [error: {:invalid_field_type, %{key: "records"}}]}
  end
end
