defmodule Chessh.Auth.PasswordAuthenticator do
  alias Chessh.{Player, Repo}

  def authenticate(username, password) do
    case Repo.get_by(Player, username: username) do
      x -> Player.valid_password?(x, password)
    end
  end
end
