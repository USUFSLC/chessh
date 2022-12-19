defmodule Chessh.Key do
  use Ecto.Schema
  import Ecto.Changeset

  schema "keys" do
    field(:key, :string)
    field(:name, :string)

    belongs_to(:player, Chessh.Player)

    timestamps()
  end

  def changeset(key, attrs) do
    key
    |> cast(update_encode_key(attrs, :key), [:key])
    |> cast(attrs, [:name])
    |> validate_required([:key, :name])
    |> validate_format(:key, ~r/[\-\w\d]+ [^ ]+$/, message: "invalid ssh key")
    |> validate_format(:key, ~r/^(?!ssh-dss).+/, message: "DSA keys are not supported")
  end

  defp update_encode_key(attrs, field) do
    if Map.has_key?(attrs, field) do
      Map.update!(attrs, field, &encode_key/1)
    else
      attrs
    end
  end

  def encode_key(key) do
    if is_tuple(key) do
      case key do
        {pub, [opts]} -> [{pub, [opts]}]
        key -> [{key, [comment: '']}]
      end
      |> :ssh_file.encode(:openssh_key)
    else
      key
    end
    # Remove comment at end of key
    |> String.replace(~r/ [^ ]+\@[^ ]+$/, "")
    # Remove potential spaces / newline
    |> String.trim()
  end
end
