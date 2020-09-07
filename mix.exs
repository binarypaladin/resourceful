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

  defp deps, do: []

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Joshua Hansen"]
    }
  end
end
