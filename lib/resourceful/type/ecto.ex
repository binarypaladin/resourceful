defmodule Resourceful.Type.Ecto do
  @moduledoc """
  Creates a `Resourceful.Type` from an `Ecto.Schema` module. The use case
  is that internal data will be represented by the schema and client-facing data
  will be represented by the resource definition. Additionally, field names may
  be mapped differently to the client, such as camel case values. This can be
  done individually or with a single function as an option.

  Since `Resourceful.Type` instances use the same type system as Ecto, this
  is a relatively straightforward conversion.
  """

  alias Resourceful.{Type, Util}
  alias Resourceful.Type.Attribute

  @doc """
  Returns a `Resourceful.Type.Attribute` based on a field from an `Ecto.Schema`
  module.
  """
  @spec attribute(module(), atom(), keyword()) :: %Attribute{}
  def attribute(schema, field_name, opts \\ []) do
    Attribute.new(
      transform_name(field_name, Keyword.get(opts, :transform_names)),
      schema.__schema__(:type, field_name),
      Keyword.put(opts, :map_to, field_name)
    )
  end

  @doc """
  Returns a `Resourceful.Type` from an `Ecto.Schema` module by inferring
  values from the schema.

  ## Options

  For most options, a list of schema field names (atoms) will be passed in
  specifying the type's configuration for those fields. In these cases a value
  of `true` or `:all` will result in all fields being used. For example if you
  wanted to be able to query all fields, you would pass `[query: :all]`.

    * `:except` - Schema fields to be excluded from the type.
    * `:filter` - Schema fields allowed to be filtered.
    * `:only` - Schema fields to be included in the type.
    * `:query` - Schema fields allowed to be queried (sorted and filtered).
    * `:sort` - Schema fields allowed to be sorted.
    * `:transform_names` - A single argument function that takes the field name
      (an atom) and transforms it into either another atom or a string. A type
      of case conversion is the most likely use case.

  Addionally, any options not mentioned above will be passed directly to
  `Resourceful.Type.new/2`.
  """
  @spec type_with_schema(module(), keyword()) :: %Type{}
  def type_with_schema(schema, opts \\ []) do
    Type.new(
      Keyword.get(opts, :name, schema.__schema__(:source)),
      type_opts(schema, opts)
    )
  end

  defp attr_opts(attr_name, opts) do
    Keyword.merge(
      opts,
      Enum.map([:filter, :query, :sort], &{&1, in_opt_list?(opts, &1, attr_name)})
    )
  end

  defp expand_all_opt({opt, val}, fields)
       when opt in [:filter, :query, :sort] and val in [:all, true],
       do: {opt, fields}

  defp expand_all_opt(opt, _), do: opt

  defp expand_all_opts(fields, opts), do: Enum.map(opts, &expand_all_opt(&1, fields))

  defp in_opt_list?(opts, key, attr) do
    opts
    |> Keyword.get(key, [])
    |> Enum.member?(attr)
  end

  defp type_opts(schema, opts) do
    fields = Util.except_or_only!(opts, schema.__schema__(:fields))
    opts = expand_all_opts(fields, opts)

    Keyword.merge(opts,
      fields: Enum.map(fields, &attribute(schema, &1, attr_opts(&1, opts))),
      meta: %{ecto: %{schema: schema}},
      id: Keyword.get(opts, :id, schema.__schema__(:primary_key))
    )
  end

  defp transform_name(field_name, nil), do: to_string(field_name)

  defp transform_name(field_name, func) when is_function(func, 1), do: func.(field_name)
end
