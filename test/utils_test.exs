defmodule EctoTaggedUnion.UtilsTest do
  use ExUnit.Case

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

  defmodule Rectangle do
    use EctoTaggedUnion.Variant
    import Ecto.Changeset

    embedded_schema do
      field(:width, :integer)
      field(:length, :integer)
    end

    def changeset(data, attrs) do
      cast(data, attrs, [:length, :width])
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

  defmodule Parallelepiped do
    import EctoTaggedUnion
    defunion(square: Square, rectangle: Rectangle)
  end

  test "raises if there are duplicate discriminators" do
    assert_raise ArgumentError, fn ->
      EctoTaggedUnion.Utils.parse_type_definition(
        quote(do: [square: Square, square: Circle]),
        __ENV__
      )
    end
  end

  test "raises if trying to create nested union" do
    assert_raise ArgumentError, fn ->
      EctoTaggedUnion.Utils.parse_type_definition(
        quote(do: [square: Square, rectangle: Parallelepiped]),
        __ENV__
      )
    end
  end
end
