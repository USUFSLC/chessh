defmodule Chessh.Game do
  alias Chessh.{Bot, Player, Game}
  use Ecto.Schema
  import Ecto.Changeset

  @default_fen "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

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

    belongs_to(:bot, Bot, foreign_key: :bot_id)

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
      :bot_id,
      :game_moves
    ])
  end

  def new_game(initial_player_color, player_id, fen \\ @default_fen) do
    Game.changeset(
      %Game{
        fen: fen
      },
      if(initial_player_color == :light,
        do: %{light_player_id: player_id},
        else: %{dark_player_id: player_id}
      )
    )
  end

  def update_with_status(%Game{} = game, move, fen, status) do
    Game.changeset(
      game,
      %{
        fen: fen,
        moves: game.moves + 1,
        turn: if(game.turn == :dark, do: :light, else: :dark),
        last_move: move,
        game_moves:
          if(!is_nil(game) && game.game_moves != "", do: "#{game.game_moves} ", else: "") <> move
      }
      |> Map.merge(changeset_from_status(status))
    )
  end

  def changeset_from_status(game_status) do
    case game_status do
      :continue ->
        %{}

      {:draw, _} ->
        %{status: :draw}

      {:checkmate, :white_wins} ->
        %{status: :winner, winner: :light}

      {:checkmate, :black_wins} ->
        %{status: :winner, winner: :dark}
    end
  end
end
