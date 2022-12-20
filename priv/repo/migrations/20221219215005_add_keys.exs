defmodule Chessh.Repo.Migrations.AddKeys do
  use Ecto.Migration

  def change do
    create table(:keys) do
      add(:key, :text, null: false)
      add(:name, :string, null: false)

      add(:player_id, references(:players))

      timestamps()
    end

    create(unique_index(:keys, [:player_id, :key]))
  end
end
