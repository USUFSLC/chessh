defmodule Chessh.Auth.PasswordAuthenticator do
  alias Chessh.Player
  alias Chessh.Repo
  use Sshd.PasswordAuthenticator

  def authenticate(username, password) do
    case Repo.get_by(Player, username: String.Chars.to_string(username)) do
      x -> Player.valid_password?(x, String.Chars.to_string(password))
    end
  end
end
