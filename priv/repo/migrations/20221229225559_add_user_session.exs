defmodule Chessh.Repo.Migrations.AddUserSession do
  use Ecto.Migration

  def change do
    create table(:player_sessions) do
      add(:process, :string)
      add(:login, :utc_datetime_usec)

      add(:player_id, references(:players))
      add(:node_id, references(:nodes, type: :string))
    end

    create(unique_index(:player_sessions, [:process, :node_id]))
  end
end
