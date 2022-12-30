defmodule Chessh.Auth.PasswordAuthenticatorTest do
  use ExUnit.Case
  alias Chessh.{Player, Repo}

  @valid_user %{username: "logan", password: "password"}

  setup_all do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Chessh.Repo)

    {:ok, _user} = Repo.insert(Player.registration_changeset(%Player{}, @valid_user))

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
end
