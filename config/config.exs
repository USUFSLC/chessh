import Config

# This will be redis when scaled across multiple nodes
config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10]}

config :chessh,
  ecto_repos: [Chessh.Repo],
  key_dir: Path.join(Path.dirname(__DIR__), "priv/keys"),
  port: 42_069,
  max_sessions: 255,
  ascii_chars_json_file: Path.join(Path.dirname(__DIR__), "priv/ascii_chars.json")

config :chessh, RateLimits,
  jail_timeout_ms: 5 * 60 * 1000,
  jail_attempt_threshold: 15,
  max_concurrent_user_sessions: 5,
  player_session_message_burst_ms: 500,
  player_session_message_burst_rate: 8

config :chessh, Web,
  port: 8080,
  github_oauth_login_url: "https://github.com/login/oauth/access_token",
  github_user_api_url: "https://api.github.com/user"

config :joken, default_signer: "secret"

import_config "#{config_env()}.exs"
