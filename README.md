# EctoTaggedUnion

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ecto_tagged_union` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_tagged_union, "~> 0.1.0"}
  ]
end
```

## Usage

First, define variant schemas:

```elixir
defmodule Shape.Circle do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :radius, :integer
  end

  @fields [:radius]
  def changeset(data, attrs) do
    data
    |> cast(attrs, @fields)
  end
end

defmodule Shape.Rectangle do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :height, :integer
    field :width, :integer
  end

  @fields [:height, :width]
  def changeset(data, attrs) do
    data
    |> cast(attrs, @fields)
  end
end
```

### Internally tagged

By default, tag is stored next to other fields of the variant.

```elixir
defmodule Shape do
  import EctoTaggedUnion
  alias Shape.Circle
  alias Shape.Rectangle

  defunion Circle | Rectangle
end

iex> Shape.dump(%Shape.Circle{radius: 10})
%{radius: 10, tag: "Circle"}

iex> Shape.load(%{"radius" => 10, "tag" => "Circle"})
%Shape.Circle{radius: 10}

iex> Shape.cast(%{radius: 10, tag: "Circle"})
%Shape.Circle{radius: 10}
```

### Externally tagged

```elixir
defmodule Shape do
  import EctoTaggedUnion
  alias Shape.Circle
  alias Shape.Rectangle

  defunion Circle | Rectangle, :external
end

iex> Shape.dump(%Shape.Circle{radius: 10})
%{"Circle" => %{radius: 10}}

iex> Shape.load(%{"Circle" => %{"radius" => 10}})
%Shape.Circle{radius: 10}

iex> Shape.cast(%{"Circle" => %{radius: 10}})
%Shape.Circle{radius: 10}
```

### Adjacently tagged

The tag and the content are adjacent to each other as two fields within the same map.

```elixir
defmodule Shape do
  import EctoTaggedUnion
  alias Shape.Circle
  alias Shape.Rectangle

  defunion Circle | Rectangle, :adjacent, tag: :t, content: :c
end

iex> Shape.dump(%Shape.Circle{radius: 10})
%{c: %{radius: 10}, t: "Circle"}

iex> Shape.load(%{"c" => %{"radius" => 10}, "t" => "Circle"})
%Shape.Circle{radius: 10}

iex> Shape.cast(%{t: "Circle", c: %{radius: 10}})
%Shape.Circle{radius: 10}
```
