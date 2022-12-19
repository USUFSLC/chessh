defmodule Chessh.Repo do
  use Ecto.Repo,
    otp_app: :chessh,
    adapter: Ecto.Adapters.Postgres
end
