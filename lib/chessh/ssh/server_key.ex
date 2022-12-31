defmodule Chessh.SSH.ServerKey do
  alias Chessh.PlayerSession
  alias Chessh.Auth.KeyAuthenticator

  @behaviour :ssh_server_key_api

  def is_auth_key(key, username, _daemon_options) do
    PlayerSession.update_sessions_and_player_satisfies(
      username,
      fn player -> KeyAuthenticator.authenticate(player, key) end
    )
  end

  def host_key(algorithm, daemon_options) do
    :ssh_file.host_key(algorithm, daemon_options)
  end
end
