import Config

config :chessh, Chessh.Repo,
  database: "chessh-test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :esshd,
  priv_dir: Path.join(Path.dirname(__DIR__), "priv/test_keys")
