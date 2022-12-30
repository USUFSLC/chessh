defmodule Chessh.SSH.Cli do
  @behaviour :ssh_server_channel

  def init(_args) do
    {:ok, %{}}
  end

  def handle_msg(_message, state) do
    {:ok, state}
  end

  def handle_ssh_msg(
        {:ssh_cm, _connection_handler, {:exit_signal, channel_id, _signal, _err, _lang}},
        state
      ) do
    {:stop, channel_id, state}
  end

  def handle_ssh_msg(_message, state) do
    {:ok, state}
  end

  def terminate(_reason, _state) do
    :ok
  end
end
