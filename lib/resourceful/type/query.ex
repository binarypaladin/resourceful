defmodule Resourceful.Type.Ecto.Query do
  @moduledoc """
  This module is something of hack designed to deal with the fact that Ecto does
  not make it simple to:

    1. Dynamically assigned aliases to joins. When specifying `:as` it _must_ be
       a compile-time atom. A recent reference to this issue can be found
       [here](https://elixirforum.com/t/build-dynamic-bindings-for-ecto-query-order-by/1638/17).
       This was learned the hard way. This is especially frustrating because
       the aside from assignment, the aliases can be referenced dynamically
       throughout the rest of the query DSL with a `^`.
    2. Preload joins if a join is already present and handle join introspection
       in general.

  The easiest way to solve this was to manipulate the struct because there's
  nothing magical about aliases. They're just a named reference to a positional
  binding. Preloads operate similarly. A tree of tuples and keyword lists
  defines which associations should be preloaded.

  Join introspection is also important so fields can be added to a query in an
  ad-hoc manner without having to care whether the query contains joins or not.

  ## A Note About Intended Use Cases

  It's important to remember that unless you go out of your way to mess with
  data structures in fields (I say this because this module is going out of its
  way to mess with data structures) relationships that support inclusion must
  follow a one-to-one path from start to finish.

  See `Resourceful.Type.Relationship` for a broader explanation on this design
  decision.

  ## Is this a good idea?

  It's certainly possible the underlying `Ecto.Query` structs change. This sort
  of manipulation is effectively using a private API. Hopefully getting proper
  support for this behavior is doable.

  Additionally, it's possible to handle some (and maybe all) of this using
  macros. However, that ultimately seemed every more convoluted and confusing.
  At least this is mostly simple recursion.

  What it does do is solve the problem it needed to solve.
  """

  import Ecto.Query, warn: false

  alias Resourceful.Type

  @doc """
  Including a field does two things:

  1. It automatically joins any necessary relationships (see `join_field/3`).
  2. It preloads said relationships.

  This allows a single query to bring back all of the data and also allows
  filtering and sorting to work on related attributes, not just those of the
  root type.

  For reference, an `Ecto.Query` stores preload instructions meant to happen
  with joins in the `:assocs` key in the form of a tree of keyword lists and
  tuples.

  A single join looks like this: `[<assoc_name>: {<position>, []}]` The tuple
  contains the position of the binging for the related join and a list of any
  child joins which would be in the same form as the parent.

  In the song/album/artist example this could look like the following:
  `[album: {1, [artist: {2, []}]}]`.
  """
  @spec include_field(any(), %Type{}, String.t()) :: %Ecto.Query{}
  def include_field(queryable, %Type{} = type, field_name) do
    graph_path =
      type
      |> Type.fetch_graphed_field!(field_name)
      |> graph_path()

    queryable
    |> join_graph(graph_path)
    |> merge_preloads(graph_path)
  end

  defp merge_preloads(queryable, graph_path) do
    %{queryable | assocs: build_new_preloads(graph_path, queryable.assocs, queryable.aliases)}
  end

  defp build_new_preloads([], assocs, _), do: assocs

  defp build_new_preloads([graphed_rel | path], assocs, aliases) do
    assoc_name = graphed_rel.field.map_to

    child =
      case Keyword.get(assocs, assoc_name) do
        nil ->
          {postition(graphed_rel, aliases), build_new_preloads(path, [], aliases)}

        {postition, child_assocs} ->
          {postition, build_new_preloads(path, child_assocs, aliases)}
    end

    Keyword.put(assocs, assoc_name, child)
  end

  defp postition(%{query_alias: {alias_name, _}}, aliases) do
    Map.fetch!(aliases, alias_name)
  end

  @doc """
  Joining a field joins all associations connected to all relationships in the
  field's graph. For example, if viewing a song and the field
  `album.artist.name` is joined, two relationships will be joined: the song's
  `album`, and the album's `artist`.

  The join will be given an alias of the full relationship name. So, the album
  will be aliases as `album` and the artist will be aliased as `album.artist`.

  If those joins have already been made, the queryable will remain unchanged.

  Fields resolving to attributes are ignored, but if they are children of a
  relationship, the relationship will be included.
  """
  @spec join_field(any(), Type.graphed_field()) :: %Ecto.Query{}
  def join_field(queryable, graphed_field) do
    join_graph(queryable, graph_path(graphed_field))
  end

  @doc """
  Like `join_field/2` except it takes a type and a field name rather than the
  graphed field directly.
  """
  @spec join_field(any(), %Type{}, String.t()) :: %Ecto.Query{}
  def join_field(queryable, %Type{} = type, field_name) do
    graphed_field = Type.fetch_graphed_field!(type, field_name)
    join_field(queryable, graphed_field)
  end

  defp graph_path(graphed_field, path \\ [])

  defp graph_path(nil, path), do: path

  defp graph_path(%{field: %Type.Attribute{}, parent: parent}, path) do
    graph_path(parent, path)
  end

  defp graph_path(graphed_field, path) do
    graph_path(graphed_field.parent, [graphed_field | path])
  end

  defp join_graph(queryable, graph_path) do
    Enum.reduce(graph_path, queryable, fn graphed_rel, q ->
      maybe_join(q, graphed_rel)
    end)
  end

  defp maybe_join(queryable, %{query_alias: join_as} = graphed_field) do
    case has_named_binding?(queryable, join_as) do
      true -> queryable
      _ -> named_join(queryable, graphed_field, join_as)
    end
  end

  defp named_join(queryable, %{field: field, parent: nil}, join_as) do
    queryable
    |> join(:left, [q], assoc(q, ^field.map_to))
    |> alias_last_join(join_as)
  end

  defp named_join(
    queryable,
    %{field: field, parent: %{query_alias: {parent_alias, _}}},
    join_as
  ) do
    queryable
    |> join(:left, [_, {^parent_alias, p}], assoc(p, ^field.map_to))
    |> alias_last_join(join_as)
  end

  defp alias_last_join(%{aliases: aliases, joins: joins} = query, {alias_name, _}) do
    new_joins =
      Enum.map(joins, fn join ->
        case join do
          %{as: nil} -> %{join | as: alias_name}
          _ -> join
        end
      end)

    new_aliases = Map.put(aliases, alias_name, length(new_joins))

    %{query | aliases: new_aliases, joins: new_joins}
  end
end
