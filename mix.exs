defmodule Resourceful.MixProject do
  use Mix.Project

  def project do
    [
      app: :resourceful,
      deps: deps(),
      description: "",
      elixir: "~> 1.10",
      name: "Resourceful",
      package: package(),
      start_permanent: Mix.env() == :prod,
      version: "0.1.0"
    ]
  end

  def application, do: [applications: []]

  defp deps do
    [
      {:ecto, "~> 3.4"},
      {:ecto_sql, "~> 3.4", only: [:test]},
      {:inflex, "~> 2.0.0", only: [:test]},
      {:postgrex, ">= 0.0.0", only: [:test]}
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Joshua Hansen"]
    }
  end
end
