defmodule Chessh.SSH.Client do
  alias IO.ANSI
  require Logger

  use GenServer

  @default_message [
    ANSI.clear(),
    ANSI.reset(),
    ANSI.home(),
    ["Hello, world"]
  ]

  defmodule State do
    defstruct tui_pid: nil,
              width: nil,
              height: nil,
              player_session: nil,
              state_statck: []
  end

  @impl true
  def init([%State{tui_pid: tui_pid} = state]) do
    send(tui_pid, {:send_data, @default_message})
    {:ok, state}
  end
end
