defmodule EctoTaggedUnion.Utils do
  #########################################
  # expands module names in type definition
  def parse_type_definition(variants, caller) do
    variants
    |> parse_variants(caller)
    |> Enum.map(fn variant ->
      disc = variant |> Module.split() |> Enum.at(-1)
      {disc, variant}
    end)
  end

  defp parse_variants(variants, caller, acc \\ [])
  defp parse_variants([], _caller, acc), do: acc

  defp parse_variants({:|, _, variants}, caller, acc) do
    parse_variants(variants, caller, acc)
  end

  defp parse_variants([{:__aliases__, _, _} = head | tail], caller, acc) do
    parse_variants(tail, caller, [parse_alias(head, caller) | acc])
  end

  defp parse_alias({:__aliases__, _, _} = type, caller) do
    Macro.expand(type, caller)
  end

  #########################################

  alias Ecto.Changeset

  defp impl do
    quote do
      @impl true
    end
  end

  def build_casts(tag_location, variants, opts) do
    casts = defcasts(tag_location, variants, opts)

    for {name, variant_mod} <- variants, tag_name <- [:type, "type"] do
      defcast(tag_name, name, variant_mod)
    end

    fallback =
      quote do
        def cast(nil), do: nil

        def cast(other) do
          :error
        end
      end

    [impl(), casts, fallback]
  end

  defp defcasts(:internal, variants, opts) do
    tag_name = Keyword.fetch!(opts, :tag)

    for {name, variant_mod} <- variants, tag_name <- [tag_name, Atom.to_string(tag_name)] do
      quote location: :keep,
            bind_quoted: [tag_name: tag_name, name: name, variant_mod: variant_mod] do
        def cast(%{unquote(tag_name) => unquote(name)} = data) do
          variant_mod = unquote(variant_mod)

          case variant_mod.changeset(struct(variant_mod), data) do
            %Changeset{valid?: true} = changeset -> Changeset.apply_action!(changeset, :insert)
            changeset -> {:error, changeset.errors}
          end
        end
      end
    end
  end

  defp defcasts(:external, variants, _opts) do
    for {name, variant_mod} <- variants do
      quote location: :keep,
            bind_quoted: [name: name, variant_mod: variant_mod] do
        def cast(%{unquote(name) => %{} = data}) do
          variant_mod = unquote(variant_mod)

          case variant_mod.changeset(struct(variant_mod), data) do
            %Changeset{valid?: true} = changeset -> Changeset.apply_action!(changeset, :insert)
            changeset -> {:error, changeset.errors}
          end
        end
      end
    end
  end

  defp defcasts(:adjacent, variants, opts) do
    tag_name = Keyword.fetch!(opts, :tag)
    content_name = Keyword.fetch!(opts, :content)

    for {name, variant_mod} <- variants,
        tag_name <- [tag_name, Atom.to_string(tag_name)],
        content_name <- [content_name, Atom.to_string(content_name)],
        is_atom(tag_name) === is_atom(content_name) do
      quote location: :keep,
            bind_quoted: [
              tag_name: tag_name,
              content_name: content_name,
              name: name,
              variant_mod: variant_mod
            ] do
        def cast(%{unquote(tag_name) => unquote(name), unquote(content_name) => data}) do
          variant_mod = unquote(variant_mod)

          case variant_mod.changeset(struct(variant_mod), data) do
            %Changeset{valid?: true} = changeset -> Changeset.apply_action!(changeset, :insert)
            changeset -> {:error, changeset.errors}
          end
        end
      end
    end
  end

  defp defcast(tag_name, name, variant_mod) do
    quote location: :keep,
          bind_quoted: [tag_name: tag_name, name: name, variant_mod: variant_mod] do
      def cast(%{unquote(tag_name) => unquote(name)} = data) do
        variant_mod = unquote(variant_mod)

        case variant_mod.changeset(struct(variant_mod), data) do
          %Changeset{valid?: true} = changeset -> Changeset.apply_action!(changeset, :insert)
          changeset -> {:error, changeset.errors}
        end
      end
    end
  end

  def build_loads(tag_location, variants, opts) do
    loads = defloads(tag_location, variants, opts)

    fallback =
      quote do
        def load(nil), do: nil

        def load(other) do
          :error
        end
      end

    [impl(), loads, fallback]
  end

  def defloads(:internal, variants, opts) do
    tag_name = opts |> Keyword.fetch!(:tag) |> Atom.to_string()

    for {name, variant_mod} <- variants do
      quote location: :keep,
            bind_quoted: [tag_name: tag_name, name: name, variant_mod: variant_mod] do
        def load(%{unquote(tag_name) => unquote(name)} = data) do
          variant_mod = unquote(variant_mod)
          Ecto.embedded_load(variant_mod, data, :json)
        end
      end
    end
  end

  def defloads(:external, variants, _opts) do
    for {name, variant_mod} <- variants do
      quote location: :keep,
            bind_quoted: [name: name, variant_mod: variant_mod] do
        def load(%{unquote(name) => %{} = data}) do
          variant_mod = unquote(variant_mod)
          Ecto.embedded_load(variant_mod, data, :json)
        end
      end
    end
  end

  def defloads(:adjacent, variants, opts) do
    tag_name = opts |> Keyword.fetch!(:tag) |> Atom.to_string()
    content_name = opts |> Keyword.fetch!(:content) |> Atom.to_string()

    for {name, variant_mod} <- variants do
      quote location: :keep,
            bind_quoted: [
              tag_name: tag_name,
              content_name: content_name,
              name: name,
              variant_mod: variant_mod
            ] do
        def load(%{unquote(tag_name) => unquote(name), unquote(content_name) => %{} = data}) do
          variant_mod = unquote(variant_mod)
          Ecto.embedded_load(variant_mod, data, :json)
        end
      end
    end
  end

  def build_dumps(tag_location, variants, opts) do
    dumps = defdumps(tag_location, variants, opts)

    fallback =
      quote do
        def dump(nil), do: nil
        def dump(_), do: :error
      end

    [impl(), dumps, fallback]
  end

  def defdumps(:internal, variants, opts) do
    tag_name = Keyword.fetch!(opts, :tag)

    for {name, variant_mod} <- variants do
      quote location: :keep,
            bind_quoted: [tag_name: tag_name, name: name, variant_mod: variant_mod] do
        def dump(%unquote(variant_mod){} = data) do
          tag_name = unquote(tag_name)
          name = unquote(name)

          data
          |> Ecto.embedded_dump(:json)
          |> Map.put(tag_name, name)
        end
      end
    end
  end

  def defdumps(:external, variants, opts) do
    tag_name = Keyword.fetch!(opts, :tag)

    for {name, variant_mod} <- variants do
      quote location: :keep,
            bind_quoted: [tag_name: tag_name, name: name, variant_mod: variant_mod] do
        def dump(%unquote(variant_mod){} = data) do
          tag_name = unquote(tag_name)
          name = unquote(name)

          %{name => Ecto.embedded_dump(data, :json)}
        end
      end
    end
  end

  def defdumps(:adjacent, variants, opts) do
    tag_name = Keyword.fetch!(opts, :tag)
    content_name = Keyword.fetch!(opts, :content)

    for {name, variant_mod} <- variants do
      quote location: :keep,
            bind_quoted: [
              tag_name: tag_name,
              content_name: content_name,
              name: name,
              variant_mod: variant_mod
            ] do
        def dump(%unquote(variant_mod){} = data) do
          tag_name = unquote(tag_name)
          content_name = unquote(content_name)
          name = unquote(name)

          %{
            tag_name => name,
            content_name => Ecto.embedded_dump(data, :json)
          }
        end
      end
    end
  end
end
