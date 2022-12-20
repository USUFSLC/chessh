defmodule Chessh.Repo.Migrations.CreatePlayer do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS citext", "")

    create table(:players) do
      add(:username, :citext, null: false)
      add(:hashed_password, :string, null: false)
      timestamps()
    end

    create(unique_index(:players, [:username]))
  end
end
