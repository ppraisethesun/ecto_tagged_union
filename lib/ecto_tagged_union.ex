defmodule EctoTaggedUnion do
  alias EctoTaggedUnion.Utils

  @default_opts [tag: :tag]
  defmacro defunion(definition, opts \\ []) do
    variants = Utils.parse_type_definition(definition, __CALLER__)
    opts = Keyword.merge(@default_opts, opts)

    head =
      quote location: :keep, bind_quoted: [variants: variants] do
        use Ecto.Type

        @impl true
        def type, do: :map
      end

    casts = Utils.build_casts(variants, opts)
    loads = Utils.build_loads(variants, opts)
    dumps = Utils.build_dumps(variants, opts)
    utility = Utils.build_utility_funcs(variants, opts)
    [head, casts, loads, dumps, utility]
  end
end
