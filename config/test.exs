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

config :hammer,
  backend: [
    in_memory:
      {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10]},
    redis: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10]}
  ]

config :chessh,
  port: 34_355,
  key_dir: Path.join(Path.dirname(__DIR__), "priv/test_keys")
