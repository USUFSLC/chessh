defmodule Chessh.DiscordNotifier do
  use GenServer

  @name :discord_notifier

  alias Chessh.{Game, Player, Repo}

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: @name)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast(x, state), do: handle_info(x, state)

  @impl true
  def handle_info({:attempt_notification, notification} = body, state) do
    [discord_notification_rate, discord_notification_rate_ms] =
      Application.get_env(:chessh, RateLimits)
      |> Keyword.take([:discord_notification_rate, :discord_notification_rate_ms])
      |> Keyword.values()

    reschedule_delay = Application.get_env(:chessh, RateLimits)[:reschedule_delay]

    case Hammer.check_rate_inc(
           :redis,
           "discord-rate",
           discord_notification_rate_ms,
           discord_notification_rate,
           1
         ) do
      {:allow, _count} ->
        send_notification(notification)

      {:deny, _limit} ->
        Process.send_after(self(), body, reschedule_delay)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:schedule_notification, notification, delay}, state) do
    Process.send_after(self(), {:attempt_notification, notification}, delay)
    {:noreply, state}
  end

  defp send_notification({:move_reminder, game_id}) do
    [min_delta_t, remind_move_channel_id] =
      Application.get_env(:chessh, DiscordNotifications)
      |> Keyword.take([:game_move_notif_delay_ms, :remind_move_channel_id])
      |> Keyword.values()

    case Repo.get(Game, game_id) |> Repo.preload([:dark_player, :light_player]) do
      %Game{
        dark_player: %Player{discord_id: dark_player_discord_id},
        light_player: %Player{discord_id: light_player_discord_id},
        turn: turn,
        updated_at: last_updated,
        moves: move_count,
        status: :continue,
        discord_thread_id: discord_thread_id
      } = game ->
        delta_t = NaiveDateTime.diff(NaiveDateTime.utc_now(), last_updated, :millisecond)

        game =
          if is_nil(discord_thread_id) do
            {:ok, game} =
              Game.changeset(game, %{
                discord_thread_id: make_private_discord_thread_id(remind_move_channel_id, game)
              })
              |> Repo.update()

            game
          else
            game
          end

        if delta_t >= min_delta_t do
          post_discord(
            game.discord_thread_id,
            "<@#{if turn == :light, do: light_player_discord_id, else: dark_player_discord_id}> it is your move in Game #{game_id} (move #{move_count})."
          )
        end

      _ ->
        nil
    end
  end

  defp send_notification({:cleanup_thread, game_id}) do
    case Repo.get(Game, game_id) |> Repo.preload([:dark_player, :light_player]) do
      %Game{
        discord_thread_id: discord_thread_id,
        status: status
      } = game ->
        if !is_nil(discord_thread_id) && status != :continue do
          destroy_channel(discord_thread_id)

          Game.changeset(game, %{
            discord_thread_id: nil
          })
          |> Repo.update()
        end

      _ ->
        nil
    end
  end

  defp send_notification({:game_created, game_id}) do
    [pingable_mention, new_game_channel_id] =
      Application.get_env(:chessh, DiscordNotifications)
      |> Keyword.take([:looking_for_games_role_mention, :new_game_channel_id])
      |> Keyword.values()

    case Repo.get(Game, game_id) do
      game ->
        %Game{
          dark_player: dark_player,
          light_player: light_player
        } = Repo.preload(game, [:dark_player, :light_player])

        message =
          case {is_nil(light_player), is_nil(dark_player)} do
            {true, false} ->
              "#{pingable_mention}, <@#{dark_player.discord_id}> is looking for an opponent to play with light pieces in Game #{game_id}"

            {false, true} ->
              "#{pingable_mention}, <@#{light_player.discord_id}> is looking for an opponent to play with dark pieces in Game #{game_id}"

            _ ->
              false
          end

        if message do
          post_discord(new_game_channel_id, message)
        end
    end
  end

  defp make_private_discord_thread_id(channel_id, %Game{
         id: game_id,
         dark_player: %Player{discord_id: dark_player_discord_id, username: dark_username},
         light_player: %Player{discord_id: light_player_discord_id, username: light_username}
       }) do
    case make_discord_api_call(
           :post,
           "channels/#{channel_id}/threads",
           %{
             # Private thread
             type: 12,
             name: "Game #{game_id} - #{light_username} V #{dark_username}"
           }
         ) do
      {:ok, {_, _, body}} ->
        %{"id" => thread_id} = Jason.decode!(body)

        [light_player_discord_id, dark_player_discord_id]
        |> Enum.map(fn id ->
          make_discord_api_call(:put, 'channels/#{thread_id}/thread-members/#{id}')
        end)

        thread_id

      _ ->
        nil
    end
  end

  defp post_discord(channel_id, message) do
    make_discord_api_call(:post, "channels/#{channel_id}/messages", %{content: message})
  end

  defp destroy_channel(channel_id) do
    make_discord_api_call(:delete, "channels/#{channel_id}")
  end

  defp make_discord_api_call(method, route),
    do:
      :httpc.request(
        method,
        {
          'https://discord.com/api/#{route}',
          [
            make_authorization_header()
          ]
        },
        [],
        []
      )

  defp make_discord_api_call(method, route, body),
    do:
      :httpc.request(
        method,
        {
          'https://discord.com/api/#{route}',
          [
            make_authorization_header()
          ],
          'application/json',
          body
          |> Jason.encode!()
          |> String.to_charlist()
        },
        [],
        []
      )

  defp make_authorization_header() do
    bot_token = Application.get_env(:chessh, DiscordNotifications)[:discord_bot_token]
    {'Authorization', 'Bot #{bot_token}'}
  end
end
