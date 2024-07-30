defmodule ExoSQL.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exosql,
      version: "0.2.88",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      compilers: [:yecc, :leex] ++ Mix.compilers(),
      deps: deps(),
      source_url: "https://github.com/serverboards/exosql/",
      homepage_url: "https://serverboards.io",
      description: description(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      package: [
        name: "exosql",
        licenses: ["Apache 2.0"],
        maintainers: ["David Moreno <dmoreno@serverboards.io>"],
        links: %{
          "Serverboards" => "https://serverboards.io",
          "GitHub" => "https://github.com/serverboards/exosql/"
        }
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :httpoison]
    ]
  end

  defp description do
    "Universal SQL engine for Elixir.

This library implements the SQL logic to perform queries on user provided
databases using a simple interface based on Foreign Data Wrappers from
PostgreSQL.
"
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.27"},
      {:timex, "~> 3.0"},
      {:csv, "~> 3.2.1"},
      {:httpoison, "~> 2.2.0"},
      {:poison, "~> 6.0"},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end
end
