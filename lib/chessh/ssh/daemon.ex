defmodule Chessh.SSH.Daemon do
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

  def pwd_authenticate(username, password, _address, attempts) do
    if Chessh.Auth.PasswordAuthenticator.authenticate(username, password) do
      true
    else
      newAttempts =
        case attempts do
          :undefined -> 0
          _ -> attempts
        end

      if Application.fetch_env!(:chessh, :max_password_attempts) <= newAttempts do
        :disconnect
      else
        {false, newAttempts + 1}
      end
    end
  end

  def handle_cast(:start, state) do
    port = Application.fetch_env!(:chessh, :port)
    key_dir = String.to_charlist(Application.fetch_env!(:chessh, :key_dir))
    max_sessions = Application.fetch_env!(:chessh, :max_sessions)

    case :ssh.daemon(
           port,
           system_dir: key_dir,
           pwdfun: &pwd_authenticate/4,
           key_cb: Chessh.SSH.ServerKey,
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
