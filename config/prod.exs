import Config

config :logger,
  level: :warning,
  truncate: 4096

config :chessh, RateLimits,
  jail_timeout_ms: 5 * 60 * 1000,
  jail_attempt_threshold: 15,
  max_concurrent_user_sessions: 5,
  player_session_message_burst_ms: 750,
  player_session_message_burst_rate: 8

config :libcluster,
  topologies: [
    chessh: [
      strategy: Elixir.Cluster.Strategy.Gossip,
      config: [
        port: 45892,
        if_addr: "0.0.0.0",
        multicast_if: "192.168.1.1",
        multicast_addr: "233.252.1.32",
        multicast_ttl: 1,
        secret: "chessh"
      ]
    ]
  ]
