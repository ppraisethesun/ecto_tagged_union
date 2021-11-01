# EctoTaggedUnion

## Installation

```elixir
def deps do
  [
    {:ecto_tagged_union, git: "https://github.com/ppraisethesun/ecto_tagged_union"}
  ]
end
```

## Usage

First, define variant schemas:
use `EctoTaggedUnion.Variant` or define your own cast/1 function

```elixir
defmodule Square do
  use EctoTaggedUnion.Variant
  import Ecto.Changeset

  embedded_schema do
    field(:side, :integer)
  end

  def changeset(data, attrs) do
    cast(data, attrs, [:side])
  end
end

defmodule Circle do
  use EctoTaggedUnion.Variant
  import Ecto.Changeset

  embedded_schema do
    field(:radius, :integer)
  end

  def changeset(data, attrs) do
    cast(data, attrs, [:radius])
  end
end
```

Tag is stored next to other fields of the variant.

```elixir
defmodule Shape do
  import EctoTaggedUnion

  defunion Square | Circle
end

iex> Shape.dump(%Circle{radius: 10})
{:ok, %{radius: 10, tag: "Circle"}]

iex> Shape.load(%{"radius" => 10, "tag" => "Circle"})
{:ok, %Shape.Circle{radius: 10}}

iex> Shape.cast(%{radius: 10, tag: "Circle"})
{:ok, %Shape.Circle{radius: 10}}
```

You can define custom tags with keyword lists:

```elixir
defmodule Shape do
  import EctoTaggedUnion
  defunion(square: Square, circle: Circle)
end

iex> Shape.dump(%Circle{radius: 10})
{:ok, %{radius: 10, tag: "circle"}}

iex> Shape.load(%{"radius" => 10, "tag" => "circle"})
{:ok, %Shape.Circle{radius: 10}}

iex> Shape.cast(%{radius: 10, tag: "circle"})
{:ok, %Shape.Circle{radius: 10}}
```
