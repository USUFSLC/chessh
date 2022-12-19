import Config

config :chessh, Chessh.Repo,
  database: "chessh",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :chessh, ecto_repos: [Chessh.Repo]

config :esshd,
  enabled: true,
  priv_dir: Path.join(Path.dirname(__DIR__), "priv/keys"),
  handler: {Chessh.Shell, :on_shell, 4},
  port: 42069,
  password_authenticator: Chessh.Auth.PasswordAuthenticator,
  public_key_authenticator: Chessh.Auth.KeyAuthenticator

import_config "#{config_env()}.exs"
