defmodule Chessh.Auth.UserRegistrationTest do
  use Chessh.RepoCase
  use ExUnit.Case
  alias Chessh.{Player, Repo}

  @valid_user %{username: "logan", password: "password", github_id: 4}
  @invalid_username %{username: "a", password: "password", github_id: 7}
  @invalid_password %{username: "aasdf", password: "pass", github_id: 6}
  @repeated_username %{username: "LoGan", password: "password", github_id: 5}

  test "Password must be at least 8 characters and username must be at least 2" do
    refute Player.registration_changeset(%Player{}, @invalid_password).valid?
    refute Player.registration_changeset(%Player{}, @invalid_username).valid?
  end

  test "Password changeset must match" do
    refute Player.password_changeset(
             %Player{},
             Map.put(@valid_user, :password_confirmation,
               password_confirmation: @valid_user.password <> "a"
             )
           ).valid?

    valid_user_changed_password = Map.put(@valid_user, :password, "a_new_password")

    assert Player.password_changeset(
             %Player{},
             Map.put(
               valid_user_changed_password,
               :password_confirmation,
               valid_user_changed_password.password
             )
           ).valid?
  end

  test "Password is hashed" do
    changeset = Player.registration_changeset(%Player{}, @valid_user)
    assert_raise KeyError, fn -> changeset.changes.password end
    assert changeset.changes.hashed_password
    refute changeset.changes.hashed_password == @valid_user.password
  end

  test "Username is uniquely case insensitive" do
    assert Repo.insert(Player.registration_changeset(%Player{}, @valid_user))

    assert {:error,
            %{errors: [{:username, {_, [{:constraint, :unique}, {:constraint_name, _}]}}]}} =
             Repo.insert(Player.registration_changeset(%Player{}, @repeated_username))
  end
end
