defmodule Chessh.PlayerSession do
  alias Chessh.{Repo, Player, PlayerSession, Utils}
  use Ecto.Schema
  import Ecto.{Query, Changeset}
  require Logger

  schema "player_sessions" do
    field(:process, :string)
    field(:login, :utc_datetime_usec)

    belongs_to(:node, Chessh.Node, type: :string)
    belongs_to(:player, Chessh.Player)
  end

  def changeset(player_session, attrs) do
    player_session
    |> cast(attrs, [:login])
  end

  def concurrent_sessions(player) do
    Repo.aggregate(
      from(p in PlayerSession,
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

  def player_within_concurrent_sessions_and_satisfies(username, auth_fn) do
    max_sessions =
      Application.get_env(:chessh, RateLimits)
      |> Keyword.get(:max_concurrent_user_sessions)

    Repo.transaction(fn ->
      case Repo.one(
             from(p in Player,
               where: p.username == ^String.Chars.to_string(username),
               lock: "FOR UPDATE"
             )
           ) do
        nil ->
          Logger.error("Player with username #{username} does not exist")
          send(self(), {:authed, false})

        player ->
          authed =
            auth_fn.(player) &&
              PlayerSession.concurrent_sessions(player) < max_sessions

          if authed do
            Logger.debug(
              "Creating session for player #{username} on node #{System.fetch_env!("NODE_ID")} with process #{inspect(self())}"
            )

            Repo.insert(%PlayerSession{
              login: DateTime.utc_now(),
              node_id: System.fetch_env!("NODE_ID"),
              player: player,
              process: Utils.pid_to_str(self())
            })

            player
            |> Player.authentications_changeset(%{authentications: player.authentications + 1})
            |> Repo.update()
          end

          send(self(), {:authed, authed})
      end
    end)

    receive do
      {:authed, authed} -> authed
    after
      3_000 -> false
    end
  end
end
