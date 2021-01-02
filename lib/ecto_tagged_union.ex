defmodule EctoTaggedUnion do
  alias EctoTaggedUnion.Utils

  @default_opts [tag: :tag]
  defmacro defunion(definition, tag_location \\ :internal, opts \\ []) do
    variants = Utils.parse_type_definition(definition, __CALLER__)
    opts = Keyword.merge(@default_opts, opts)

    head =
      quote location: :keep, bind_quoted: [variants: variants] do
        use Ecto.Type

        @impl true
        def type, do: :map
      end

    casts = Utils.build_casts(tag_location, variants, opts)
    loads = Utils.build_loads(tag_location, variants, opts)
    dumps = Utils.build_dumps(tag_location, variants, opts)
    [head, casts, loads, dumps]
  end
end
