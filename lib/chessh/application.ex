defmodule Chessh.Application do
  alias Chessh.{PlayerSession, Node}
  use Application

  def initialize_player_sessions_on_node() do
    # If we have more than one node running the ssh daemon, we'd want to ensure
    # this is restarting after every potential crash. Otherwise the player sessions
    # on the node would hang.
    node_id = System.fetch_env!("NODE_ID")
    Node.boot(node_id)
    PlayerSession.delete_all_on_node(node_id)
  end

  def start(_, _) do
    children = [Chessh.Repo, Chessh.SSH.Daemon]
    opts = [strategy: :one_for_one, name: Chessh.Supervisor]

    with {:ok, pid} <- Supervisor.start_link(children, opts) do
      initialize_player_sessions_on_node()
      {:ok, pid}
    end
  end
end
