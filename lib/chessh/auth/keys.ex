defmodule Chessh.Auth.KeyAuthenticator do
  alias Chessh.Key
  alias Chessh.Repo
  use Sshd.PublicKeyAuthenticator
  require Logger
  import Ecto.Query

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
