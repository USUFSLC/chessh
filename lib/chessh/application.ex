defmodule Chessh.Application do
  use Application

  def start(_, _) do
    children = [Chessh.Repo]
    opts = [strategy: :one_for_one, name: Chessh.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
