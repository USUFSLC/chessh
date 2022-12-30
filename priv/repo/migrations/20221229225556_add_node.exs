defmodule Chessh.Repo.Migrations.AddNode do
  use Ecto.Migration

  def change do
    create table(:nodes, primary_key: false) do
      add(:id, :string, primary_key: true)
      add(:last_start, :utc_datetime)
    end
  end
end
