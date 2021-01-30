defmodule Resourceful.JSONAPI.Params do
  def split_string_list(input), do: String.split(input, ~r/, */)
end
