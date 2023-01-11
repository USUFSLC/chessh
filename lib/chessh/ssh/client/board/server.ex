# defmodule Chessh.SSH.Client.Board.Server do
#  use GenServer
#
#  defmodule State do
#    defstruct game_id: nil,
#              binbo_pid: nil
#  end
#
#  def init([%State{game_id: game_id} = state]) do
#    {:ok, binbo_pid} = GenServer.start_link(:binbo, [])
#
#    :syn.join(:games, {:game, game_id})
#    {:ok, state}
#  end
#
#  def handle_cast({:new_move, attempted_move}, %State{game_id: game_id} = state) do
#    {:no_reply, state}
#  end
# end
