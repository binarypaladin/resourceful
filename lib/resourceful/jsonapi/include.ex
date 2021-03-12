defmodule Resourceful.JSONAPI.Include do
  @moduledoc """
  Functions for validating includes, primarily for use with JSON:API
  [inclusion of related resources](https://jsonapi.org/format/#fetching-includes).

  Includes are just relationships names on the root type. A song, for instance,
  could include the album and, depending on the depth settings, could even
  include the album's artist.
  """

  alias Resourceful.{Error, JSONAPI, Type}
  alias Resourceful.Type.{GraphedField, Relationship}

  @doc """
  Validates whether a relationship may be included. A graphed relationship where
  `graph?` is true may be included.
  """
  @spec validate(%Type{}, String.t() | [String.t()]) ::
          [{:ok, %Type.GraphedField{}}] | [Error.t()]
  def validate(type, includes) when is_binary(includes) do
    validate(type, JSONAPI.Params.split_string_list(includes), includes)
  end

  def validate(%Type{} = type, includes, input \\ nil) do
    includes
    |> Stream.with_index()
    |> Enum.map(fn {include, index} ->
      with {:ok, rel_or_graph} = ok <- Type.fetch_relationship(type, include),
           :ok <- check_graph(type, rel_or_graph) do
        ok
      else
        error ->
          case input do
            nil -> Error.with_context(error, %{input: include, source: ["include", index]})
            input -> Error.with_context(error, %{input: input, source: ["include"]})
          end
      end
    end)
  end

  defp check_graph(_, %GraphedField{field: %Relationship{graph?: true}}), do: :ok

  defp check_graph(%{name: type}, %{name: key}) do
    Error.with_context(:cannot_include_relationship, %{key: key, resource_type: type})
  end
end
