defmodule InfluxEx.MixProject do
  use Mix.Project

  @version "0.1.1"

  def project do
    [
      app: :influx_ex,
      version: @version,
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: [docs: :docs, "hex.publish": :docs],
      deps: deps(),
      docs: docs(),
      package: package(),
      description: description(),
      dialyzer: dialyzer()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :mojito]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.1", only: [:test, :dev], runtime: false},
      {:ex_doc, "~> 0.28", only: :docs, runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:mojito, "~> 0.7.11", optional: true},
      {:jason, "~> 1.3", optional: true},
      {:nimble_csv, "~> 1.2", optional: true}
    ]
  end

  defp dialyzer() do
    [
      flags: [:unmatched_returns, :error_handling, :race_conditions],
      plt_add_apps: [:mojito, :jason, :nimble_csv],
      ignore_warnings: "dialyzer.ignore-warnings"
    ]
  end

  defp docs() do
    [
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      source_ref: "v#{@version}",
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      groups_for_modules: [
        Core: [
          InfluxEx,
          InfluxEx.Buckets,
          InfluxEx.Client,
          InfluxEx.Flux,
          InfluxEx.Orgs,
          InfluxEx.Point,
          InfluxEx.TableRow
        ],
        HTTP: [
          InfluxEx.HTTP,
          InfluxEx.HTTP.Request,
          InfluxEx.HTTP.Response,
          InfluxEx.HTTP.Mojito
        ],
        "API Resources": [
          InfluxEx.Bucket,
          InfluxEx.Me,
          InfluxEx.Org
        ],
        JSON: [
          InfluxEx.JSONLibrary
        ],
        CSV: [
          InfluxEx.CSVLibrary,
          InfluxEx.CSV
        ],
        Helpers: [
          InfluxEx.GenData
        ]
      ]
    ]
  end

  defp description() do
    "InfluxDB v2.x API library"
  end

  defp package() do
    [licenses: ["Apache-2.0"], links: %{"GitHub" => "https://github.com/mattludwigs/influx_ex"}]
  end
end
