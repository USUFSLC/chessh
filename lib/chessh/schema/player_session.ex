defmodule Chessh.PlayerSession do
  alias Chessh.Repo
  use Ecto.Schema
  import Ecto.{Query, Changeset}

  schema "player_sessions" do
    field(:login, :utc_datetime)

    belongs_to(:node, Chessh.Node, type: :string)
    belongs_to(:player, Chessh.Player)
  end

  def changeset(player_session, attrs) do
    player_session
    |> cast(attrs, [:login])
  end

  def concurrent_sessions(player) do
    Repo.aggregate(
      from(p in Chessh.PlayerSession,
        where: p.player_id == ^player.id
      ),
      :count
    )
  end

  def delete_all_on_node(node_id) do
    Repo.delete_all(
      from(p in Chessh.PlayerSession,
        where: p.node_id == ^node_id
      )
    )
  end
end
