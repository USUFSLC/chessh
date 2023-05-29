defmodule Chessh.Repo.Migrations.AddBots do
  use Ecto.Migration

  def change do
    create table(:bots) do
      add(:name, :citext, null: false)
      add(:webhook, :string, null: false)
      add(:token, :string, null: false)
      add(:public, :boolean, null: false)
      add(:player_id, references(:players), null: false)

      timestamps()
    end

    create(unique_index(:bots, [:name]))
    create(unique_index(:bots, [:token]))

    alter table(:games) do
      add(:bot_id, references(:bots), null: true)
    end
  end
end
