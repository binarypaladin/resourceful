defmodule Resourceful.MixProject do
  use Mix.Project

  def project do
    [
      app: :resourceful,
      deps: deps(),
      description: "",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "Resourceful",
      package: package(),
      start_permanent: Mix.env() == :prod,
      version: "0.1.0"
    ]
  end

  def application, do: [applications: []]

  defp elixirc_paths(:test), do: ["test/support"] ++ elixirc_paths(:prod)

  defp elixirc_paths(_), do: ["lib"]

  defp deps, do: []

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Joshua Hansen"]
    }
  end
end
