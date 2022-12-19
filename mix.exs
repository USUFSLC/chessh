defmodule Chessh.MixProject do
  use Mix.Project

  def project do
    [
      app: :chessh,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:esshd, :logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:chess, "~> 0.4.1"},
      {:esshd, "~> 0.2.1"},
      {:ecto, "~> 3.9"},
      {:ecto_sql, "~> 3.9"},
      {:postgrex, "~> 0.16.5"},
      {:bcrypt_elixir, "~> 3.0"}
    ]
  end
end
