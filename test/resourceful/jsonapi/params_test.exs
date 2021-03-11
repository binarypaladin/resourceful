defmodule Resourceful.JSONAPI.ParamsTest do
  use ExUnit.Case

  alias Resourceful.JSONAPI.Params
  alias Resourceful.Test.Types
  alias Resourceful.Type

  test "validate/3 with valid params" do
    type = Types.get("albums")

    params = %{
      "fields" => %{"albums" => "releaseDate,title"},
      "filter" => %{"releaseDate lt" => "2001-01-01"},
      "page" => %{"number" => "2", "size" => "4"},
      "sort" => "-releaseDate,title"
    }

    {:ok, opts} = Params.validate(type, params)

    release_date = Type.fetch_graphed_field!(type, "releaseDate")
    title = Type.fetch_graphed_field!(type, "title")

    assert [
             fields: %{"albums" => ["releaseDate", "title"]},
             filter: [{release_date, "lt", ~D[2001-01-01]}],
             page: [number: 2, size: 4],
             sort: [desc: release_date, asc: title]
           ] == opts

    assert {:ok, [fields: %{"albums" => ["releaseDate"]}]} ==
             Params.validate(type, %{"fields" => %{"albums" => "releaseDate"}})
  end

  test "validate/3 with invalid params" do
    type = Types.get("albums")

    params = %{
      "fields" => "albums",
      "filter" => "releaseDate",
      "page" => "2",
      "sort" => %{}
    }

    assert {:error,
            [
              error: {:invalid_jsonapi_parameter, %{input: "albums", source: ["fields"]}},
              error: {:invalid_jsonapi_parameter, %{input: "releaseDate", source: ["filter"]}},
              error: {:invalid_jsonapi_parameter, %{input: "2", source: ["page"]}},
              error: {:invalid_jsonapi_parameter, %{input: %{}, source: ["sort"]}}
            ]} == Params.validate(type, params)
  end

  test "validate/3 with invalid type values" do
    type = Types.get("albums")

    params = %{
      "fields" => %{"albums" => ["releaseDate", "titl"]},
      "filter" => %{"releaseDate lt" => "x"},
      "page" => %{"size" => "z"},
      "sort" => "-releaseDate,titl"
    }

    assert {:error,
            [
              error:
                {:invalid_field,
                 %{
                   input: "titl",
                   key: "titl",
                   resource_type: "albums",
                   source: ["fields", "albums", 1]
                 }},
              error:
                {:type_cast_failure,
                 %{
                   attribute: "releaseDate",
                   input: "x",
                   source: ["filter", "releaseDate lt"],
                   type: :date
                 }},
              error: {:type_cast_failure, %{input: nil, source: [:page, :size], type: :integer}},
              error:
                {:field_not_found,
                 %{
                   input: "-releaseDate,titl",
                   key: "titl",
                   resource_type: "albums",
                   source: ["sort"]
                 }}
            ]} == Params.validate(type, params)
  end
end
