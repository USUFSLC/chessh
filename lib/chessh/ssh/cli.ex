defmodule Chessh.SSH.Cli do
  @behaviour :ssh_server_channel

  def init() do
    {:ok, %{}}
  end

  def handle_msg(message, state) do
    {:ok, state}
  end

  def handle_ssh_msg(message, state) do
    {:ok, state}
  end

  def handle_ssh_msg(
        {:ssh_cm, _connection_handler, {:exit_signal, channel_id, signal, err, lang}},
        state
      ) do
    {:stop, channel_id, state}
  end

  def terminate(reason, state) do
    :ok
  end
end
