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

  @min_terminal_width 64
  @min_terminal_height 31
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
              buffer: [],
              state_stack: [{Menu, %Menu.State{}}]
  end

  @impl true
  def init([%State{tui_pid: tui_pid} = state]) do
    send(tui_pid, {:send_data, render(state)})
    {:ok, state}
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
        %State{tui_pid: tui_pid, state_stack: [{module, _screen_state} | _tail]} = state
      ) do
    action = keymap(data)

    if action == :quit do
      {:stop, :normal, state}
    else
      new_state = module.handle_input(action, state)

      send(tui_pid, {:send_data, render(new_state)})

      {:noreply, new_state}
    end
  end

  def handle({:resize, {width, height}}, %State{tui_pid: tui_pid} = state) do
    new_state = %State{state | width: width, height: height}

    if height <= @max_terminal_height || width <= @max_terminal_width do
      send(tui_pid, {:send_data, render(new_state)})
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

  def terminal_size_allowed(width, height) do
    Enum.member?(@min_terminal_width..@max_terminal_width, width) &&
      Enum.member?(@min_terminal_height..@max_terminal_height, height)
  end

  def render(
        %State{width: width, height: height, state_stack: [{module, _screen_state} | _]} = state
      ) do
    if terminal_size_allowed(width, height) do
      [
        @clear_codes ++
          module.render(state)
      ]
    else
      @terminal_bad_dim_msg
    end
  end
end
