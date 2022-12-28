import Config

config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10]}

config :chessh, Chessh.Repo,
  database: "chessh-test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :chessh,
  key_dir: Path.join(Path.dirname(__DIR__), "priv/test_keys")
