defmodule Chessh.Repo.Migrations.AddUserSession do
  use Ecto.Migration

  def change do
    create table(:player_sessions) do
      add(:login, :utc_datetime)
      add(:player_id, references(:players))
      add(:node_id, references(:nodes, type: :string))
    end
  end
end
