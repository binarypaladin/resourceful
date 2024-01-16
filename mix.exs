defmodule Resourceful.MixProject do
  use Mix.Project

  def project do
    [
      app: :resourceful,
      deps: deps(),
      description: "A type and query toolkit for web-based APIs.",
      elixir: "~> 1.14",
      name: "Resourceful",
      package: package(),
      source_url: "https://github.com/binarypaladin/resourceful",
      start_permanent: Mix.env() == :prod,
      version: "0.1.4"
    ]
  end

  def application, do: []

  defp deps do
    [
      {:ecto, "~> 3.9"},
      {:ecto_sql, "~> 3.9", only: [:test]},
      {:inflex, "~> 2.1", only: [:test]},
      {:postgrex, ">= 0.0.0", only: [:test]},
      {:ex_doc, ">= 0.0.0", only: [:dev], runtime: false}
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/binarypaladin/resourceful"},
      maintainers: ["Joshua Hansen"]
    }
  end
end
