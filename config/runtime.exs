import Config

config :chessh,
  ssh_port: String.to_integer(System.get_env("SSH_PORT", "34355"))

config :chessh, Web,
  discord_client_id: System.get_env("DISCORD_CLIENT_ID"),
  discord_client_secret: System.get_env("DISCORD_CLIENT_SECRET"),
  discord_user_agent: System.get_env("DISCORD_USER_AGENT"),
  client_redirect_after_successful_sign_in:
    System.get_env("CLIENT_REDIRECT_AFTER_OAUTH", "http://127.0.0.1:3000/auth-successful"),
  server_redirect_uri:
    System.get_env("SERVER_REDIRECT_URI", "http://127.0.0.1:3000/api/oauth/redirect"),
  port: String.to_integer(System.get_env("WEB_PORT", "8080"))

config :libcluster,
  topologies: [
    chessh: [
      strategy: Cluster.Strategy.Epmd,
      config: [
        hosts:
          String.split(System.get_env("CLUSTER_NODES", ""), ",")
          |> Enum.filter(fn x -> String.length(x) > 0 end)
          |> Enum.map(&String.to_atom/1)
      ],
      child_spec: [restart: :transient]
    ]
  ]

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
