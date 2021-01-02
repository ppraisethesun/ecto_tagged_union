defmodule EctoTaggedUnionTest do
  use ExUnit.Case

  defmodule First do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field(:first, :string)
    end

    def changeset(data, attrs) do
      data
      |> cast(attrs, [:first])
    end
  end

  defmodule Second do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field(:second, :integer)
    end

    def changeset(data, attrs) do
      data
      |> cast(attrs, [:second])
    end
  end

  defmodule TestSchema do
    use Ecto.Schema
    import EctoTaggedUnion

    defmodule Internal do
      import EctoTaggedUnion
      defunion(First | Second)
    end

    defmodule External do
      import EctoTaggedUnion
      defunion(First | Second, :external)
    end

    defmodule Adjacent do
      import EctoTaggedUnion
      defunion(First | Second, :adjacent, tag: :t, content: :c)
    end

    embedded_schema do
      field(:internal, Internal)
      field(:external, External)
      field(:adjacent, Adjacent)
    end
  end

  alias TestSchema.Adjacent
  alias TestSchema.Internal
  alias TestSchema.External

  describe "internal" do
    test "cast success" do
      assert nil == Internal.cast(nil)
      assert %First{} = Internal.cast(%{tag: "First", first: "asdsa"})
      assert %Second{} = Internal.cast(%{tag: "Second", second: 123})
    end

    test "cast error" do
      assert :error = Internal.cast(%{tag: "Third"})

      assert {:error, [second: {"is invalid", [type: :integer, validation: :cast]}]} =
               Internal.cast(%{tag: "Second", second: "asd"})
    end

    test "load success" do
      assert %First{} = Internal.load(%{"tag" => "First"})
      assert %First{} = Internal.load(%{"tag" => "First", "first" => "asdsa"})
      assert %Second{} = Internal.load(%{"tag" => "Second", "second" => 123})
    end

    test "load error" do
      assert :error = Internal.load(%{tag: :First})
      assert :error = Internal.load(%{"tag" => :First})
    end

    test "dump" do
      assert nil == Internal.dump(nil)
      assert %{tag: "First", first: "asdsad"} = Internal.dump(%First{first: "asdsad"})
    end
  end

  describe "external" do
    test "cast success" do
      assert nil == External.cast(nil)
      assert %First{} = External.cast(%{"First" => %{first: "asdsa"}})
      assert %Second{} = External.cast(%{"Second" => %{second: 123}})
    end

    test "cast error" do
      assert :error = External.cast(%{"Third" => %{}})

      assert {:error, [second: {"is invalid", [type: :integer, validation: :cast]}]} =
               External.cast(%{"Second" => %{second: "asd"}})
    end

    test "load success" do
      assert %First{} = External.load(%{"First" => %{}})
      assert %First{} = External.load(%{"First" => %{"first" => "asdsa"}})
      assert %Second{} = External.load(%{"Second" => %{"second" => 123}})
    end

    test "load error" do
      assert :error = External.load(%{First: %{}})
    end

    test "dump" do
      assert nil == External.dump(nil)
      assert %{"First" => %{first: "asdsad"}} = External.dump(%First{first: "asdsad"})
    end
  end

  describe "adjacent" do
    test "cast success" do
      assert nil == Adjacent.cast(nil)
      assert %First{} = Adjacent.cast(%{"t" => "First", "c" => %{first: "asdsa"}})
      assert %Second{} = Adjacent.cast(%{"t" => "Second", "c" => %{second: 123}})
    end

    test "cast error" do
      assert :error = Adjacent.cast(%{"t" => "Third", "c" => %{}})

      assert {:error, [second: {"is invalid", [type: :integer, validation: :cast]}]} =
               Adjacent.cast(%{"t" => "Second", "c" => %{second: "asd"}})
    end

    test "load success" do
      assert %First{} = Adjacent.load(%{"t" => "First", "c" => %{}})
      assert %First{} = Adjacent.load(%{"t" => "First", "c" => %{"first" => "asdsa"}})
      assert %Second{} = Adjacent.load(%{"t" => "Second", "c" => %{"second" => 123}})
    end

    test "load error" do
      assert :error = Adjacent.load(%{First: %{}})
    end

    test "dump" do
      assert nil == Adjacent.dump(nil)
      assert %{t: "First", c: %{first: "asdsad"}} = Adjacent.dump(%First{first: "asdsad"})
    end
  end
end
