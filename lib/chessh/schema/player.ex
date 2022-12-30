defmodule Chessh.Player do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Inspect, except: [:password]}
  schema "players" do
    field(:username, :string)

    field(:password, :string, virtual: true)
    field(:hashed_password, :string)

    field(:authentications, :integer, default: 0)

    has_many(:keys, Chessh.Key)

    timestamps()
  end

  def authentications_changeset(player, attrs) do
    player
    |> cast(attrs, [:authentications])
  end

  def registration_changeset(player, attrs, opts \\ []) do
    player
    |> cast(attrs, [:username, :password])
    |> validate_username()
    |> validate_password(opts)
  end

  def password_changeset(player, attrs, opts \\ []) do
    player
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  def valid_password?(%Chessh.Player{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  defp validate_username(changeset) do
    changeset
    |> validate_required([:username])
    |> validate_length(:username, min: 2, max: 16)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_\-]*$/,
      message: "only letters, numbers, underscores, and hyphens allowed"
    )
    |> unique_constraint(:username)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 80)
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end
end
