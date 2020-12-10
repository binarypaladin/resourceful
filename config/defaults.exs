import Config

config :resourceful, :error_type_defaults, %{
  attribute_not_found: %{
    detail: "An attribute with the name `%{key}` could not be found for resource type `%{type}`.",
    title: "Attribute Could Not Be Found"
  },
  cannot_filter_by_attribute: %{
    detail: "`%{attribute}` is a valid attribute but cannot be used to filter resource.",
    title: "Resource Cannot Be Filtered By Attribute"
  },
  cannot_sort_by_attribute: %{
    detail: "`%{attribute}` is a valid attribute but cannot be used to sort resource.",
    title: "Resource Cannot Be Sorted By Attribute"
  },
  invalid_filter: %{
    title: "Invalid Filter"
  },
  invalid_filter_operator: %{
    detail: "`%{operator}` is not a valid filter operator.",
    title: "Invalid Filter Operator"
  },
  invalid_filter_value: %{
    detail: "`%{value}` is not compatible with filter operator `%{operator}`.",
    title: "Invalid Filter Value"
  },
  invalid_jsonapi_field: %{
    detail: "`%{key}` is not a valid field name for resource type `%{type}`.",
    title: "Invalid Field"
  },
  invalid_jsonapi_field_type: %{
    detail: "`%{key}` is not a valid resource type in this request.",
    title: "Invalid Field Type"
  },
  invalid_sorter: %{
    title: "Invalid Sorter"
  },
  max_filters_exceeded: %{
    detail: "Resource cannot be filtered by more than %{max_allowed} filters.",
    title: "Max Filters Exceeded"
  },
  max_sorters_exceeded: %{
    detail: "Resource cannot be sortered by more than %{max_allowed} sorters.",
    title: "Max Sorters Exceeded"
  },
  type_cast_failure: %{
    detail: "`%{input}` cannot be cast to type `%{type}`.",
    title: "Type Cast Failure"
  }
}
