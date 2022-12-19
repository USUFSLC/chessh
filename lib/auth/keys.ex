defmodule Chessh.Auth.KeyAuthenticator do
  use Sshd.PublicKeyAuthenticator
  require Logger

  def authenticate(_, _, _) do
    false
  end
end
