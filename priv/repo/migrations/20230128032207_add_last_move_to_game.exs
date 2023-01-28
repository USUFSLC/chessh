defmodule Chessh.Repo.Migrations.AddLastMoveToGame do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:last_move, :string, null: true)
    end
  end
end
