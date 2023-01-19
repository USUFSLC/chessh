defmodule Chessh.Key do
  use Ecto.Schema
  import Ecto.Changeset

  schema "keys" do
    field(:key, :string)
    field(:name, :string)

    belongs_to(:player, Chessh.Player)

    timestamps()
  end

  defimpl Jason.Encoder, for: Chessh.Key do
    def encode(value, opts) do
      Jason.Encode.map(Map.take(value, [:id, :key, :name]), opts)
    end
  end

  def changeset(key, attrs) do
    key
    |> cast(update_encode_key(attrs, :key), [:key, :player_id])
    |> cast(attrs, [:name])
    |> validate_required([:key, :name])
    |> validate_format(:key, ~r/^[\-\w\d]+ [^ ]+$/, message: "invalid public ssh key")
    |> validate_format(:key, ~r/^(?!ssh-dss).+/, message: "DSA keys are not supported")
    |> unique_constraint([:player_id, :key], message: "Player already has that key")
  end

  def encode_key(key) do
    if is_tuple(key) do
      case key do
        {pub, [opts]} -> [{pub, [opts]}]
        {pub, []} -> [{pub, [comment: '']}]
        key -> [{key, [comment: '']}]
      end
      |> :ssh_file.encode(:openssh_key)
    else
      key
    end
    |> String.replace(~r/ [^ ]+\@[^ ]+$/, "")
    |> String.trim()
  end

  defp update_encode_key(attrs, field) do
    if Map.has_key?(attrs, field) do
      Map.update!(attrs, field, &encode_key/1)
    else
      attrs
    end
  end
end
