defmodule Chessh.Auth.KeyAuthenticator do
  use Sshd.PublicKeyAuthenticator
  require Logger

  def authenticate(username, public_key, _opts) do
    Logger.debug("#{inspect(username)}")
    Logger.debug("#{inspect(public_key)}")
    true
  end
end
