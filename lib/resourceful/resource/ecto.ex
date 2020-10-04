defmodule Resourceful.Resource.Ecto do
  defmodule InvalidSchemaFieldError do
    defexception message: "Fields must be included in schema."
  end

  alias Resourceful.Resource
  alias Resourceful.Resource.Attribute

  def attribute(schema, field_name, opts \\ []) do
    Attribute.new(
      transform_name(field_name, Keyword.get(opts, :transform_names)),
      schema.__schema__(:type, field_name),
      [map_to: field_name] ++ opts
    )
  end

  def resource(schema, opts \\ []) do
    Resource.new(
      Keyword.get(opts, :resource_type, schema.__schema__(:source)),
      resource_opts(schema, opts)
    )
  end

  defp attr_opts(attr_name, opts) do
    Enum.map(
      [:filter, :query, :sort],
      &{&1, in_opt_list?(opts, &1, attr_name)}
    ) ++ opts
  end

  defp check_opt_fields!(opt_fields, fields) do
    case opt_fields -- fields do
      [] ->
        opt_fields

      not_included ->
        error_fields = not_included |> Enum.map(&to_string/1) |> Enum.join(", ")
        raise InvalidSchemaFieldError, message: "Fields not included in schema: #{error_fields}"
    end
  end

  defp except_or_only(fields, opts) do
    except = Keyword.get(opts, :except)
    only = Keyword.get(opts, :only)

    if except && only, do: raise(ArgumentError, message: ":except cannot be used with :only")

    cond do
      only -> only |> check_opt_fields!(fields)
      except -> except |> check_opt_fields!(fields) |> fields_except(fields)
      true -> fields
    end
  end

  defp expand_all_opt({opt, val}, fields)
       when opt in [:filter, :query, :sort] and val in [:all, true],
       do: {opt, fields}

  defp expand_all_opt(opt, _), do: opt

  defp expand_all_opts(fields, opts), do: opts |> Enum.map(&expand_all_opt(&1, fields))

  defp fields_except(except, fields), do: fields -- except

  defp in_opt_list?(opts, key, attr), do: Keyword.get(opts, key, []) |> Enum.member?(attr)

  defp resource_opts(schema, opts) do
    fields = schema.__schema__(:fields) |> except_or_only(opts)
    opts = fields |> expand_all_opts(opts)

    [
      attributes: fields |> Enum.map(&attribute(schema, &1, attr_opts(&1, opts))),
      id: Keyword.get(opts, :id, schema.__schema__(:primary_key))
    ] ++ opts
  end

  defp transform_name(field_name, nil), do: Kernel.to_string(field_name)

  defp transform_name(field_name, func) when is_function(func, 1), do: func.(field_name)
end
