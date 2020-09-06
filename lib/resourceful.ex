defmodule Resourceful do
  @moduledoc """
  Resourceful is a library intended to provide a common interface for  generic
  operations and representations for resources in an edge-facing API. These
  include:

    * Filtering
    * Introspection
    * Pagination
    * Representation
    * Searching
    * Sorting
    * Input validation
    * Type checking

  Its defaults are intended to be appropriate for web-based APIs. For instance,
  the filters are significantly simpler than SQL. The format for items such as
  sorting and pagination are also intended for easy adaptation to URL query
  strings. (The entire library is opinionated toward this use case.)

  Resources themselves are expected to be maps or structs.
  """
end
