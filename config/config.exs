import Config

config :chessh,
  ecto_repos: [Chessh.Repo],
  key_dir: Path.join(Path.dirname(__DIR__), "priv/keys"),
  port: 42_069,
  max_sessions: 255

config :chessh, RateLimits,
  jail_timeout_ms: 5 * 60 * 1000,
  jail_attempt_threshold: 15,
  max_concurrent_user_sessions: 5

config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10]}

import_config "#{config_env()}.exs"
