import Config

config :chessh, Chessh.Repo,
  database: "chessh",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :chessh, ecto_repos: [Chessh.Repo]
