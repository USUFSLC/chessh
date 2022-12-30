defmodule Chessh.Auth.PasswordAuthenticator do
  alias Chessh.{Player, Repo}

  def authenticate(player = %Player{}, password) do
    Player.valid_password?(player, password)
  end

  def authenticate(username, password) do
    case Repo.get_by(Player, username: username) do
      player -> authenticate(player, password)
    end
  end
end
