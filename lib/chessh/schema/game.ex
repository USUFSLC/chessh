defmodule Chessh.Game do
  alias Chessh.Player
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field(:increment_sec, :integer)
    field(:light_clock_ms, :integer)
    field(:dark_clock_ms, :integer)
    field(:last_move, :utc_datetime_usec)

    field(:fen, :string)
    field(:moves, :integer, default: 0)

    field(:turn, Ecto.Enum, values: [:light, :dark], default: :light)
    field(:winner, Ecto.Enum, values: [:light, :dark, :none], default: :none)
    field(:status, Ecto.Enum, values: [:continue, :draw, :winner], default: :continue)

    belongs_to(:light_player, Player, foreign_key: :light_player_id)
    belongs_to(:dark_player, Player, foreign_key: :dark_player_id)

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
      :increment_sec,
      :light_clock_ms,
      :dark_clock_ms,
      :last_move,
      :light_player_id,
      :dark_player_id
    ])
  end
end
