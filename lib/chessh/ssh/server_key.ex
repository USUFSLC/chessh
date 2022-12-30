defmodule Chessh.SSH.ServerKey do
  alias Chessh.PlayerSession
  alias Chessh.Auth.KeyAuthenticator

  @behaviour :ssh_server_key_api

  def is_auth_key(key, username, _daemon_options) do
    PlayerSession.player_within_concurrent_sessions_and_satisfies(
      username,
      &KeyAuthenticator.authenticate(&1, key)
    )
  end

  def host_key(algorithm, daemon_options) do
    :ssh_file.host_key(algorithm, daemon_options)
  end
end
