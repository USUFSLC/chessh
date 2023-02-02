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
           "discord-webhook-message-rate",
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
    [min_delta_t, discord_game_move_notif_webhook] =
      Application.get_env(:chessh, DiscordNotifications)
      |> Keyword.take([:game_move_notif_delay_ms, :discord_game_move_notif_webhook])
      |> Keyword.values()

    case Repo.get(Game, game_id) |> Repo.preload([:dark_player, :light_player]) do
      %Game{
        dark_player: %Player{discord_id: dark_player_discord_id},
        light_player: %Player{discord_id: light_player_discord_id},
        turn: turn,
        updated_at: last_updated,
        moves: move_count,
        status: :continue
      } ->
        delta_t = NaiveDateTime.diff(NaiveDateTime.utc_now(), last_updated, :millisecond)

        if delta_t >= min_delta_t do
          post_discord(
            discord_game_move_notif_webhook,
            "<@#{if turn == :light, do: light_player_discord_id, else: dark_player_discord_id}> it is your move in Game #{game_id} (move #{move_count})."
          )
        end

      _ ->
        nil
    end
  end

  defp send_notification({:game_created, game_id}) do
    [pingable_mention, discord_game_created_notif_webhook] =
      Application.get_env(:chessh, DiscordNotifications)
      |> Keyword.take([:looking_for_games_role_mention, :discord_new_game_notif_webhook])
      |> Keyword.values()

    case Repo.get(Game, game_id) do
      nil ->
        nil

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
          post_discord(discord_game_created_notif_webhook, message)
        end
    end
  end

  defp post_discord(webhook, message) do
    :httpc.request(
      :post,
      {
        String.to_charlist(webhook),
        [],
        'application/json',
        %{content: message} |> Jason.encode!() |> String.to_charlist()
      },
      [],
      []
    )
  end
end
