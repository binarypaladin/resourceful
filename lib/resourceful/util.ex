defmodule Resourceful.Util do
  @moduledoc """
  Extra utility functions. These are for miscellaneous shared functions that
  don't really fit with any other module but are shared across multiple modules.
  """

  @doc """
  Allows `:except` or `:only` options to be set in a keyword set of options. The
  options and the set are given as arguments and, depending on the options, a
  subset (or the set itself) will be returned.

  An exception will be raised if invalid arguments are passed or if both
  `:except` and `:only` are passed.
  """
  @spec except_or_only!(keyword(), %MapSet{} | list()) :: list()
  def except_or_only!(opts, set) do
    set = MapSet.new(set)
    except = Keyword.get(opts, :except)
    only = Keyword.get(opts, :only)

    if except && only, do: raise(ArgumentError, message: ":except cannot be used with :only")

    cond do
      only -> validate_except_or_only!(only, set)
      except -> MapSet.difference(set, validate_except_or_only!(except, set))
      true -> set
    end
    |> MapSet.to_list()
  end

  defp validate_except_or_only!(%MapSet{} = opt_set, set) do
    unless MapSet.subset?(opt_set, set) do
      bad_opts =
        opt_set
        |> MapSet.difference(set)
        |> MapSet.to_list()
        |> Stream.map(&to_string/1)
        |> Enum.join(", ")

      raise(ArgumentError, message: "#{bad_opts} are not valid :except or :only options")
    end

    opt_set
  end

  defp validate_except_or_only!(opt_set, set) do
    opt_set
    |> List.wrap()
    |> MapSet.new()
    |> validate_except_or_only!(set)
  end
end
