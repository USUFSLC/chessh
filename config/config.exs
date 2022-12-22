import Config

config :chessh,
  ecto_repos: [Chessh.Repo],
  priv_dir: Path.join(Path.dirname(__DIR__), "priv/keys"),
  port: 42069,
  max_sessions: 255

import_config "#{config_env()}.exs"
