defmodule EctoTaggedUnion.Utils do
  #########################################
  # Takes the leaf module name and uses it as a discriminator
  def parse_type_definition(variants, caller) do
    variants
    |> parse_variants(caller)
    |> validate_variants()
  end

  defp parse_variants(variants, caller, acc \\ [])
  defp parse_variants([], _caller, acc), do: acc

  defp parse_variants({:|, _, variants}, caller, acc) do
    parse_variants(variants, caller, acc)
  end

  defp parse_variants([head | tail], caller, acc) do
    parse_variants(tail, caller, [parse_variant(head, caller) | acc])
  end

  defp parse_variant({disc, {:__aliases__, _, _} = variant_alias}, caller) do
    variant_module = parse_alias(variant_alias, caller)
    {"#{disc}", variant_module}
  end

  defp parse_variant({:__aliases__, _, _} = variant_alias, caller) do
    variant_module = parse_alias(variant_alias, caller)
    disc = variant_module |> Module.split() |> Enum.at(-1)
    {disc, variant_module}
  end

  defp parse_alias({:__aliases__, _, _} = type, caller) do
    type
    |> Macro.expand(caller)
    |> Code.ensure_compiled!()
  end

  defp validate_variants(variants) do
    variants
    |> validate_unique_discs()
    |> validate_no_nesting()
  end

  defp validate_unique_discs(variants) do
    discs = Enum.map(variants, fn {disc, _mod} -> disc end)
    unique_discs = Enum.dedup(discs)

    if length(unique_discs) == length(variants) do
      variants
    else
      raise ArgumentError, "Duplicate discriminators: #{inspect(discs -- unique_discs)}"
    end
  end

  defp validate_no_nesting(variants) do
    variants
    |> Enum.each(fn {disc, variant_mod} ->
      :functions
      |> variant_mod.__info__()
      |> Enum.member?({:__tagged_union__, 1})
      |> case do
        true ->
          raise ArgumentError,
                "{#{disc}, #{inspect(variant_mod)}} is a union. Nested unions are not supported"

        false ->
          :ok
      end
    end)

    variants
  end

  #########################################

  defp impl do
    quote do
      @impl true
    end
  end

  def build_casts(variants, opts) do
    tag_name = Keyword.fetch!(opts, :tag)

    casts =
      for {disc, variant_mod} <- variants, tag_name <- [tag_name, Atom.to_string(tag_name)] do
        defcast(disc, variant_mod, tag_name)
      end

    fallback =
      quote bind_quoted: [tag_name: tag_name, variants: variants] do
        def cast(nil), do: {:ok, nil}

        def cast(map) do
          {:error,
           [
             {:invalid_tag,
              expected: Enum.map(unquote(variants), &elem(&1, 0)),
              got: map[unquote(tag_name)] || map["#{unquote(tag_name)}"]}
           ]}
        end
      end

    [impl(), casts, fallback]
  end

  defp defcast(disc, variant_mod, tag_name) do
    quote location: :keep,
          bind_quoted: [tag_name: tag_name, disc: disc, variant_mod: variant_mod] do
      def cast(%unquote(variant_mod){} = struct), do: {:ok, struct}

      def cast(%{unquote(tag_name) => n} = data)
          when n in [unquote(disc), unquote(String.to_existing_atom(disc))] do
        variant_mod = unquote(variant_mod)

        variant_mod.cast(data)
      end
    end
  end

  def build_loads(variants, opts) do
    tag_name = opts |> Keyword.fetch!(:tag) |> Atom.to_string()

    loads =
      for {disc, variant_mod} <- variants do
        build_load(disc, variant_mod, tag_name)
      end

    fallback =
      quote do
        def load(nil), do: {:ok, nil}

        def load(other) do
          :error
        end
      end

    [impl(), loads, fallback]
  end

  defp build_load(disc, variant_mod, tag_name) do
    quote location: :keep,
          bind_quoted: [tag_name: tag_name, disc: disc, variant_mod: variant_mod] do
      def load(%{unquote(tag_name) => unquote(disc)} = data) do
        variant_mod = unquote(variant_mod)
        {:ok, Ecto.embedded_load(variant_mod, data, :json)}
      end
    end
  end

  def build_dumps(variants, opts) do
    tag_name = Keyword.fetch!(opts, :tag)

    dumps =
      for {disc, variant_mod} <- variants do
        build_dump(disc, variant_mod, tag_name)
      end

    fallback =
      quote do
        def dump(nil), do: {:ok, nil}
        def dump(_), do: :error
      end

    [impl(), dumps, fallback]
  end

  defp build_dump(disc, variant_mod, tag_name) do
    quote location: :keep,
          bind_quoted: [tag_name: tag_name, disc: disc, variant_mod: variant_mod] do
      def dump(%unquote(variant_mod){} = data) do
        tag_name = unquote(tag_name)
        disc = unquote(disc)

        {:ok,
         data
         |> Ecto.embedded_dump(:json)
         |> Map.put(tag_name, disc)}
      end
    end
  end

  def build_utility_funcs(variants, opts) do
    tag_name = Keyword.fetch!(opts, :tag)

    variant =
      for {disc, variant_mod} <- variants, tag_name <- [tag_name, Atom.to_string(tag_name)] do
        quote location: :keep,
              bind_quoted: [tag_name: tag_name, disc: disc, variant_mod: variant_mod] do
          def variant(%{unquote(tag_name) => unquote(disc)} = data) do
            unquote(variant_mod)
          end
        end
      end

    disc =
      for {disc, variant_mod} <- variants do
        quote location: :keep do
          def disc(%unquote(variant_mod){}), do: unquote(disc)
        end
      end

    [variant, disc]
  end

  def build_underscore_funcs(variants, opts) do
    quote location: :keep, bind_quoted: [variants: variants, opts: opts] do
      def __tagged_union__(:variants), do: unquote(variants)
    end
  end
end
