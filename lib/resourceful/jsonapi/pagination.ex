defmodule Resourceful.JSONAPI.Pagination do
  import Ecto.Changeset

  @default_strategy :resourceful
                    |> Application.get_env(:jsonapi, [])
                    |> Keyword.get(:pagination_strategy, :number_size)

  @max_resources_per Application.get_env(:resourceful, :max_resources_per, 100)

  @number_size %{
    per_field: :size,
    validations: %{
      number: [greater_than_or_equal_to: 1],
      size: [greater_than_or_equal_to: 1]
    }
  }

  def validate(%{} = params, opts \\ []) do
    do_validate(
      Keyword.get(opts, :pagination_strategy, @default_strategy),
      params,
      Keyword.get(opts, :max_resources_per, @max_resources_per)
    )
  end

  defp convert_param_names(changeset, page_key, per_key) do
    Enum.reduce(
      %{page: page_key, per: per_key},
      [],
      fn {new_key, old_key}, params ->
        case get_change(changeset, old_key) do
          nil -> params
          num -> Keyword.put(params, new_key, num)
        end
      end
    )
  end

  defp do_validate(:number_size, params, max_resources_per) do
    @number_size
    |> do_validations(params, max_resources_per)
    |> to_collection_params(&number_size_collection_params/1)
  end

  defp do_validations(strategy, params, max_resources_per) do
    keys = Map.keys(strategy.validations)

    {%{}, Map.new(keys, &{&1, :integer})}
    |> cast(params, keys)
    |> do_number_validations(strategy.validations)
    |> validate_number(strategy.per_field, less_than_or_equal_to: max_resources_per)
  end

  defp do_number_validations(changeset, number_validations) do
    Enum.reduce(number_validations, changeset, fn {key, opts}, chset ->
      validate_number(chset, key, opts)
    end)
  end

  defp number_size_collection_params(changeset), do: convert_param_names(changeset, :number, :size)

  defp to_collection_params(%{valid?: true} = changeset, func), do: func.(changeset)

  defp to_collection_params(changeset, _), do: changeset
end
