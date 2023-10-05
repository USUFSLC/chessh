defmodule Chessh.Chat do
  use Ecto.Schema
  import Ecto.Changeset
  alias Chessh.Player

  schema "chats" do
    field(:message, :string)
    belongs_to(:chatter, Player, foreign_key: :chatter_id)
    timestamps()
  end

  def changeset(chat, attrs) do
    chat
    |> cast(attrs, [
      :message,
      :chatter_id
    ])
  end
end
