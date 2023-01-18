import Config

config :chessh, Web,
  github_client_id: System.get_env("GITHUB_CLIENT_ID"),
  github_client_secret: System.get_env("GITHUB_CLIENT_SECRET"),
  github_user_agent: System.get_env("GITHUB_USER_AGENT")

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []

  config :chessh, Chessh.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6
end
