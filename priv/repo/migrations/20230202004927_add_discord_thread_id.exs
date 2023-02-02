defmodule Chessh.Repo.Migrations.AddDiscordThreadId do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:discord_thread_id, :string, null: true)
    end
  end
end
