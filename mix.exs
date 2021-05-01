defmodule EctoTaggedUnion.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_tagged_union,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: "Tagged union for ecto schemas",
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ecto, "~> 3.5"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"Github" => "https://github.com/ppraisethesun/tagged_union"}
    ]
  end

  defp docs do
    [
      extras: [
        "README.md": [title: "README"]
      ]
    ]
  end
end
