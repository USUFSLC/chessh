defmodule Chessh.Repo.Migrations.AddMoveHistory do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:game_moves, :string, size: 1024)
    end
  end
end
