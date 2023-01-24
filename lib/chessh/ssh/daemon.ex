defmodule Chessh.SSH.Daemon do
  alias Chessh.{Repo, PlayerSession, Utils}
  alias Chessh.Auth.PasswordAuthenticator
  alias Chessh.SSH.{ServerKey, Tui}

  use GenServer
  import Ecto.Query

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{
      pid: nil
    })
  end

  def init(state) do
    send(self(), :start)

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
        Logger.debug(
          "#{username} on bucket #{rateId} got their password wrong, or they don't exist! Point at them and laugh!!!!"
        )

        case Hammer.check_rate_inc(:redis, rateId, jail_timeout_ms, jail_attempt_threshold, 1) do
          {:allow, _count} ->
            Logger.debug("Bucket #{rateId} can continue to brute force though")
            false

          {:deny, _limit} ->
            Logger.debug("Bucket #{rateId} ran out of password attempts")
            :disconnect
        end

      authed_or_disconnect ->
        PlayerSession.update_sessions_and_player_satisfies(username, fn _player ->
          authed_or_disconnect
        end)

        authed_or_disconnect
    end
  end

  def pwd_authenticate(username, password, inet, _state),
    do: pwd_authenticate(username, password, inet)

  def handle_info(:start, state) do
    port = Application.fetch_env!(:chessh, :port)
    key_dir = String.to_charlist(Application.fetch_env!(:chessh, :key_dir))
    max_sessions = Application.fetch_env!(:chessh, :max_sessions)

    case :ssh.daemon(
           port,
           system_dir: key_dir,
           pwdfun: &pwd_authenticate/4,
           key_cb: ServerKey,
           ssh_cli: {Tui, [%Tui.State{}]},
           disconnectfun: &on_disconnect/1,
           id_string: :random,
           parallel_login: true,
           max_sessions: max_sessions,
           subsystems: []
         ) do
      {:ok, pid} ->
        Logger.info("SSH server started on port #{port}, on #{inspect(pid)}")

        Process.link(pid)
        {:noreply, %{state | pid: pid}, :hibernate}

      {:error, err} ->
        raise inspect(err)
    end

    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp on_disconnect(_reason) do
    Logger.info("#{inspect(self())} disconnected")

    Repo.delete_all(
      from(p in PlayerSession,
        where: p.node_id == ^System.fetch_env!("NODE_ID"),
        where: p.process == ^Utils.pid_to_str(self())
      )
    )
  end
end
