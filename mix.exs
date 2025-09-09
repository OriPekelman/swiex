defmodule Swiex.MixProject do
  use Mix.Project

  @version "0.3.0"
  @source_url "https://github.com/oripekelman/swiex"

  def project do
    [
      app: :swiex,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Inline Prolog code in Elixir using SWI-Prolog MQI",
      package: package(),
      test_paths: test_paths(Mix.env()),
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: docs(),
      source_url: @source_url,
      homepage_url: @source_url,
      maintainers: ["Ori Pekelman"]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Swiex.Application, []}
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:socket, "~> 0.3"},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:file_system, "~> 1.0"},
      {:erlog, github: "rvirding/erlog", branch: "develop", optional: true}
    ]
  end

  defp package do
    [
      name: "swiex",
      licenses: ["BSD-2-Clause"],
      links: %{
        "GitHub" => @source_url,
        "SWI-Prolog MQI Documentation" => "https://www.swi-prolog.org/pldoc/man?section=mqi"
      },
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md CODE_OF_CONDUCT.md config),
      maintainers: ["Ori Pekelman"]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end

  defp test_paths(:test), do: ["test"]
  defp test_paths(_), do: []

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
