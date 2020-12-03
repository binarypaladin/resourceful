defmodule Resourceful.Error do
  @moduledoc """
  Errors in `Resourceful` follow a few conventions. This module contains
  functions to help work with those conventions. Client-facing errors are
  loosely inspired by and should be easily converted to [JSON API-style
  errors](https://jsonapi.org/format/#errors), however they should also be
  suitable when JSON API isn't used at all.

  ## Error Structure

  All errors returned in `Resourceful` are expected to be two element tuples
  where the first element is `:error`. This is a common Elixir and Erlang
  convention, but it's strict for the purposes of this library. `Resourceful`
  generates and expects one of two kinds of errors:

  ### Basic Errors

  Basic errors are always a two element tuple where the second element is an
  atom that should related to specific kind of error returned. These are meant
  for situations where context is either easily inferred, unnecessary, or
  obvious in some other manner.

  Example: `{:error, :basic_err}`

  Basic errors that require context are often transformed into contextual errors
  by higher level functions as they have context that lower level functions do
  not.

  ### Contextual Errors

  Contextual errors are always a two element tuple where the second element is
  another two element tuple in which the first element is an atom and the second
  element is a map containing contextual information such as user input, data
  being validated, and/or the source of the error. The map's keys must be atoms.

  Example: `{:error, {:context_err, %{input: "XYZ", source: ["email_address"]}}`

  Errors outside of this format are not expected to work with these functions.

  #### Sources

  While not strictly required by contextual errors the `:source` key is used to
  indicate an element in a complex data structure that is responsible for a
  particular error. It must be a list of atoms, strings, or integers used to
  navigate a tree of data. Non-nested values should still be in the form of a
  list as prefixing sources is common. It's common for functions generating
  errors to be ignorant of their full context and higher level functions to
  prepend errors with their current location.

  #### Other Common Conventions

  There are a few other keys that appear in errors regularly:

  * `:detail`: A human friendly description about the error. If there is
  information related to resolving the error, it belongs here.
  * `:input`: A text representation of the actual input given by the client. It
  should be as close as possible to the original. (In general, `IO.inspect/1` is
  used.)

  ### Error Types

  Both basic and contextual errors will contain an atom describing the specific
  type of error. These should be thought of as error codes and should be unique
  to the kinds of errors. For example, `:attribute_not_found` means that in some
  context, an attribute for a given resource doesn't exist. This could be an
  attempt to filter or sort. Either way, the error type remains the same. In
  both contexts, this error means the same thing.

  Contextual errors of a particular type should always contain at least some
  expected keys in their context maps. For example, `:attribute_not_found`
  should always contain a `:source` and may contain other information. More is
  usually better when it comes to errors.
  """

  @doc """
  Transforms an arbitrary data structure that may contain errors into a single,
  flat list of those errors. Non-error values are removed. Collections are
  checked recursively.

  Maps are given special treatment in that their values are checked but keys
  used only to define a `:source`.

  By convention, simple errors aren't deeply nested so converting to a flat list
  shouldn't cause any confusion about the origin of the errors. In situations
  where nested data may contain errors, it is important to use complex errors
  that contain `source` information.

  This format is meant to keep reading errors fairly simple and consistent at
  the edge. Clients can rely on reading a single list of errors regardless of
  whether transversing nested validation failures or handling more simple single
  fault situations.

  This function is also designed with another convention in mind: mixing
  successes and failures in a single payload. A design goal of error use in this
  library is to wait until as late as possible to return errors. That way, a
  single request can return the totality of its failure to the client. This way,
  many different paths can be evaluated and if there are any errors along the
  way, those errors can be returned in full.

  Returns a list of errors.
  """
  def all(errors) when is_list(errors) or is_map(errors),
    do: errors |> flatten_errors()

  def all(value), do: [value] |> all()

  @doc """
  Recursively checks arbitrary data structures for any basic or contextual
  errors.

  Returns `true` or `false`.
  """
  def any?({:error, _}), do: true

  def any?(list) when is_list(list), do: list |> Enum.any?(&any?/1)

  def any?(%{} = map), do: map |> Map.values() |> any?()

  def any?(_), do: false

  @doc """
  Deletes `key` from an error's context map if present.

  Returns an error tuple.
  """
  def delete_context_key({:error, {type, %{} = context}}, key),
    do: {:error, {type, Map.delete(context, key)}}

  def delete_context_key({:error, _} = error, _), do: error

  @doc """
  Recursively transforms arbitrary data structures containing `:ok` tuples with
  just values. Values which are not in `:ok` tuples are left untouched.

  It does not check for errors. If errors are included, they will remain in the
  structure untouched. This function is designed to work on error free data and
  is unlikely to be used on its own but rather with `or_ok/1`.

  Keyword lists where `:ok` may be included with other keys won't be returned
  as probably intended. Keep this limitation in mind.

  Returns the input data structure with all instances of `{:ok, value}` replaced
  with `value`.
  """
  def ok_value({:ok, value}), do: ok_value(value)

  def ok_value(list) when is_list(list), do: list |> Enum.map(&ok_value/1)

  def ok_value(%{} = map), do: Map.new(map, fn {k, v} -> {k, ok_value(v)} end)

  def ok_value(value), do: value

  @doc """
  Checks an arbitrary data structure for errors and returns either the errors
  or valid data.

  See `all/1`, `any?/1`, and `ok_value/1` for specific details as this function
  combines the three into a common pattern. Return the errors if there are any
  or the validated data.

  Returns either a list of errors wrapped in an `:error` tuple or valid data
  wrapped in an `:ok` tuple.
  """
  def or_ok(value) do
    case any?(value) do
      true -> {:error, all(value)}
      _ -> {:ok, ok_value(value)}
    end
  end

  @doc """
  Adds or prepends source context to an error. A common pattern when dealing
  with sources in nested data structures being transversed recursively is for
  the child structure to have no knowledge of the parent structure. Once the
  child errors are resolved the parent can then prepend its location in the
  structure to the child's errors.

  Returns a contextual error tuple.
  """
  def prepend_source(errors, prefix) when is_list(errors),
    do: errors |> Enum.map(&prepend_source(&1, prefix))

  def prepend_source({:error, {error, %{source: source} = context}}, prefix),
    do: {:error, {error, %{context | source: List.wrap(prefix) ++ List.wrap(source)}}}

  def prepend_source({:error, {error, %{} = context}}, prefix),
    do: {:error, {error, context |> Map.put(:source, List.wrap(prefix))}}

  def prepend_source({:error, _} = error, prefix),
    do: error |> with_context() |> prepend_source(prefix)

  @doc """
  Adds a context map to an error if it lacks one, converting a basic error to a
  contextual error.

  Returns a contextual error tuple.
  """
  def with_context({:error, {type, %{}}} = error) when is_atom(type), do: error

  def with_context({:error, type}) when is_atom(type), do: {:error, {type, %{}}}

  def with_context(error, %{} = context),
    do: error |> with_context() |> merge_context(context)

  def with_context(error, key, value),
    do: error |> with_context() |> with_context_value(key, value)

  @doc """
  Adds source context to an error and replaces `:source` if present. Leaves
  non-error values as is.

  Returns a contextual error tuple.
  """
  def with_source({:error, _} = error, source),
    do: error |> delete_context_key(:source) |> prepend_source(source)

  def with_source(ok, _), do: ok

  defp all_value(%{} = map) do
    map
    |> Enum.filter(fn {_, val} -> any?(val) end)
    |> Enum.map(fn {src, val} -> all_value(val) |> prepend_source(src) end)
  end

  defp all_value(list) when is_list(list) do
    list
    |> Enum.with_index()
    |> Enum.filter(fn {val, _} -> any?(val) end)
    |> Enum.map(fn {val, src} -> all_value(val) |> prepend_source(src) end)
  end

  defp all_value({:error, _} = error), do: error

  defp error_value({:error, value}), do: value

  defp error_value(value), do: value

  defp flatten_errors(errors),
    do: errors |> all_value() |> List.flatten() |> Enum.map(&error_value/1)

  defp merge_context({:error, {type, %{} = context}}, new_context),
    do: {:error, {type, Map.merge(context, new_context)}}

  defp with_context_value({:error, {type, %{} = context}}, key, value),
    do: {:error, {type, Map.put(context, key, value)}}
end
