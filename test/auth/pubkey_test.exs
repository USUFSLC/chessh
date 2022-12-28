defmodule Chessh.Auth.PublicKeyAuthenticatorTest do
  use ExUnit.Case
  alias Chessh.{Key, Repo, Player}

  @valid_user %{username: "logan", password: "password"}
  @valid_key %{
    name: "The Gamer Machine",
    key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ/2LOJGGEd/dhFgRxJ5MMv0jJw4s4pA8qmMbZyulN44"
  }

  setup_all do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Chessh.Repo)

    {:ok, player} = Repo.insert(Player.registration_changeset(%Player{}, @valid_user))

    {:ok, _key} =
      Repo.insert(
        Key.changeset(%Key{}, @valid_key)
        |> Ecto.Changeset.put_assoc(:player, player)
      )

    :ok
  end

  test "User can sign in with their ssh key from raw string" do
    assert Chessh.Auth.KeyAuthenticator.authenticate(@valid_user.username, @valid_key.key)
  end

  test "User can sign in with erlang decoded ssh key" do
    [key] = :ssh_file.decode(@valid_key.key, :openssh_key)
    assert Chessh.Auth.KeyAuthenticator.authenticate(@valid_user.username, key)
  end
end
