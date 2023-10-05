defmodule Chessh.Repo.Migrations.AddTrongleChat do
  use Ecto.Migration

  def change do
    create table(:chats) do
      add(:message, :string, null: false)
      add(:chatter_id, references(:players), null: false)

      timestamps()
    end
  end
end
