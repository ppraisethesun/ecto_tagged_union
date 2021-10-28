defmodule EctoTaggedUnionTest do
  use ExUnit.Case

  describe "module name as discrimitator" do
    defmodule First do
      use EctoTaggedUnion.Variant
      import Ecto.Changeset

      embedded_schema do
        field(:first, :string)
      end

      def changeset(data, attrs) do
        cast(data, attrs, [:first])
      end
    end

    defmodule Second do
      use EctoTaggedUnion.Variant
      import Ecto.Changeset

      embedded_schema do
        field(:second, :integer)
      end

      def changeset(data, attrs) do
        cast(data, attrs, [:second])
      end
    end

    defmodule Union do
      import EctoTaggedUnion
      defunion(First | Second)
    end

    defmodule TestSchema do
      use Ecto.Schema

      embedded_schema do
        field(:union, Union)
      end
    end

    test "cast success" do
      assert {:ok, nil} == Union.cast(nil)
      assert {:ok, %First{}} = Union.cast(%{tag: "First", first: "asdsa"})
      assert {:ok, %Second{}} = Union.cast(%{tag: "Second", second: 123})

      assert {:ok, %First{}} = Union.cast(%First{first: "asdsa"})
      assert {:ok, %Second{}} = Union.cast(%Second{second: 123})
    end

    test "cast error" do
      assert {:error, [{:invalid_tag, _}]} = Union.cast(%{tag: "Third"})
      assert {:error, [{:invalid_tag, _}]} = Union.cast(%{"tag" => "Third"})

      assert {:error,
              %Ecto.Changeset{
                errors: [
                  second: {"is invalid", [type: :integer, validation: :cast]}
                ]
              }} = Union.cast(%{tag: "Second", second: "asd"})
    end

    test "load success" do
      assert {:ok, %First{}} = Union.load(%{"tag" => "First"})
      assert {:ok, %First{}} = Union.load(%{"tag" => "First", "first" => "asdsa"})
      assert {:ok, %Second{}} = Union.load(%{"tag" => "Second", "second" => 123})
    end

    test "load error" do
      assert :error = Union.load(%{tag: :First})
      assert :error = Union.load(%{"tag" => :First})
    end

    test "dump" do
      assert {:ok, nil} == Union.dump(nil)
      assert {:ok, %{tag: "First", first: "asdsad"}} = Union.dump(%First{first: "asdsad"})
    end

    test "variant" do
      assert First = Union.variant(%{"tag" => "First"})
    end

    test "name" do
      assert "First" = Union.name(%First{})
    end
  end

  describe "custom discriminator" do
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

    defmodule Shape do
      import EctoTaggedUnion
      defunion(square: Square, circle: Circle)
    end

    defmodule TestSchema2 do
      use Ecto.Schema

      embedded_schema do
        field(:shape, Shape)
      end

      def changeset(struct \\ %__MODULE__{}, attrs) do
        struct
        |> Ecto.Changeset.cast(attrs, [:shape])
      end
    end

    test "cast success" do
      assert {:ok, nil} == Shape.cast(nil)
      assert {:ok, %Square{}} = Shape.cast(%{tag: "square", side: 1})
      assert {:ok, %Circle{}} = Shape.cast(%{tag: "circle", radius: 123})
    end

    test "cast error" do
      assert {:error, [{:invalid_tag, _}]} = Shape.cast(%{tag: "triangle"})
      assert {:error, [{:invalid_tag, _}]} = Shape.cast(%{"tag" => "triangle"})

      assert {:error,
              %Ecto.Changeset{
                errors: [
                  radius: {"is invalid", [type: :integer, validation: :cast]}
                ]
              }} = Shape.cast(%{tag: "circle", radius: "asd"})
    end

    test "load success" do
      assert {:ok, %Square{}} = Shape.load(%{"tag" => "square"})
      assert {:ok, %Square{}} = Shape.load(%{"tag" => "square", "side" => 1})
      assert {:ok, %Circle{}} = Shape.load(%{"tag" => "circle", "radius" => 123})
    end

    test "load error" do
      assert :error = Shape.load(%{tag: :square})
      assert :error = Shape.load(%{"tag" => :square})
    end

    test "dump" do
      assert {:ok, nil} == Shape.dump(nil)
      assert {:ok, %{tag: "square", side: 1}} = Shape.dump(%Square{side: 1})
    end

    test "variant" do
      assert Square = Shape.variant(%{"tag" => "square"})
    end

    test "name" do
      assert "square" = Shape.name(%Square{side: 1})
    end

    test "dumps variant if Ecto.embedded_dump is called with union inside embed" do
      data = %TestSchema2{
        shape: nil
      }

      assert %{shape: nil} = Ecto.embedded_dump(data, :json)

      data = %TestSchema2{
        shape: %Square{side: 1}
      }

      assert %{shape: %{tag: "square", side: 1}} = Ecto.embedded_dump(data, :json)
    end
  end
end
