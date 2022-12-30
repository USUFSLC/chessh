defmodule Chessh.SSH.Daemon do
  alias Chessh.Auth.PasswordAuthenticator
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{
      pid: nil
    })
  end

  def init(state) do
    GenServer.cast(self(), :start)
    {:ok, state}
  end

  def pwd_authenticate(username, password) do
    # TODO - check concurrent sessions
    PasswordAuthenticator.authenticate(
      String.Chars.to_string(username),
      String.Chars.to_string(password)
    )
  end

  def pwd_authenticate(username, password, inet) do
    [jail_timeout_ms, jail_threshold] =
      Application.get_env(:chessh, RateLimits)
      |> Keyword.take([:jail_timeout_ms, :jail_threshold])
      |> Keyword.values()

    {ip, _port} = inet
    rateId = "failed_password_attempts:#{Enum.join(Tuple.to_list(ip), ".")}"

    case Hammer.check_rate(rateId, jail_timeout_ms, jail_threshold) do
      {:allow, _count} ->
        pwd_authenticate(username, password) ||
          (fn ->
             Hammer.check_rate_inc(rateId, jail_timeout_ms, jail_threshold, 1)
             false
           end).()

      {:deny, _limit} ->
        :disconnect
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
           system_dir: key_dir,
           pwdfun: &pwd_authenticate/4,
           key_cb: Chessh.SSH.ServerKey,
           #          disconnectfun: 
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
end
