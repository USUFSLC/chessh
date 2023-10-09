import Config

config :chessh,
  ecto_repos: [Chessh.Repo],
  key_dir: Path.join(Path.dirname(__DIR__), "priv/keys"),
  max_sessions: 255,
  ascii_chars_json_file: Path.join(Path.dirname(__DIR__), "priv/ascii_chars.json")

config :chessh, RateLimits,
  player_bots: 2,
  jail_timeout_ms: 5 * 60 * 1000,
  jail_attempt_threshold: 15,
  max_concurrent_user_sessions: 5,
  player_session_message_burst_ms: 500,
  player_session_message_burst_rate: 10,
  player_public_keys: 15,
  create_game_ms: 60 * 1000,
  create_game_rate: 3,
  discord_notification_rate: 30,
  discord_notification_rate_ms: 1000,
  bot_redrive_rate: 1,
  bot_redrive_rate_ms: 30_000

config :chessh, Web,
  discord_oauth_login_url: "https://discord.com/api/oauth2/token",
  discord_user_api_url: "https://discord.com/api/users/@me",
  discord_scope: "identify"

config :chessh, DiscordNotifications,
  game_move_notif_delay_ms: 0,
  game_created_notif_delay_ms: 15_000,
  game_player_joined_notif_delay_ms: 0,
  reschedule_delay: 3 * 1000

config :joken, default_signer: "secret"

import_config "#{config_env()}.exs"
