defmodule Chessh.Repo.Migrations.AddKeys do
  use Ecto.Migration

  def change do
    create table(:keys) do
      add :key, :string, null: false
      add :name, :string, null: false

      add :player_id, references(:players)

      timestamps()
    end
  end
end
