defmodule Chessh.Repo.Migrations.IncreaseGameMovesSize do
  use Ecto.Migration

  def change do
    alter table(:games) do
      modify(:game_moves, :string, size: 4096)
    end
  end
end
