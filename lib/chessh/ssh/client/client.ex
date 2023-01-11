defmodule Chessh.SSH.Client do
  alias IO.ANSI
  require Logger

  use GenServer

  @clear_codes [
    ANSI.clear(),
    ANSI.home()
  ]

  @min_terminal_width 64
  @min_terminal_height 31
  @max_terminal_width 200
  @max_terminal_height 100

  defmodule State do
    defstruct tui_pid: nil,
              width: 0,
              height: 0,
              player_session: nil,
              screen_processes: []
  end

  @impl true
  def init([%State{} = state]) do
    {:ok, screen_pid} =
      GenServer.start_link(Chessh.SSH.Client.Menu, [
        %Chessh.SSH.Client.Menu.State{client_pid: self()}
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

  def handle(
        :refresh,
        %State{} = state
      ) do
    render(state)
    {:noreply, state}
  end

  def handle(
        {:send_to_ssh, data},
        %State{width: width, height: height, tui_pid: tui_pid} = state
      ) do
    case get_terminal_dim_msg(width, height) do
      {true, msg} -> send(tui_pid, {:send_data, msg})
      {false, _} -> send(tui_pid, {:send_data, data})
    end

    {:noreply, state}
  end

  def handle(
        {:resize, {width, height}},
        %State{tui_pid: tui_pid, screen_processes: [screen_pid | _]} = state
      ) do
    case get_terminal_dim_msg(width, height) do
      {true, msg} -> send(tui_pid, {:send_data, msg})
      {false, _} -> send(screen_pid, {:render, width, height})
    end

    {:noreply, %State{state | width: width, height: height}}
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

  defp get_terminal_dim_msg(width, height) do
    case {height > @max_terminal_height, height < @min_terminal_height,
          width > @max_terminal_width, width < @min_terminal_width} do
      {true, _, _, _} -> {true, @clear_codes ++ ["The terminal height is too large."]}
      {_, true, _, _} -> {true, @clear_codes ++ ["The terminal height is too small."]}
      {_, _, true, _} -> {true, @clear_codes ++ ["The terminal width is too large"]}
      {_, _, _, true} -> {true, @clear_codes ++ ["The terminal width is too small."]}
      {false, false, false, false} -> {false, nil}
    end
  end

  defp render(%State{
         tui_pid: tui_pid,
         width: width,
         height: height,
         screen_processes: [screen_pid | _]
       }) do
    {out_of_range, msg} = get_terminal_dim_msg(width, height)

    if out_of_range && msg do
      send(tui_pid, {:send_data, msg})
    else
      send(screen_pid, {:render, width, height})
    end
  end
end
