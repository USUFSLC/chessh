defmodule Chessh.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Chessh.Repo

      import Ecto
      import Ecto.Query
      import Chessh.RepoCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Chessh.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Chessh.Repo, {:shared, self()})
    end

    :ok
  end
end
