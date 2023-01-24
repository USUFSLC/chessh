import Config

config :chessh, Chessh.Repo,
  database: "chessh",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :hammer,
  backend: [
    in_memory:
      {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10]},
    redis: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10]}
  ]
