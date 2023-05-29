defmodule Chessh.SSH.Client do
  alias IO.ANSI
  use GenServer

  @clear_codes [
    ANSI.clear(),
    ANSI.home()
  ]

  @min_terminal_width 64
  @min_terminal_height 38

  defmodule State do
    defstruct tui_pid: nil,
              width: 0,
              height: 0,
              player_session: nil,
              screen_pid: nil,
              screen_state_initials: []
  end

  def link_menu_screen(player_session) do
    send(
      self(),
      {:set_screen_process, Chessh.SSH.Client.MainMenu,
       %Chessh.SSH.Client.SelectPaginatePoller.State{player_session: player_session}}
    )
  end

  @impl true
  def init([%State{player_session: player_session} = state]) do
    link_menu_screen(player_session)

    {:ok, state}
  end

  @impl true
  def handle_info(
        {:set_screen_process, module, screen_state_initial},
        %State{
          width: width,
          height: height,
          screen_state_initials: screen_state_initials
        } = state
      ) do
    case GenServer.start_link(module, [%{screen_state_initial | client_pid: self()}]) do
      {:ok, new_screen_pid} ->
        send(new_screen_pid, {:render, width, height})

        {:noreply,
         %State{
           state
           | screen_pid: new_screen_pid,
             screen_state_initials: [{module, screen_state_initial} | screen_state_initials]
         }}

      _ ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:go_back_one_screen, previous_state}, %State{} = state) do
    {:noreply, go_back_one_screen(state, previous_state)}
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
           :in_memory,
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
        %State{
          width: width,
          height: height,
          screen_pid: screen_pid,
          player_session: player_session
        } = state
      ) do
    case keymap(data) do
      :quit ->
        {:stop, :normal, state}

      :menu ->
        GenServer.stop(screen_pid)
        link_menu_screen(player_session)

        {:noreply, state}

      action ->
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
        %State{tui_pid: tui_pid, screen_pid: screen_pid} = state
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
      # C-b
      <<2>> -> :menu
      # Escape
      "\e" -> :escape
      # VIM keys
      "k" -> :up
      "j" -> :down
      "h" -> :left
      "l" -> :right
      # Arrow keys
      "\e[A" -> :up
      "\e[B" -> :down
      "\e[D" -> :left
      "\e[C" -> :right
      "\eOA" -> :up
      "\eOB" -> :down
      "\eOD" -> :left
      "\eOC" -> :right
      "\r" -> :return
      x -> x
    end
  end

  defp get_terminal_dim_msg(width, height) do
    case {height < @min_terminal_height, width < @min_terminal_width} do
      {true, _} -> {true, @clear_codes ++ ["The terminal height is too small."]}
      {_, true} -> {true, @clear_codes ++ ["The terminal width is too small."]}
      {false, false} -> {false, nil}
    end
  end

  defp render(%State{
         tui_pid: tui_pid,
         width: width,
         height: height,
         screen_pid: screen_pid
       }) do
    {out_of_range, msg} = get_terminal_dim_msg(width, height)

    if out_of_range && msg do
      send(tui_pid, {:send_data, msg})
    else
      send(screen_pid, {:render, width, height})
    end
  end

  defp go_back_one_screen(
         %State{
           screen_pid: screen_pid,
           screen_state_initials: [_ | rest_initial]
         } = state,
         previous_state
       ) do
    [{prev_module, prev_state_initial} | _] = rest_initial

    send(
      self(),
      {:set_screen_process, prev_module,
       if(is_nil(previous_state), do: prev_state_initial, else: previous_state)}
    )

    if screen_pid do
      GenServer.stop(screen_pid)
    end

    %State{state | screen_state_initials: rest_initial}
  end
end
