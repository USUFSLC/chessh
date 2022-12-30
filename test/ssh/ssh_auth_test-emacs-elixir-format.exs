defmodule Chessh.SSH.AuthTest do
  use ExUnit.Case
  alias Chessh.{Player, Repo, Key}

  @localhost '127.0.0.1'
  @key_name "The Gamer Machine"
  @valid_user %{username: "logan", password: "password"}
  @client_test_keys_dir Path.join(Application.compile_env!(:chessh, :key_dir), "client_keys")
  @client_pub_key 'id_ed25519.pub'

  setup_all do
    case Ecto.Adapters.SQL.Sandbox.checkout(Repo) do
      :ok -> nil
      {:already, :owner} -> nil
    end

    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    {:ok, player} = Repo.insert(Player.registration_changeset(%Player{}, @valid_user))

    {:ok, key_text} = File.read(Path.join(@client_test_keys_dir, @client_pub_key))

    {:ok, _key} =
      Repo.insert(
        Key.changeset(%Key{}, %{key: key_text, name: @key_name})
        |> Ecto.Changeset.put_assoc(:player, player)
      )

    :ok
  end

  test "Password attempts are rate limited" do
    assert :disconnect ==
             Enum.reduce(
               1..Application.fetch_env!(:chessh, RateLimits, :jail_threshold),
               fn _, _ ->
                 Chessh.SSH.Daemon.pwd_authenticate(
                        @valid_user.username,
                        'wrong_password',
                        @localhost
                      ) do
               end
             )
  end

  test "INTEGRATION - Can ssh into daemon with password or public key" do
    {:ok, sup} = Task.Supervisor.start_link()
    test_pid = self()

    Task.Supervisor.start_child(sup, fn ->
      {:ok, _pid} =
        :ssh.connect(@localhost, Application.fetch_env!(:chessh, :port),
          user: String.to_charlist(@valid_user.username),
          password: String.to_charlist(@valid_user.password),
          auth_methods: 'password',
          silently_accept_hosts: true
        )

      send(test_pid, :connected_via_password)
    end)

    Task.Supervisor.start_child(sup, fn ->
      {:ok, _pid} =
        :ssh.connect(@localhost, Application.fetch_env!(:chessh, :port),
          user: String.to_charlist(@valid_user.username),
          auth_methods: 'publickey',
          silently_accept_hosts: true,
          user_dir: String.to_charlist(@client_test_keys_dir)
        )

      send(test_pid, :connected_via_public_key)
    end)

    assert_receive(:connected_via_password, 500)
    assert_receive(:connected_via_public_key, 500)
  end

  test "INTEGRATION - User cannot have more than specified concurrent sessions" do
    :ok
  end
end
