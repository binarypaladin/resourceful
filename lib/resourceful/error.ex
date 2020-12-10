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
  * `:key`: Not to be confused with `:source`, a `:key` key should always be
  present when a lookup of data is done by some sort of key and there is a
  failure.
  * `:value`: Not to be confused with `:input`, a `:value` key

  **Note:** all of these keys have convenience functions as it is a very common
  convention to create a new error with one of these keys or add one to an
  existing error.

  ### Error Types

  Both basic and contextual errors will contain an atom describing the specific
  type of error. These should be thought of as error codes and should be unique
  to the kinds of errors. For example, `:attribute_not_found` means that in some
  context, an attribute for a given resource doesn't exist. This could be an
  attempt to filter or sort. Either way, the error type remains the same. In
  both contexts, this error means the same thing.

  Contextual errors of a particular type should always contain at least some
  expected keys in their context maps. For example, `:attribute_not_found`
  should always contain a `:name` and may contain other information. More is
  usually better when it comes to errors.

  Keys should remain consistent in their use. `:invalid_filter_operator`, for
  example, should always contain an `:attribute` key implying that the failure
  was on a valid attribute whereas `:attribute_not_found` contains a `:key` key
  implying it was never resolved to an actual attribute.
  """

  @error_type_defaults Application.get_env(:resourceful, :error_type_defaults)

  @doc """
  Mostly a convenience function to use instead of `list/1` with the option to
  auto source errors as well. Additionally it will take a non-collection value
  and convert it to a list.

  Returns a list of errors.
  """
  def all(errors, opts \\ [])

  def all(errors, opts) when is_list(errors) or is_map(errors) do
    if Keyword.get(opts, :auto_source) do
      errors |> auto_source()
    else
      errors
    end
    |> list()
  end

  def all(value, opts), do: [value] |> all([auto_source: false] ++ opts)

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
  Transverses an arbitrary data structure that may contain errors and prepends
  `:source` data given the error's position in the data structure using either
  an index from a list or a key from a map.

  **Note:** This will not work for keyword lists. In order to infer source
  information they must first be converted to maps.

  Returns input data structure with errors modified to contain `:source` in
  their context.
  """
  def auto_source(error_or_enum, prefix \\ [])

  def auto_source(%{} = map, prefix),
    do: map |> Map.new(fn {src, val} -> {src, auto_source(val, prefix ++ [src])} end)

  def auto_source(list, prefix) when is_list(list) do
    list
    |> Enum.with_index()
    |> Enum.map(fn {val, src} -> auto_source(val, prefix ++ [src]) end)
  end

  def auto_source({:error, _} = error, prefix), do: error |> prepend_source(prefix)

  def auto_source(non_error, _), do: non_error

  @doc """
  Extracts the context map from an error.

  Returns a context map.
  """
  def context({:error, {_, %{} = context}}), do: context

  def context({:error, _}), do: %{}

  def context(%{} = context), do: context

  @doc """
  Deletes `key` from an error's context map if present.

  Returns an error tuple.
  """
  def delete_context_key({:error, {type, %{} = context}}, key),
    do: {:error, {type, Map.delete(context, key)}}

  def delete_context_key({:error, _} = error, _), do: error

  @doc """
  Many error types should, at a minimum, have an associated `:title`. If there
  are regular context values, it should also include a `:detail` value as well.
  Both of these keys provide extra information about the nature of the error
  and can help the client understand the particulars of the provided context.
  While it might not be readily obvious what `:key` means in an error, if it is
  used in `:detail` it will help the client understand the significance.

  Unlike the error's type itself--which realistically should serve as an error
  code of sorts--the title should should be more human readable and able to be
  localized, although it should be consistent. Similarly, detail should be able
  to be localized although it can change depending on the specifics of the error
  or values in the context map.

  This function handles injecting default `:title` and `:detail` items into the
  context map if they are available for an error type and replacing context-
  related bindings in messages. (See `message_with_context/2` for details.)

  In the future, this is also where localization should happen.

  Returns an error tuple.
  """
  def humanize(error, opts \\ [])

  def humanize(errors, opts) when is_list(errors),
    do: errors |> Enum.map(&humanize(&1, opts))

  def humanize({:error, errors}, opts) when is_list(errors),
    do: {:error, humanize(errors, opts)}

  def humanize({:error, {type, %{} = context}}, _opts) do
    {:error,
     {type,
      [:detail, :title]
      |> Enum.reduce(context, fn key, new_ctx ->
        case Map.get(context, key) || default_type_message([type, key]) do
          nil -> new_ctx
          msg -> new_ctx |> Map.put(key, message_with_context(msg, context))
        end
      end)}}
  end

  def humanize({:error, _} = error, opts),
    do: error |> with_context() |> humanize(opts)

  @doc """
  Transforms an arbitrary data structure that may contain errors into a single,
  flat list of those errors. Non-error values are removed. Collections are
  checked recursively.

  Maps are given special treatment in that their values are checked but their
  keys are discarded.

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
  def list(enum) when is_list(enum) or is_map(enum),
    do: enum |> flatten_maps() |> List.flatten() |> Enum.filter(&any?/1)

  @doc """
  Replaces context bindings in a message with atom keys in a context map.

  A message of `"Invalid input %{input}." would have `%{input}` replaced with
  the value in the context map of `:input`.

  Returns a string.
  """
  def message_with_context(message, %{} = context) do
    Regex.replace(~r/%\{(\w+)\}/, message, fn _, key ->
      context |> Map.get(String.to_atom(key)) |> to_string()
    end)
  end

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
  def or_ok(value, opts \\ []) do
    case any?(value) do
      true -> {:error, all(value, opts)}
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
  def prepend_source({:error, {error, %{source: source} = context}}, prefix),
    do: {:error, {error, %{context | source: List.wrap(prefix) ++ source}}}

  def prepend_source({:error, {error, %{} = context}}, prefix),
    do: {:error, {error, context |> Map.put(:source, List.wrap(prefix))}}

  def prepend_source(error_or_type, prefix),
    do: error_or_type |> with_context() |> prepend_source(prefix)

  @doc """
  Adds a context map to an error if it lacks one, converting a basic error to a
  contextual error. It may also take a single atom to prevent error generating
  code from having to constantly wrap errors in an `:error` tuple.

  Returns a contextual error tuple.
  """
  def with_context({:error, {type, %{}}} = error) when is_atom(type), do: error

  def with_context({:error, type}) when is_atom(type), do: contextual_error(type)

  def with_context(type) when is_atom(type), do: contextual_error(type)

  def with_context(error_or_type, %{} = context),
    do: error_or_type |> with_context() |> merge_context(context)

  def with_context(error_or_type, key, value),
    do: error_or_type |> with_context() |> with_context_value(key, value)

  @doc """
  Convenience function to create or modify an existing error with `:input`
  context.

  Returns a contextual error.
  """
  def with_input(error_or_type, input),
    do: error_or_type |> with_context(:input, input)

  @doc """
  Convenience function to create or modify an existing error with `:key`
  context.

  Returns a contextual error.
  """
  def with_key(error_or_type, key), do: error_or_type |> with_context(:key, key)

  @doc """
  Adds source context to an error and replaces `:source` if present.

  Returns a contextual error tuple.
  """
  def with_source(error_or_type, source, %{} = context \\ %{}) do
    error_or_type
    |> with_context(context)
    |> delete_context_key(:source)
    |> prepend_source(source)
  end

  defp contextual_error(type), do: {:error, {type, %{}}}

  defp default_type_message(path), do: @error_type_defaults |> get_in(path)

  defp flatten_maps(list) when is_list(list), do: list |> Enum.map(&flatten_maps/1)

  defp flatten_maps(%{} = map), do: map |> Map.values() |> flatten_maps()

  defp flatten_maps(value), do: value

  defp merge_context({:error, {type, %{} = context}}, new_context),
    do: {:error, {type, Map.merge(context, new_context)}}

  defp with_context_value({:error, {type, %{} = context}}, key, value),
    do: {:error, {type, Map.put(context, key, value)}}
end
