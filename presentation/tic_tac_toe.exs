defmodule Generator do
  def gen_reference() do
    min = String.to_integer("100000", 36)
    max = String.to_integer("ZZZZZZ", 36)

    max
    |> Kernel.-(min)
    |> :rand.uniform()
    |> Kernel.+(min)
    |> Integer.to_string(36)
  end
end

defmodule TicTacToe.GameManager do
  use GenServer

  defmodule State do
    defstruct games: %{},
              joinable_games: [],
              player_games: %{}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{
      pid: nil
    })
  end

  def init(_) do
    {:ok, %State{}}
  end

  defp create_board(), do: Enum.map(0..2, fn _ -> Enum.map(0..2, fn _ -> :empty end) end)

  defp create_game(game_id, player) do
    %{
      x: player,
      o: nil,
      board: create_board()
    }
  end

  def handle_info(
        {:join, %{client_pid: client_pid, username: username, player_id: connection_id} = player},
        %State{player_games: player_games, games: games, joinable_games: joinable_games} = state
      ) do
    if length(joinable_games) == 0 do
      game_id = Generator.gen_reference()
      send(client_pid, {:join_game, game_id})

      {:ok,
       %State{
         state
         | games: Map.put(games, game_id, create_game(game_id, player)),
           joinable_games: joinable_games ++ [game_id],
           player_games: Map.put(player_games, player_id, game_id)
       }}
    else
      [joining_game_id | rest] = joinable_games
      game = Map.get(games, joining_game_id)
      send(game.x.client_pid, :player_joined)
      send(client_pid, {:join_game, game_id})

      {:ok,
       %State{
         state
         | games: Map.put(games, game_id, %{game | o: player}),
           joinable_games: rest,
           connection_games: Map.put(player_games, connection_id, game_id)
       }}
    end
  end
end

defmodule TicTacToe.SSHDaemon do
  @port 4000
  @key_dir "/tmp/keys"
  use GenServer
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

  def handle_info(:start, state) do
    game_manager_pid =
      case GenServer.start_link(TicTacToe.GameManager, [%{}]) do
        {:ok, game_manager_pid} ->
          game_manager_pid

        _ ->
          nil
      end

    case :ssh.daemon(
           @port,
           system_dir: @key_dir,
           ssh_cli:
             {TicTacToe.SSHListener,
              [
                %TicTacToe.SSHListener.State{
                  game_manager_pid: game_manager_pid
                }
              ]},
           disconnectfun: &on_disconnect/1,
           id_string: :random,
           parallel_login: true,
           max_sessions: 1_000,
           subsystems: [],
           no_auth_needed: true
         ) do
      {:ok, pid} ->
        Logger.info("SSH server started on port #{port}, on #{inspect(pid)}")

        Process.link(pid)

        {:noreply, %{state | pid: pid, game_manager_pid: game_manager_pid}, :hibernate}

      {:error, err} ->
        raise inspect(err)
    end

    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp on_disconnect(_reason) do
    Logger.info("#{inspect(self())} disconnected")
  end
end

