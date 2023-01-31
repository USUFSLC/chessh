defmodule Chessh.Repo.Migrations.CreatePlayer do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS citext", "")

    create table(:players) do
      add(:discord_id, :string, null: false)
      add(:username, :citext, null: false)
      add(:hashed_password, :string, null: true)
      timestamps()
    end

    create(unique_index(:players, [:username]))
    create(unique_index(:players, [:discord_id]))
  end
end
