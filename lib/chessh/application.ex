defmodule Chessh.Application do
  alias Chessh.{PlayerSession, Node}
  use Application

  def initialize_node() do
    # If we have more than one node running the ssh daemon, we'd want to ensure
    # this is restarting after every potential crash. Otherwise the player sessions
    # on the node would hang.

    # User session also need to be cleaned up after the node exits the pool for
    # the same reason.
    node_id = System.fetch_env!("NODE_ID")
    Node.boot(node_id)
    PlayerSession.delete_all_on_node(node_id)
  end

  def start(_, _) do
    children = [
      Chessh.Repo,
      Chessh.SSH.Daemon,
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Chessh.Web.Endpoint,
        options: [port: Application.get_env(:chessh, Web)[:port]]
      )
    ]

    opts = [strategy: :one_for_one, name: Chessh.Supervisor]

    with {:ok, pid} <- Supervisor.start_link(children, opts) do
      initialize_node()
      {:ok, pid}
    end
  end
end
