defmodule Chessh.Auth.KeyAuthenticator do
  alias Chessh.{Key, Repo, Player}
  import Ecto.Query

  def authenticate(player = %Player{}, public_key) do
    !!Repo.one(
      from(k in Key,
        where: k.key == ^Key.encode_key(public_key),
        where: k.player_id == ^player.id
      )
    )
  end

  def authenticate(username, public_key) do
    !!Repo.one(
      from(k in Key,
        join: p in assoc(k, :player),
        where: k.key == ^Key.encode_key(public_key),
        where: p.username == ^String.Chars.to_string(username)
      )
    )
  end

  def authenticate(username, public_key, _opts), do: authenticate(username, public_key)
end
