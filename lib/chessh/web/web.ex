defmodule Chessh.Web.Endpoint do
  alias Chessh.{Player, Repo, Key, PlayerSession}
  alias Chessh.Web.Token
  use Plug.Router
  import Ecto.Query

  plug(Plug.Logger)
  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  get "/oauth/redirect" do
    [
      discord_login_url,
      discord_scope,
      client_id,
      client_secret,
      discord_user_api_url,
      discord_user_agent,
      redirect_uri
    ] = get_discord_configs()

    resp =
      case conn.params do
        %{"code" => req_token} ->
          case :httpc.request(
                 :post,
                 {String.to_charlist(discord_login_url), [], 'application/x-www-form-urlencoded',
                  'scope=#{discord_scope}&client_id=#{client_id}&client_secret=#{client_secret}&code=#{req_token}&grant_type=authorization_code&redirect_uri=#{redirect_uri}'},
                 [],
                 []
               ) do
            {:ok, {{_, 200, 'OK'}, _, resp}} ->
              Jason.decode!(String.Chars.to_string(resp))
          end
      end

    {status, body} =
      create_player_from_discord_response(resp, discord_user_api_url, discord_user_agent)

    conn
    |> assign_jwt_and_redirect_or_encode(status, body)
  end

  delete "/player/token/password" do
    player = get_player_from_jwt(conn)
    PlayerSession.close_all_player_sessions(player)

    {status, body} =
      case Repo.update(Ecto.Changeset.change(player, %{hashed_password: nil})) do
        {:ok, _new_player} ->
          {200, %{success: true}}

        {:error, _} ->
          {400, %{success: false}}
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end

  put "/player/token/password" do
    player = get_player_from_jwt(conn)
    PlayerSession.close_all_player_sessions(player)

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

  get "/player/logout" do
    conn
    |> delete_resp_cookie("jwt")
    |> send_resp(200, Jason.encode!(%{success: true}))
  end

  post "/player/keys" do
    player = get_player_from_jwt(conn)

    player_key_count =
      Repo.aggregate(from(k in Key, where: k.player_id == ^player.id), :count, :id)

    max_key_count = Application.get_env(:chessh, RateLimits)[:player_public_keys]

    {status, body} =
      case conn.body_params do
        %{"key" => key, "name" => name} ->
          if player_key_count > max_key_count do
            {400, %{errors: "Player has reached threshold of #{max_key_count} keys."}}
          else
            case Key.changeset(%Key{player_id: player.id}, %{key: key, name: name})
                 |> Repo.insert() do
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

  get "/player/token/me" do
    {:ok, jwt} = Token.verify_and_validate(get_jwt(conn))

    %{"uid" => player_id, "exp" => expiration} = jwt
    player = Repo.get(Player, player_id)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{player: player, expiration: expiration * 1000}))
  end

  get "/player/:id/keys" do
    %{"id" => player_id} = conn.path_params

    keys = (Repo.get(Player, player_id) |> Repo.preload([:keys])).keys

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(keys))
  end

  delete "/keys/:id" do
    player = get_player_from_jwt(conn)
    PlayerSession.close_all_player_sessions(player)

    %{"id" => key_id} = conn.path_params
    key = Repo.get(Key, key_id)

    {status, body} =
      if key && player.id == key.player_id do
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

  defp get_discord_configs() do
    Enum.map(
      [
        :discord_oauth_login_url,
        :discord_scope,
        :discord_client_id,
        :discord_client_secret,
        :discord_user_api_url,
        :discord_user_agent,
        :client_redirect_after_successful_sign_in
      ],
      fn key -> Application.get_env(:chessh, Web)[key] end
    )
  end

  defp get_jwt(conn) do
    auth_header =
      Enum.find_value(conn.req_headers, fn {header, value} ->
        if header === "authorization", do: value
      end)

    if auth_header, do: auth_header, else: Map.get(fetch_cookies(conn).cookies, "jwt")
  end

  defp get_player_from_jwt(conn) do
    {:ok, %{"uid" => uid}} = Token.verify_and_validate(get_jwt(conn))

    Repo.get(Player, uid)
  end

  defp assign_jwt_and_redirect_or_encode(conn, status, body) do
    case body do
      %{jwt: token} ->
        client_redirect_location =
          Application.get_env(:chessh, Web)[:client_redirect_after_successful_sign_in]

        conn
        |> put_resp_cookie("jwt", token)
        |> put_resp_header("location", client_redirect_location)
        |> send_resp(301, '')

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(status, Jason.encode!(body))
    end
  end

  defp create_player_from_discord_response(resp, discord_user_api_url, discord_user_agent) do
    case resp do
      %{"access_token" => access_token} ->
        case :httpc.request(
               :get,
               {String.to_charlist(discord_user_api_url),
                [
                  {'Authorization', String.to_charlist("Bearer #{access_token}")},
                  {'User-Agent', discord_user_agent}
                ]},
               [],
               []
             ) do
          {:ok, {{_, 200, 'OK'}, _, user_details}} ->
            %{"username" => username, "id" => discord_id} =
              Jason.decode!(String.Chars.to_string(user_details))

            %Player{id: id} =
              Repo.insert!(%Player{discord_id: discord_id, username: username},
                on_conflict: [set: [discord_id: discord_id]],
                conflict_target: :discord_id
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
        {400, %{errors: "Failed to retrieve token from Discord. Try again."}}
    end
  end
end
