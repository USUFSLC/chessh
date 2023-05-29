defmodule Chessh.Bot do
  alias Chessh.{Player, Game, Repo}
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset

  require Logger

  @derive {Jason.Encoder, only: [:id, :name, :webhook, :token, :public]}
  schema "bots" do
    field(:name, :string)
    field(:webhook, :string)
    field(:token, :string)
    field(:public, :boolean, default: false)

    belongs_to(:player, Player, foreign_key: :player_id)

    timestamps()
  end

  def changeset(game, attrs) do
    game
    |> cast(attrs, [
      :public,
      :name,
      :webhook,
      :token,
      :player_id
    ])
    |> validate_required([:name, :webhook, :token, :public])
    |> validate_format(:webhook, ~r/^https:\/\//, message: "must start with https://")
    |> unique_constraint(:name)
  end

  def make_game_status_message(%Game{
        id: game_id,
        bot: %Chessh.Bot{id: bot_id, name: bot_name},
        fen: fen,
        turn: turn,
        status: status,
        light_player_id: light_player_id,
        dark_player_id: dark_player_id
      }) do
    %{
      bot_id: bot_id,
      bot_name: bot_name,
      game_id: game_id,
      fen: fen,
      turn: Atom.to_string(turn),
      bot_turn:
        (is_nil(light_player_id) && turn == :light) || (is_nil(dark_player_id) && turn == :dark),
      status: Atom.to_string(status)
    }
  end

  def redrive_games(%Chessh.Bot{id: bot_id, webhook: webhook}) do
    messages =
      Repo.all(from(g in Game, where: g.bot_id == ^bot_id))
      |> Repo.preload([:bot])
      |> Enum.map(&make_game_status_message/1)

    send_message(webhook, messages)
  end

  def send_update(%Game{bot: %Chessh.Bot{webhook: webhook}} = game) do
    send_message(webhook, make_game_status_message(game))
  end

  defp send_message(webhook, msg) do
    :httpc.request(
      :post,
      {String.to_charlist(webhook), [], 'application/json', Jason.encode!(msg)},
      [],
      []
    )
  end
end
