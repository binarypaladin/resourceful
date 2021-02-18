defmodule Resourceful.JSONAPI.Pagination do
  @moduledoc """
  Validates parameters provided by various pagination strategies and returns
  paramaters as expected by `Resourceful.Collection`.
  """

  import Ecto.Changeset

  @default_strategy :resourceful
                    |> Application.get_env(:jsonapi, [])
                    |> Keyword.get(:pagination_strategy, :number_size)

  @default_max_page_size Application.get_env(:resourceful, :max_page_size, 100)

  @number_size %{
    size_field: :size,
    validations: %{
      number: [greater_than_or_equal_to: 1],
      size: [greater_than_or_equal_to: 1]
    }
  }

  def validate(%{} = params, opts \\ []) do
    do_validate(
      Keyword.get(opts, :pagination_strategy, @default_strategy),
      params,
      Keyword.get(opts, :max_page_size, @default_max_page_size)
    )
  end

  defp do_validate(:number_size, params, max_page_size) do
    @number_size
    |> do_validations(params, max_page_size)
    |> to_collection_params()
  end

  defp do_validations(strategy, params, max_page_size) do
    keys = Map.keys(strategy.validations)

    {%{}, Map.new(keys, &{&1, :integer})}
    |> cast(params, keys)
    |> do_number_validations(strategy.validations)
    |> validate_number(strategy.size_field, less_than_or_equal_to: max_page_size)
  end

  defp do_number_validations(changeset, number_validations) do
    Enum.reduce(number_validations, changeset, fn {key, opts}, chset ->
      validate_number(chset, key, opts)
    end)
  end

  defp to_collection_params(%{valid?: true} = changeset), do: Keyword.new(changeset.changes)

  defp to_collection_params(changeset), do: changeset
end
