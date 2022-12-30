defmodule Chessh.Repo.Migrations.AddAuthenticatingColumnToPlayer do
  use Ecto.Migration

  def change do
    alter table(:players) do
      add(:authentications, :integer, default: 0)
    end
  end
end
