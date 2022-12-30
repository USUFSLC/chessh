defmodule Chessh.Node do
  alias Chessh.Repo
  import Ecto.Changeset
  use Ecto.Schema

  @primary_key {:id, :string, []}
  schema "nodes" do
    field(:last_start, :utc_datetime_usec)
  end

  def changeset(node, attrs) do
    node
    |> cast(attrs, [:last_start])
  end

  def boot(node_id) do
    case Repo.get(Chessh.Node, node_id) do
      nil -> %Chessh.Node{id: node_id}
      node -> node
    end
    |> changeset(%{last_start: DateTime.utc_now()})
    |> Repo.insert_or_update()
  end
end
