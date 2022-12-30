import Config

config :chessh, RateLimits,
  jail_timeout_ms: 10_000,
  jail_attempt_threshold: 3

config :chessh, Chessh.Repo,
  database: "chesshtest",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :chessh,
  key_dir: Path.join(Path.dirname(__DIR__), "priv/test_keys")
