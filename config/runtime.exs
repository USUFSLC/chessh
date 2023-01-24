import Config

config :chessh,
  port: String.to_integer(System.get_env("SSH_PORT", "42069"))

config :chessh, Web,
  github_client_id: System.get_env("GITHUB_CLIENT_ID"),
  github_client_secret: System.get_env("GITHUB_CLIENT_SECRET"),
  github_user_agent: System.get_env("GITHUB_USER_AGENT"),
  client_redirect_after_successful_sign_in:
    System.get_env("CLIENT_REDIRECT_AFTER_OAUTH", "http://localhost:3000")

config :joken,
  default_signer: System.get_env("JWT_SECRET")

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

  config :hammer,
    backend: [
      in_memory:
        {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10]},
      redis:
        {Hammer.Backend.Redis,
         [
           expiry_ms: 60_000 * 60 * 2,
           redix_config: [
             host: System.get_env("REDIS_HOST", "redis"),
             port: String.to_integer(System.get_env("REDIS_PORT", "6379"))
           ]
         ]}
    ]
end
