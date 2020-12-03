defmodule Resourceful.ErrorTest do
  use ExUnit.Case

  alias Resourceful.Error

  @data_with_errors %{
    k1: [
      {:ok, "a"},
      {:error, {:err_1, %{input: 0}}},
      [{:error, {:err_2, %{input: 1}}}, "d", "e"]
    ],
    k2: %{
      k2_1: {:ok, 1},
      k2_2: {:error, {:err_3, %{input: "x"}}},
      k2_3: [3, 4, {:error, {:err_4, %{input: "y"}}}]
    },
    k3: [
      %{k3_0_1: {:ok, "f"}, k3_0_2: {:error, {:err_4, %{input: 2}}}},
      %{k3_1_1: {:error, {:err_5, %{input: 3}}}, k3_1_2: "i"}
    ],
    k4: {:error, {:err_6, %{input: 4}}},
    k5: "k"
  }

  @data_without_errors %{
    k1: [ok: "a", ok: "b", ok: ["c", "d", "e"]],
    k2: %{n1: {:ok, 1}, n2: 2, n3: [3, 4, 5]},
    k3: [
      %{k3_0_1: {:ok, "f"}, k3_0_2: {:ok, "g"}},
      %{k3_1_1: "h", k3_1_2: "i"}
    ],
    k4: {:ok, "j"},
    k5: "k"
  }

  test "all/1" do
    assert Error.all(@data_with_errors) ==
             [
               err_1: %{input: 0, source: [:k1, 1]},
               err_2: %{input: 1, source: [:k1, 2, 0]},
               err_3: %{input: "x", source: [:k2, :k2_2]},
               err_4: %{input: "y", source: [:k2, :k2_3, 2]},
               err_4: %{input: 2, source: [:k3, 0, :k3_0_2]},
               err_5: %{input: 3, source: [:k3, 1, :k3_1_1]},
               err_6: %{input: 4, source: [:k4]}
             ]

    assert Error.all(@data_without_errors) == []
  end

  test "any?/1" do
    assert Error.any?({:error, :invalid}) == true
    assert Error.any?(ok: 1, error: :invalid) == true
    assert Error.any?(%{k1: {:error, :invalid}, k2: {:ok, 2}}) == true
    assert Error.any?(@data_with_errors) == true
    refute Error.any?({:ok, :error}) == true
    refute Error.any?(1) == true
    refute Error.any?(@data_without_errors) == true
  end

  test "delete_context_key/2" do
    error = {:error, {:invalid, %{input: "x"}}}

    assert error |> Error.delete_context_key(:source) == error
    assert error |> Error.delete_context_key(:input) == {:error, {:invalid, %{}}}
  end

  test "ok_value/1" do
    assert Error.ok_value(@data_without_errors) ==
             %{
               k1: ["a", "b", ["c", "d", "e"]],
               k2: %{n1: 1, n2: 2, n3: [3, 4, 5]},
               k3: [%{k3_0_1: "f", k3_0_2: "g"}, %{k3_1_1: "h", k3_1_2: "i"}],
               k4: "j",
               k5: "k"
             }
  end

  test "or_ok/1" do
    assert Error.or_ok(@data_with_errors) == {:error, Error.all(@data_with_errors)}

    assert Error.or_ok(@data_without_errors) == {:ok, Error.ok_value(@data_without_errors)}
  end

  test "prepend_source/2" do
    assert :type |> Error.prepend_source([:key]) ==
             {:error, {:type, %{source: [:key]}}}

    assert {:error, :type} |> Error.prepend_source([:key]) ==
             {:error, {:type, %{source: [:key]}}}

    assert {:error, {:type, %{source: ["k2"]}}}
           |> Error.prepend_source("k1") ==
             {:error, {:type, %{source: ["k1", "k2"]}}}
  end

  test "with_context/1" do
    assert :type |> Error.with_context() == {:error, {:type, %{}}}

    assert {:error, :type} |> Error.with_context() == {:error, {:type, %{}}}

    assert {:error, {:type, %{input: "abc"}}} |> Error.with_context() ==
             {:error, {:type, %{input: "abc"}}}
  end

  test "with_context/2" do
    assert {:error, :type} |> Error.with_context(%{key: "value"}) ==
             {:error, {:type, %{key: "value"}}}

    assert {:error, {:type, %{k1: "v1"}}} |> Error.with_context(%{k2: "v2"}) ==
             {:error, {:type, %{k1: "v1", k2: "v2"}}}
  end

  test "with_context/3" do
    assert {:error, :type} |> Error.with_context(:key, "value") ==
             {:error, {:type, %{key: "value"}}}

    assert {:error, {:type, %{k1: "v1"}}} |> Error.with_context(:k2, "v2") ==
             {:error, {:type, %{k1: "v1", k2: "v2"}}}
  end

  test "with_source/3" do
    assert :type |> Error.with_source(:key, %{input: "x"}) ==
      {:error, {:type, %{input: "x", source: [:key]}}}

    assert {:error, :type} |> Error.with_source(:key) ==
             {:error, {:type, %{source: [:key]}}}

    assert {:error, {:type, %{source: ["k2"]}}} |> Error.with_source("k1") ==
             {:error, {:type, %{source: ["k1"]}}}
  end
end
