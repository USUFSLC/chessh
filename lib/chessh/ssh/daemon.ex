defmodule Chessh.SSH.Daemon do
  alias Chessh.{Repo, PlayerSession, Utils}
  alias Chessh.Auth.PasswordAuthenticator
  use GenServer
  import Ecto.Query

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{
      pid: nil
    })
  end

  def init(state) do
    GenServer.cast(self(), :start)
    {:ok, state}
  end

  def pwd_authenticate(username, password, {ip, _port}) do
    [jail_timeout_ms, jail_attempt_threshold] =
      Application.get_env(:chessh, RateLimits)
      |> Keyword.take([:jail_timeout_ms, :jail_attempt_threshold])
      |> Keyword.values()

    rateId = "failed_password_attempts:#{Enum.join(Tuple.to_list(ip), ".")}"

    case PasswordAuthenticator.authenticate(
           String.Chars.to_string(username),
           String.Chars.to_string(password)
         ) do
      false ->
        case Hammer.check_rate_inc(rateId, jail_timeout_ms, jail_attempt_threshold, 1) do
          {:allow, _count} ->
            false

          {:deny, _limit} ->
            :disconnect
        end

      x ->
        if PlayerSession.player_within_concurrent_sessions_and_satisfies(username, fn _player ->
             x
           end),
           do: true,
           else: :disconnect
    end
  end

  def pwd_authenticate(username, password, inet, _address),
    do: pwd_authenticate(username, password, inet)

  def handle_cast(:start, state) do
    port = Application.fetch_env!(:chessh, :port)
    key_dir = String.to_charlist(Application.fetch_env!(:chessh, :key_dir))
    max_sessions = Application.fetch_env!(:chessh, :max_sessions)

    case :ssh.daemon(
           port,
           # shell: fn _username, _peer -> Process.sleep(5000) end,
           system_dir: key_dir,
           pwdfun: &pwd_authenticate/4,
           key_cb: Chessh.SSH.ServerKey,
           ssh_cli: {Chessh.SSH.Tui, []},
           #           connectfun: &on_connect/3,
           disconnectfun: &on_disconnect/1,
           id_string: :random,
           subsystems: [],
           parallel_login: true,
           max_sessions: max_sessions
         ) do
      {:ok, pid} ->
        Process.link(pid)
        {:noreply, %{state | pid: pid}, :hibernate}

      {:error, err} ->
        raise inspect(err)
    end

    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp on_disconnect(_reason) do
    Logger.debug("#{inspect(self())} disconnected")

    Repo.delete_all(
      from(p in PlayerSession,
        where: p.node_id == ^System.fetch_env!("NODE_ID"),
        where: p.process == ^Utils.pid_to_str(self())
      )
    )
  end
end
