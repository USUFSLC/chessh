import Config

config :logger,
  level: :info,
  truncate: 4096

config :chessh, RateLimits,
  jail_timeout_ms: 5 * 60 * 1000,
  jail_attempt_threshold: 15,
  max_concurrent_user_sessions: 5,
  player_session_message_burst_ms: 400,
  player_session_message_burst_rate: 11
