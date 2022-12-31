defmodule Chessh.SSH.Tui do
  require Logger

  @behaviour :ssh_server_channel

  def init(opts) do
    Logger.debug("#{inspect(opts)}")

    {:ok,
     %{
       channel: nil,
       cm: nil,
       pty: %{term: nil, width: nil, height: nil, pixwidth: nil, pixheight: nil, modes: nil},
       shell: false,
       client_pid: nil
     }}
  end

  @spec handle_msg(any, any) ::
          :ok
          | {:ok, atom | %{:channel => any, :cm => any, optional(any) => any}}
          | {:stop, any, %{:channel => any, :client_pid => any, optional(any) => any}}
  def handle_msg({:ssh_channel_up, channel_id, connection_handler}, state) do
    Logger.debug(
      "SSH CHANNEL UP #{inspect(connection_handler)} #{inspect(:ssh.connection_info(connection_handler))}"
    )

    {:ok, %{state | channel: channel_id, cm: connection_handler}}
  end

  def handle_msg({:EXIT, client_pid, _reason}, %{client_pid: client_pid} = state) do
    {:stop, state.channel, state}
  end

  ### commands we expect from the client ###
  def handle_msg({:send_data, data}, state) do
    Logger.debug("DATA SENT #{inspect(data)}")
    :ssh_connection.send(state.cm, state.channel, data)
    {:ok, state}
  end

  ### catch all for what we haven't seen ###
  def handle_msg(msg, term) do
    Logger.debug("Unknown msg #{inspect(msg)}, #{inspect(term)}")
  end

  def handle_ssh_msg(
        {:ssh_cm, _connection_handler, {:data, _channel_id, _type, data}},
        state
      ) do
    Logger.debug("DATA #{inspect(data)}")
    send(state.client_pid, {:data, data})
    {:ok, state}
  end

  def handle_ssh_msg(
        {:ssh_cm, connection_handler,
         {:pty, channel_id, want_reply?, {term, width, height, pixwidth, pixheight, modes} = _pty}},
        state
      ) do
    :ssh_connection.reply_request(connection_handler, want_reply?, :success, channel_id)

    {:ok,
     %{
       state
       | pty: %{
           term: term,
           width: width,
           height: height,
           pixwidth: pixwidth,
           pixheight: pixheight,
           modes: modes
         }
     }}
  end

  def handle_ssh_msg(
        {:ssh_cm, connection_handler, {:env, channel_id, want_reply?, var, value}},
        state
      ) do
    :ssh_connection.reply_request(connection_handler, want_reply?, :failure, channel_id)
    Logger.debug("ENV #{var} = #{value}")
    {:ok, state}
  end

  def handle_ssh_msg(
        {:ssh_cm, _connection_handler,
         {:window_change, _channel_id, width, height, pixwidth, pixheight}},
        state
      ) do
    Logger.debug("WINDOW CHANGE")
    #    SSHnakes.Client.resize(state.client_pid, width, height)

    {:ok,
     %{
       state
       | pty: %{
           state.pty
           | width: width,
             height: height,
             pixwidth: pixwidth,
             pixheight: pixheight
         }
     }}
  end

  def handle_ssh_msg(
        {:ssh_cm, connection_handler, {:shell, channel_id, want_reply?}},
        state
      ) do
    :ssh_connection.reply_request(connection_handler, want_reply?, :success, channel_id)

    {:ok, client_pid} =
      GenServer.start_link(Chessh.SSH.Client, [self(), state.pty.width, state.pty.height])

    {:ok, %{state | client_pid: client_pid, shell: true}}
  end

  def handle_ssh_msg(
        {:ssh_cm, connection_handler, {:exec, channel_id, want_reply?, cmd}},
        state
      ) do
    :ssh_connection.reply_request(connection_handler, want_reply?, :success, channel_id)
    Logger.debug("EXEC #{cmd}")
    {:ok, state}
  end

  def handle_ssh_msg(
        {:ssh_cm, _connection_handler, {:eof, _channel_id}},
        state
      ) do
    Logger.debug("EOF")
    {:ok, state}
  end

  def handle_ssh_msg(
        {:ssh_cm, _connection_handler, {:signal, _channel_id, signal}},
        state
      ) do
    Logger.debug("SIGNAL #{signal}")
    {:ok, state}
  end

  def handle_ssh_msg(
        {:ssh_cm, _connection_handler, {:exit_signal, channel_id, signal, err, lang}},
        state
      ) do
    Logger.debug("EXIT SIGNAL #{signal} #{err} #{lang}")
    {:stop, channel_id, state}
  end

  def handle_ssh_msg(
        {:ssh_cm, _connection_handler, {:exit_STATUS, channel_id, status}},
        state
      ) do
    Logger.debug("EXIT STATUS #{status}")
    {:stop, channel_id, state}
  end

  def terminate(_reason, _state) do
    :ok
  end
end
