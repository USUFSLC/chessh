defmodule Chessh.Player do
  use Ecto.Schema
  import Ecto.Changeset
  alias Chessh.{Key, Game, Bot}

  @derive {Inspect, except: [:password]}
  schema "players" do
    field(:discord_id, :string)

    field(:username, :string)

    field(:password, :string, virtual: true)
    field(:hashed_password, :string)

    field(:authentications, :integer, default: 0)

    has_many(:keys, Key)
    has_many(:light_games, Game, foreign_key: :light_player_id, references: :id)
    has_many(:dark_games, Game, foreign_key: :dark_player_id, references: :id)
    has_many(:bots, Bot, foreign_key: :player_id, references: :id)

    timestamps()
  end

  defimpl Jason.Encoder, for: Chessh.Player do
    def encode(value, opts) do
      Jason.Encode.map(
        Map.take(value, [:id, :discord_id, :username, :created_at, :updated_at]),
        opts
      )
    end
  end

  def authentications_changeset(player, attrs) do
    player
    |> cast(attrs, [:authentications])
  end

  def discord_changeset(player, attrs) do
    player
    |> cast(attrs, [:username, :discord_id])
    |> validate_username()
    |> validate_discord_id()
  end

  def registration_changeset(player, attrs, opts \\ []) do
    player
    |> cast(attrs, [:username, :password, :discord_id])
    |> validate_username()
    |> validate_password(opts)
    |> validate_discord_id()
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

  defp validate_discord_id(changeset) do
    changeset
    |> unique_constraint(:discord_id)
  end

  defp validate_username(changeset) do
    changeset
    |> validate_required([:username])
    |> validate_length(:username, min: 2, max: 40)
    |> validate_format(:username, ~r/^.{3,32}#[0-9]{4}$/, message: "must match discord tag format")
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
