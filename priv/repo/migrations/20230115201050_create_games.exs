defmodule Chessh.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add(:increment_sec, :integer)
      add(:light_clock_ms, :integer)
      add(:dark_clock_ms, :integer)
      add(:last_move, :utc_datetime_usec, null: true)

      add(:fen, :string)
      add(:moves, :integer, default: 0)

      add(:turn, :string)
      add(:winner, :string)
      add(:status, :string)

      add(:light_player_id, references(:players), null: true)
      add(:dark_player_id, references(:players), null: true)

      timestamps()
    end
  end
end
