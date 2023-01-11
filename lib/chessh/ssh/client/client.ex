defmodule Chessh.SSH.Client do
  alias IO.ANSI
  alias Chessh.SSH.Client.Menu
  require Logger

  use GenServer

  @clear_codes [
    ANSI.clear(),
    ANSI.reset(),
    ANSI.home()
  ]

  @max_terminal_width 255
  @max_terminal_height 127

  @terminal_bad_dim_msg [
    @clear_codes | "The dimensions of your terminal are not within in the valid range"
  ]

  defmodule State do
    defstruct tui_pid: nil,
              width: 0,
              height: 0,
              player_session: nil,
              screen_processes: []
  end

  @impl true
  def init([%State{tui_pid: tui_pid} = state]) do
    {:ok, screen_pid} =
      GenServer.start_link(Chessh.SSH.Client.Menu, [
        %Chessh.SSH.Client.Menu.State{tui_pid: tui_pid}
      ])

    {:ok, %{state | screen_processes: [screen_pid]}}
  end

  @impl true
  def handle_info(:quit, %State{} = state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_info(msg, state) do
    [burst_ms, burst_rate] =
      Application.get_env(:chessh, RateLimits)
      |> Keyword.take([:player_session_message_burst_ms, :player_session_message_burst_rate])
      |> Keyword.values()

    case Hammer.check_rate_inc(
           "player-session-#{state.player_session.id}-burst-message-rate",
           burst_ms,
           burst_rate,
           1
         ) do
      {:allow, _count} ->
        handle(msg, state)

      {:deny, _limit} ->
        {:noreply, state}
    end
  end

  def handle(
        {:data, data},
        %State{width: width, height: height, screen_processes: [screen_pid | _]} = state
      ) do
    action = keymap(data)

    if action == :quit do
      {:stop, :normal, state}
    else
      send(screen_pid, {:input, width, height, action})
      {:noreply, state}
    end
  end

  #  def handle(
  #        {:refresh, },
  #        %State{screen_processes: [screen_pid | _] = screen_processes, width: width, height: height} = state
  #      ) do
  #    send(screen_pid, {:render, tui_pid, width, height})
  #    {:noreply, state}
  #  end

  def handle(
        {:resize, {width, height}},
        %State{tui_pid: tui_pid, screen_processes: [screen_pid | _]} = state
      ) do
    new_state = %State{state | width: width, height: height}

    if height <= @max_terminal_height && width <= @max_terminal_width do
      send(screen_pid, {:render, width, height})
    else
      send(tui_pid, {:send_data, @terminal_bad_dim_msg})
    end

    {:noreply, new_state}
  end

  def keymap(key) do
    case key do
      # Exit keys - C-c and C-d
      <<3>> -> :quit
      <<4>> -> :quit
      # Arrow keys
      "\e[A" -> :up
      "\e[B" -> :down
      "\e[D" -> :left
      "\e[C" -> :right
      "\r" -> :return
      x -> x
    end
  end
end
