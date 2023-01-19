defmodule Chessh.MixProject do
  use Mix.Project

  def project do
    [
      app: :chessh,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Chessh.Application, []},
      extra_applications: [:logger, :crypto, :syn, :ssh, :plug_cowboy, :inets, :ssl]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:binbo, "~> 4.0.2"},
      {:ecto, "~> 3.9"},
      {:ecto_sql, "~> 3.9"},
      {:postgrex, "~> 0.16.5"},
      {:bcrypt_elixir, "~> 3.0"},
      {:hammer, "~> 6.1"},
      {:syn, "~> 3.3"},
      {:jason, "~> 1.3"},
      {:plug_cowboy, "~> 2.2"},
      {:joken, "~> 2.5"}
    ]
  end

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate", "test --seed 0"]
    ]
  end
end
