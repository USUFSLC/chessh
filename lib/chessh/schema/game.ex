defmodule Chessh.Game do
  alias Chessh.Player
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field(:fen, :string)
    field(:moves, :integer, default: 0)
    field(:last_move, :string)

    field(:turn, Ecto.Enum, values: [:light, :dark], default: :light)
    field(:winner, Ecto.Enum, values: [:light, :dark, :none], default: :none)
    field(:status, Ecto.Enum, values: [:continue, :draw, :winner], default: :continue)

    field(:game_moves, :string)

    belongs_to(:light_player, Player, foreign_key: :light_player_id)
    belongs_to(:dark_player, Player, foreign_key: :dark_player_id)

    field(:discord_thread_id, :string)

    timestamps()
  end

  def changeset(game, attrs) do
    game
    |> cast(attrs, [
      :fen,
      :moves,
      :turn,
      :winner,
      :status,
      :last_move,
      :light_player_id,
      :dark_player_id,
      :discord_thread_id,
      :game_moves
    ])
  end
end