defmodule TicTacToe.SSHListener do
  alias Chessh.SSH.Client

  alias IO.ANSI

  require Logger

  @behaviour :ssh_server_channel
  @session_closed_message [
    ANSI.clear(),
    ["This session has been closed"]
  ]

  defmodule State do
    defstruct channel_id: nil,
              client_pid: nil,
              game_manager_pid: nil,
              connection_ref: nil
  end

  def init([%State{} = init_state]) do
    {:ok, init_state}
  end

  def handle_msg({:ssh_channel_up, channel_id, connection_ref}, %State{} = state) do
    Logger.debug("SSH channel up #{inspect(:ssh.connection_info(connection_ref))}")

    username =
      :ssh.connection_info(connection_ref)
      |> Keyword.fetch!(:user)
      |> String.Chars.to_string()

    {:ok,
     %State{
       state
       | channel_id: channel_id,
         connection_ref: connection_ref,
         player: %{
           id: Generator.gen_reference(),
           username: username
         }
     }}
  end

  def handle_msg(
        {:EXIT, client_pid, _reason},
        %State{client_pid: client_pid, channel_id: channel_id} = state
      ) do
    send(client_pid, :quit)
    {:stop, channel_id, state}
  end

  def handle_msg(
        {:send_data, data},
        %State{connection_ref: connection_ref, channel_id: channel_id} = state
      ) do
    :ssh_connection.send(connection_ref, channel_id, data)
    {:ok, state}
  end

  def handle_msg(
        :session_closed,
        %State{connection_ref: connection_ref, channel_id: channel_id} = state
      ) do
    :ssh_connection.send(connection_ref, channel_id, @session_closed_message)
    {:stop, channel_id, state}
  end

  def handle_msg(msg, term) do
    Logger.debug("Unknown msg #{inspect(msg)}, #{inspect(term)}")
  end

  def handle_ssh_msg(
        {:ssh_cm, _connection_handler, {:data, _channel_id, _type, data}},
        %State{client_pid: client_pid} = state
      ) do
    send(client_pid, {:data, data})
    {:ok, state}
  end

  def handle_ssh_msg(
        {:ssh_cm, connection_handler,
         {:pty, channel_id, want_reply?, {_term, _width, _height, _pixwidth, _pixheight, _opts}}},
        %State{} = state
      ) do
    Logger.debug("#{inspect(state.player_session)} has requested a PTY")
    :ssh_connection.reply_request(connection_handler, want_reply?, :success, channel_id)
    {:ok, state}
  end

  def handle_ssh_msg(
        {:ssh_cm, connection_handler, {:env, channel_id, want_reply?, var, value}},
        state
      ) do
    :ssh_connection.reply_request(connection_handler, want_reply?, :failure, channel_id)

    {:ok, state}
  end

  def handle_ssh_msg(
        {:ssh_cm, _connection_handler,
         {:window_change, _channel_id, _width, _height, _pixwidth, _pixheight}},
        %State{client_pid: client_pid} = state
      ) do
    {:ok, state}
  end

  def handle_ssh_msg(
        {:ssh_cm, connection_handler, {:shell, channel_id, want_reply?}},
        %State{player: player} = state
      ) do
    :ssh_connection.reply_request(connection_handler, want_reply?, :success, channel_id)

    {:ok, client_pid} =
      GenServer.start_link(Client, [
        %Client.State{
          tui_pid: self(),
          player: player
        }
      ])

    send(client_pid, :refresh)
    {:ok, %State{state | client_pid: client_pid}}
  end

  def handle_ssh_msg(
        msg,
        %State{channel_id: channel_id} = state
      ) do
    Logger.debug("UNKOWN MESSAGE #{inspect(msg)}")
    # {:stop, channel_id, state}
    {:ok, state}
  end

  def terminate(_reason, _state) do
    :ok
  end
end

defmodule TicTacToe.Client do
  alias IO.ANSI
  use GenServer

  @clear_codes [
    ANSI.clear(),
    ANSI.home()
  ]

  defmodule State do
    defstruct tui_pid: nil,
              game_manager_pid: nil,
              player: %{},
              game_id: nil
  end

  @impl true
  def init([%State{game_manager_pid: game_manager_pid, player: player} = state]) do
    player = %{
      player
      | client_pid: self()
    }

    send(game_manager_pid, {:join, player})

    {:ok,
     %State{
       player: player
     }}
  end

  @impl true
  def handle_info(:quit, %State{} = state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_info({:join_game, game_id}, %State{} = state) do
    state = %State{state | game_id: game_id}
    render(state)
    {:stop, :normal, state}
  end

  def handle(
        {:data, data},
        %State{} = state
      ) do
    case keymap(data) do
      :quit ->
        {:stop, :normal, state}
    end
  end

  def handle(
        :player_joined,
        %State{} = state
      ) do
    render(state)
    {:noreply, state}
  end

  defp render(%State{
         tui_pid: tui_pid
       }) do
    send(tui_pid, {:send_data, ["Testing"]})
  end

  def keymap(key) do
    case key do
      # Exit keys - C-c and C-d
      <<3>> -> :quit
      <<4>> -> :quit
      x -> x
    end
  end
end
