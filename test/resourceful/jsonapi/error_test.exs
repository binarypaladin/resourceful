defmodule Resourceful.JSONAPI.ErrorTest do
  use ExUnit.Case

  alias Resourceful.JSONAPI.Error

  @error_with_context {:error,
                       {:type_cast_failure,
                        %{
                          attribute: "releaseDate",
                          detail: "`x` cannot be cast to type `date`.",
                          input: "x",
                          source: ["filter", "releaseDate gt"],
                          title: "Type Cast Failure",
                          type: :date
                        }}}

  test "all/2" do
    assert {:error, [@error_with_context]} |> Error.all() ==
             [Error.to_map(@error_with_context)]
  end

  test "meta/2" do
    assert {:error, {:invalid, %{input: "x", source: [:filter]}}} |> Error.meta() ==
             %{"input" => "x"}

    assert {:error, {:invalid, %{source: [:filter]}}} |> Error.meta() == nil
    assert {:error, :invalid} |> Error.meta() == nil
  end

  test "source/2" do
    error = {:error, {:invalid, %{source: [:data, :attributes, :field]}}}

    assert Error.source(error) == %{"pointer" => "/data/attributes/field"}
    assert Error.source(error) == Error.source(error, source_type: "pointer")

    assert Error.source(error, source_type: "parameter") ==
             %{"parameter" => "data[attributes][field]"}
  end

  test "source_string/2" do
    source = [:data, :attributes, :field]

    assert [] |> Error.source_string("pointer") == ""
    assert [:data] |> Error.source_string("pointer") == "/data"
    assert source |> Error.source_string("pointer") == "/data/attributes/field"

    assert [] |> Error.source_string("parameter") == nil
    assert [:sort] |> Error.source_string("parameter") == "sort"
    assert source |> Error.source_string("parameter") == "data[attributes][field]"
  end

  test "status/2" do
    assert {:error, :invalid} |> Error.status() == nil
    assert {:error, {:teapot, %{http_status: 418}}} |> Error.status() == "418"
    assert {:error, :teapot} |> Error.status(http_status: 418) == "418"
  end

  test "to_map/2" do
    assert @error_with_context
           |> Error.to_map(http_status: 400, source_type: "parameter") ==
             %{
               "code" => "type_cast_failure",
               "detail" => "`x` cannot be cast to type `date`.",
               "meta" => %{"attribute" => "releaseDate", "input" => "x", "type" => :date},
               "source" => %{"parameter" => "filter[releaseDate gt]"},
               "status" => "400",
               "title" => "Type Cast Failure"
             }

    assert {:error, :some_issue} |> Error.to_map() == %{"code" => "some_issue"}
  end
end
