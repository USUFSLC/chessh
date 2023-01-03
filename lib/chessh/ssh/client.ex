defmodule Chessh.SSH.Client do
  alias IO.ANSI

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
              state_stack: [{&Chessh.SSH.Client.Menu.render/2, []}]
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

  def handle({:data, data}, %State{tui_pid: tui_pid} = state) do
    new_state =
      keymap(data)
      |> keypress(state)

    send(tui_pid, {:send_data, render(new_state)})
    {:noreply, new_state}
  end

  def handle({:resize, {width, height}}, %State{tui_pid: tui_pid} = state) do
    new_state = %State{state | width: width, height: height}

    if height <= @max_terminal_height || width <= @max_terminal_width do
      send(tui_pid, {:send_data, render(new_state)})
    end

    {:noreply, new_state}
  end

  def keypress(:up, state), do: state
  def keypress(:right, state), do: state
  def keypress(:down, state), do: state
  def keypress(:left, state), do: state

  def keypress(:quit, state) do
    send(self(), :quit)
    state
  end

  def keypress(_, state), do: state

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
      x -> x
    end
  end

  @spec terminal_size_allowed(any, any) :: boolean
  def terminal_size_allowed(width, height) do
    Enum.member?(@min_terminal_width..@max_terminal_width, width) &&
      Enum.member?(@min_terminal_height..@max_terminal_height, height)
  end

  defp render(%{width: width, height: height, state_stack: [{render_fn, args} | _tail]} = state) do
    if terminal_size_allowed(width, height) do
      [
        @clear_codes ++
          render_fn.(state, args)
      ]
    else
      @terminal_bad_dim_msg
    end
  end
end
