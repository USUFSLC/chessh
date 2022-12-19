defmodule Chessh.Auth.PasswordAuthenticator do
  use Sshd.PasswordAuthenticator

  def authenticate(_username, _password) do
    true
  end
end
