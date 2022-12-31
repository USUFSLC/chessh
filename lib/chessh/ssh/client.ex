defmodule Chessh.SSH.Client do
  alias Chessh.SSH.Client
  require Logger

  use GenServer

  # TODO: tui_state_stack is like [:menu, :player_settings, :change_password] or [:menu, {:game, game_id}, {:game_chat, game_id}]

  defstruct [:tui_pid, :width, :height, :player_id, :tui_state_stack]

  @impl true
  def init([tui_pid, width, height] = args) do
    Logger.debug("#{inspect(args)}")
    {:ok, %Client{tui_pid: tui_pid, width: width, height: height}}
  end
end
