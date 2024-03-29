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
      %{k3_0_1: {:ok, "f"}, k3_0_2: {:error, {:err_5, %{input: 2}}}},
      %{k3_1_1: {:error, {:err_6, %{input: 3}}}, k3_1_2: "i"}
    ],
    k4: {:error, {:err_7, %{input: 4}}},
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

  test "all/2" do
    assert Error.all(@data_with_errors) == Error.list(@data_with_errors)

    assert Error.all(@data_with_errors, auto_source: true) ==
             @data_with_errors
             |> Error.auto_source()
             |> Error.list()

    assert Error.all({:error, :err_1}) == [error: :err_1]
    assert Error.all({:error, :err_1}, auto_source: true) == [error: :err_1]

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

  test "auto_source/1" do
    assert Error.auto_source(@data_with_errors) ==
             %{
               k1: [
                 {:ok, "a"},
                 {:error, {:err_1, %{input: 0, source: [:k1, 1]}}},
                 [{:error, {:err_2, %{input: 1, source: [:k1, 2, 0]}}}, "d", "e"]
               ],
               k2: %{
                 k2_1: {:ok, 1},
                 k2_2: {:error, {:err_3, %{input: "x", source: [:k2, :k2_2]}}},
                 k2_3: [3, 4, {:error, {:err_4, %{input: "y", source: [:k2, :k2_3, 2]}}}]
               },
               k3: [
                 %{
                   k3_0_1: {:ok, "f"},
                   k3_0_2: {:error, {:err_5, %{input: 2, source: [:k3, 0, :k3_0_2]}}}
                 },
                 %{
                   k3_1_1: {:error, {:err_6, %{input: 3, source: [:k3, 1, :k3_1_1]}}},
                   k3_1_2: "i"
                 }
               ],
               k4: {:error, {:err_7, %{input: 4, source: [:k4]}}},
               k5: "k"
             }
  end

  test "context/2" do
    context = %{input: "x"}

    assert Error.context({:error, {:invalid, context}}) == context
    assert Error.context({:error, :invalid}) == %{}
    assert Error.context(context) == context
  end

  test "delete_context_key/2" do
    error = {:error, {:invalid, %{input: "x"}}}

    assert Error.delete_context_key(error, :source) == error
    assert Error.delete_context_key(error, :input) == {:error, {:invalid, %{}}}
  end

  test "from_changeset/1" do
    types = %{number: :integer, size: :integer}

    change = fn data ->
      {data, types}
      |> Ecto.Changeset.cast(data, Map.keys(types))
      |> Ecto.Changeset.validate_required(:number)
      |> Ecto.Changeset.validate_number(:number, greater_than_or_equal_to: 1)
      |> Ecto.Changeset.validate_number(:size, greater_than_or_equal_to: 1)
    end

    errors = change.(%{"number" => "0", "size" => "a"})

    assert Error.from_changeset(errors) ==
             [
               error: {
                 :input_validation_failure,
                 %{
                   detail: "must be greater than or equal to %{number}",
                   input: "0",
                   kind: :greater_than_or_equal_to,
                   number: 1,
                   source: [:number]
                 }
               },
               error: {
                 :type_cast_failure,
                 %{input: "a", source: [:size], type: :integer}
               }
             ]
  end

  test "humanize/2" do
    error = {:error, {:type_cast_failure, %{input: "x", type: :date}}}

    assert Error.humanize(error) ==
             {:error,
              {:type_cast_failure,
               %{
                 detail: "`x` cannot be cast to type `date`.",
                 input: "x",
                 title: "Type Cast Failure",
                 type: :date
               }}}

    error = Error.with_context(error, %{detail: "`%{input}` isn't a %{type}", title: "Fail"})

    assert Error.humanize(error) ==
             {:error,
              {:type_cast_failure,
               %{detail: "`x` isn't a date", input: "x", title: "Fail", type: :date}}}
  end

  test "list/1" do
    assert Error.list(@data_with_errors) ==
             [
               error: {:err_1, %{input: 0}},
               error: {:err_2, %{input: 1}},
               error: {:err_3, %{input: "x"}},
               error: {:err_4, %{input: "y"}},
               error: {:err_5, %{input: 2}},
               error: {:err_6, %{input: 3}},
               error: {:err_7, %{input: 4}}
             ]

    assert Error.all(@data_without_errors) == []
  end

  test "message_with_context/2" do
    message = "Hello, my name is %{name}."

    assert Error.message_with_context(message, %{name: "Inigo Montoya"}) ==
             "Hello, my name is Inigo Montoya."

    assert Error.message_with_context(message, %{"name" => "Rupert"}) ==
             "Hello, my name is ."
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

    assert Error.or_ok(@data_with_errors, auto_source: true) ==
             {:error, Error.all(@data_with_errors, auto_source: true)}

    assert Error.or_ok(@data_without_errors) == {:ok, Error.ok_value(@data_without_errors)}
  end

  test "prepend_source/2" do
    assert Error.prepend_source(:type, [:key]) ==
             {:error, {:type, %{source: [:key]}}}

    assert Error.prepend_source({:error, :type}, [:key]) ==
             {:error, {:type, %{source: [:key]}}}

    assert Error.prepend_source({:error, {:type, %{source: ["k2"]}}}, "k1") ==
             {:error, {:type, %{source: ["k1", "k2"]}}}
  end

  test "with_context/1" do
    assert Error.with_context(:type) == {:error, {:type, %{}}}

    assert Error.with_context({:error, :type}) == {:error, {:type, %{}}}

    assert Error.with_context({:error, {:type, %{input: "abc"}}}) ==
             {:error, {:type, %{input: "abc"}}}
  end

  test "with_context/2" do
    assert Error.with_context({:error, :type}, %{key: "value"}) ==
             {:error, {:type, %{key: "value"}}}

    assert Error.with_context({:error, {:type, %{k1: "v1"}}}, %{k2: "v2"}) ==
             {:error, {:type, %{k1: "v1", k2: "v2"}}}
  end

  test "with_context/3" do
    assert Error.with_context({:error, :type}, :key, "value") ==
             {:error, {:type, %{key: "value"}}}

    assert Error.with_context({:error, {:type, %{k1: "v1"}}}, :k2, "v2") ==
             {:error, {:type, %{k1: "v1", k2: "v2"}}}
  end

  test "with_input/2" do
    assert Error.with_input(:type, "input") ==
             {:error, {:type, %{input: "input"}}}
  end

  test "with_key/2" do
    assert Error.with_key(:type, "key") == {:error, {:type, %{key: "key"}}}
  end

  test "with_source/3" do
    assert Error.with_source(:type, :key, %{input: "x"}) ==
             {:error, {:type, %{input: "x", source: [:key]}}}

    assert Error.with_source({:error, :type}, :key) ==
             {:error, {:type, %{source: [:key]}}}

    assert Error.with_source({:error, {:type, %{source: ["k2"]}}}, "k1") ==
             {:error, {:type, %{source: ["k1"]}}}
  end
end
