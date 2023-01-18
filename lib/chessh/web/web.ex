defmodule Chessh.Web.Endpoint do
  alias Chessh.{Player, Repo, Key}
  alias Chessh.Web.Token
  use Plug.Router
  require Logger

  plug(Plug.Logger)
  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  get "/oauth/redirect" do
    [github_login_url, client_id, client_secret, github_user_api_url, github_user_agent] =
      get_github_configs()

    resp =
      case conn.params do
        %{"code" => req_token} ->
          case :httpc.request(
                 :post,
                 {String.to_charlist(
                    "#{github_login_url}?client_id=#{client_id}&client_secret=#{client_secret}&code=#{req_token}"
                  ), [], 'application/json', ''},
                 [],
                 []
               ) do
            {:ok, {{_, 200, 'OK'}, _, resp}} ->
              URI.decode_query(String.Chars.to_string(resp))
          end
      end

    {status, body} =
      case resp do
        %{"access_token" => access_token} ->
          case :httpc.request(
                 :get,
                 {String.to_charlist(github_user_api_url),
                  [
                    {'Authorization', String.to_charlist("Bearer #{access_token}")},
                    {'User-Agent', github_user_agent}
                  ]},
                 [],
                 []
               ) do
            {:ok, {{_, 200, 'OK'}, _, user_details}} ->
              %{"login" => username, "id" => github_id} =
                Jason.decode!(String.Chars.to_string(user_details))

              %Player{id: id} =
                Repo.insert!(%Player{github_id: github_id, username: username},
                  on_conflict: [set: [github_id: github_id]],
                  conflict_target: :github_id
                )

              {200,
               %{
                 success: true,
                 jwt:
                   Token.generate_and_sign!(%{
                     "uid" => id
                   })
               }}

            _ ->
              {400, %{errors: "Access token was incorrect. Try again."}}
          end

        _ ->
          {400, %{errors: "Failed to retrieve token from GitHub. Try again."}}
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end

  put "/player/password" do
    jwt =
      Enum.find_value(conn.req_headers, fn {header, value} ->
        if header === "authorization", do: value
      end)

    {:ok, %{"uid" => uid}} = Token.verify_and_validate(jwt)

    player = Repo.get(Player, uid)

    {status, body} =
      case conn.body_params do
        %{"password" => password, "password_confirmation" => password_confirmation} ->
          case Player.password_changeset(player, %{
                 password: password,
                 password_confirmation: password_confirmation
               })
               |> Repo.update() do
            {:ok, player} ->
              {200, %{success: true, id: player.id}}

            {:error, %{valid?: false} = changeset} ->
              {400, %{errors: format_errors(changeset)}}
          end
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end

  post "/player/login" do
    {status, body} =
      case conn.body_params do
        %{"username" => username, "password" => password} ->
          player = Repo.get_by(Player, username: username)

          case Player.valid_password?(player, password) do
            true ->
              {
                200,
                %{
                  token:
                    Token.generate_and_sign!(%{
                      "uid" => player.id
                    })
                }
              }

            _ ->
              {
                400,
                %{
                  errors: "Invalid credentials"
                }
              }
          end

        _ ->
          {
            400,
            %{errors: "Username and password must be defined"}
          }
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end

  post "/player/keys" do
    jwt =
      Enum.find_value(conn.req_headers, fn {header, value} ->
        if header === "authorization", do: value
      end)

    {:ok, %{"uid" => uid}} = Token.verify_and_validate(jwt)

    {status, body} =
      case conn.body_params do
        %{"key" => key, "name" => name} ->
          case Key.changeset(%Key{}, %{player_id: uid, key: key, name: name}) |> Repo.insert() do
            {:ok, _new_key} ->
              {
                200,
                %{
                  success: true
                }
              }

            {:error, %{valid?: false} = changeset} ->
              {
                400,
                %{
                  errors: format_errors(changeset)
                }
              }
          end

        _ ->
          {
            400,
            %{errors: "Must define key and name"}
          }
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end

  get "/player/:id/keys" do
    %{"id" => player_id} = conn.path_params

    keys = (Repo.get(Player, player_id) |> Repo.preload([:keys])).keys

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{keys: keys}))
  end

  delete "/keys/:id" do
    %{"id" => key_id} = conn.path_params

    jwt =
      Enum.find_value(conn.req_headers, fn {header, value} ->
        if header === "authorization", do: value
      end)

    {:ok, %{"uid" => uid}} = Token.verify_and_validate(jwt)

    key = Repo.get(Key, key_id)

    {status, body} =
      if key && uid == key.player_id do
        case Repo.delete(key) do
          {:ok, _} ->
            {200, %{success: true}}

          {:error, changeset} ->
            {400, %{errors: format_errors(changeset)}}
        end
      else
        if !key do
          {404, %{errors: "Key not found"}}
        else
          {401, %{errors: "You cannot delete that key"}}
        end
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end

  match _ do
    send_resp(conn, 404, "Route undefined")
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  defp get_github_configs() do
    Enum.map(
      [
        :github_oauth_login_url,
        :github_client_id,
        :github_client_secret,
        :github_user_api_url,
        :github_user_agent
      ],
      fn key -> Application.get_env(:chessh, Web)[key] end
    )
  end
end
