import Config

config :esshd,
  enabled: true,
  priv_dir: Path.join(Path.dirname(__DIR__), "priv/keys"),
  handler: {Chessh.Shell, :on_shell, 4},
  port: 42069,
  public_key_authenticator: Chessh.Auth.KeyAuthenticator,
  password_authenticator: Chessh.Auth.PasswordAuthenticator

import_config "#{config_env()}.exs"
