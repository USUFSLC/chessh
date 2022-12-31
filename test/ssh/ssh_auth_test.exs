defmodule Chessh.SSH.AuthTest do
  use ExUnit.Case, async: false
  alias(Chessh.{Player, Repo, Key, PlayerSession})

  @localhost '127.0.0.1'
  @localhost_inet {{127, 0, 0, 1}, 1}
  @key_name "The Gamer Machine"
  @valid_user %{username: "logan", password: "password"}
  @client_test_keys_dir Path.join(Application.compile_env!(:chessh, :key_dir), "client_keys")
  @client_pub_key 'id_ed25519.pub'

  setup_all do
    Ecto.Adapters.SQL.Sandbox.checkout(Repo)
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

  def cleanup() do
    Process.sleep(1_000)
    PlayerSession.delete_all_on_node(System.fetch_env!("NODE_ID"))

    # Wait for (what I believe to be the) DB Connection queue to clear?
    Process.sleep(1_000)
  end

  def send_ssh_connection_to_pid(parent, auth_method) do
    send(
      parent,
      {:attempted,
       :ssh.connect(@localhost, Application.fetch_env!(:chessh, :port),
         user: String.to_charlist(@valid_user.username),
         password: String.to_charlist(@valid_user.password),
         auth_methods: auth_method,
         silently_accept_hosts: true,
         user_dir: String.to_charlist(@client_test_keys_dir)
       )}
    )
  end

  test "Password attempts are rate limited" do
    jail_attempt_threshold =
      Application.get_env(:chessh, RateLimits)
      |> Keyword.get(:jail_attempt_threshold)

    assert :disconnect ==
             Enum.reduce(
               0..(jail_attempt_threshold + 1),
               fn _, _ ->
                 Chessh.SSH.Daemon.pwd_authenticate(
                   @valid_user.username,
                   "wrong_password",
                   @localhost_inet
                 )
               end
             )
  end

  test "INTEGRATION - Can ssh into daemon with password or public key" do
    {:ok, sup} = Task.Supervisor.start_link()
    test_pid = self()

    Task.Supervisor.start_child(sup, fn ->
      {:ok, conn} =
        :ssh.connect(@localhost, Application.fetch_env!(:chessh, :port),
          user: String.to_charlist(@valid_user.username),
          password: String.to_charlist(@valid_user.password),
          auth_methods: 'password',
          silently_accept_hosts: true
        )

      :ssh.close(conn)
      send(test_pid, :connected_via_password)
    end)

    Task.Supervisor.start_child(sup, fn ->
      {:ok, conn} =
        :ssh.connect(@localhost, Application.fetch_env!(:chessh, :port),
          user: String.to_charlist(@valid_user.username),
          auth_methods: 'publickey',
          silently_accept_hosts: true,
          user_dir: String.to_charlist(@client_test_keys_dir)
        )

      :ssh.close(conn)
      send(test_pid, :connected_via_public_key)
    end)

    assert_receive(:connected_via_password, 2_000)
    assert_receive(:connected_via_public_key, 2_000)

    cleanup()
  end

  test "INTEGRATION - Player cannot have more than specified concurrent sessions which are tracked by successful authentications and disconnections" do
    max_concurrent_user_sessions =
      Application.get_env(:chessh, RateLimits)
      |> Keyword.get(:max_concurrent_user_sessions)

    player = Repo.get_by(Player, username: @valid_user.username)

    {:ok, sup} = Task.Supervisor.start_link()
    test_pid = self()

    Enum.reduce(0..(max_concurrent_user_sessions + 1), fn i, _ ->
      Task.Supervisor.start_child(
        sup,
        fn ->
          send_ssh_connection_to_pid(
            test_pid,
            if(rem(i, 2) == 0, do: 'publickey', else: 'password')
          )
        end
      )
    end)

    conns =
      Enum.map(1..max_concurrent_user_sessions, fn _ ->
        assert_receive({:attempted, {:ok, conn}}, 2_000)
        conn
      end)

    assert_receive(
      {:attempted, {:error, 'Unable to connect using the available authentication methods'}},
      2000
    )

    # Give it time to send back the disconnection payload after session was opened
    # but over threshold
    :timer.sleep(100)
    assert PlayerSession.concurrent_sessions(player) == max_concurrent_user_sessions

    Enum.map(conns, fn conn -> :ssh.close(conn) end)
    :timer.sleep(100)
    assert PlayerSession.concurrent_sessions(player) == 0

    cleanup()
  end
end
