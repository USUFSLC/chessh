defmodule Chessh.Auth.PasswordAuthenticatorTest do
  use ExUnit.Case
  alias Chessh.{Player, Repo}

  @valid_user %{username: "lizzy#0003", password: "password", discord_id: "1"}

  setup_all do
    Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    {:ok, _player} = Repo.insert(Player.registration_changeset(%Player{}, @valid_user))

    :ok
  end

  test "Password can authenticate a hashed password" do
    assert Chessh.Auth.PasswordAuthenticator.authenticate(
             @valid_user.username,
             @valid_user.password
           )

    refute Chessh.Auth.PasswordAuthenticator.authenticate(
             @valid_user.username,
             "a_bad_password"
           )
  end

  test "Password can authenticate a user instance" do
    player = Repo.get_by(Player, username: "lizzy#0003")

    assert Chessh.Auth.PasswordAuthenticator.authenticate(
             player,
             @valid_user.password
           )
  end
end
