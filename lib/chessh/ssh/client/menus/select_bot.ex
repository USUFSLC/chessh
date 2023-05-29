defmodule Chessh.SSH.Client.SelectBot do
  alias Chessh.{Utils, Bot, Repo, Game}
  alias Chessh.SSH.Client.Selector
  import Ecto.Query
  require Logger

  use Chessh.SSH.Client.SelectPaginatePoller

  def refresh_options_ms(), do: 4000
  def max_displayed_options(), do: 5
  def title(), do: ["-- Select Bot To Play Against --"]
  def dynamic_options(), do: true

  def get_bots(player_id, current_id \\ nil, direction \\ :desc) do
    Selector.paginate_ish_query(
      Bot
      |> where([b], b.player_id == ^player_id or b.public == true)
      |> limit(^max_displayed_options()),
      current_id,
      direction
    )
  end

  def format_bot_tuple(%Bot{id: id, name: name}), do: {name, id}

  def next_page_options(%State{
        options: options,
        player_session: %PlayerSession{
          player_id: player_id
        }
      }) do
    {_label, previous_last_bot_id} = List.last(options)
    next_bots = get_bots(player_id, previous_last_bot_id, :desc)

    if length(next_bots) > 0,
      do:
        next_bots
        |> Enum.map(&format_bot_tuple/1),
      else: options
  end

  def previous_page_options(%State{
        options: options,
        player_session: %PlayerSession{player_id: player_id}
      }) do
    {_label, previous_first_bot_id} = List.first(options)

    previous_bots = get_bots(player_id, previous_first_bot_id, :asc)

    if length(previous_bots) > 0,
      do:
        previous_bots
        |> Enum.map(&format_bot_tuple/1),
      else: options
  end

  def initial_options(%State{
        player_session: %PlayerSession{player_id: player_id}
      }) do
    get_bots(player_id)
    |> Enum.map(&format_bot_tuple/1)
  end

  def refresh_options(%State{
        options: options,
        player_session: %PlayerSession{player_id: player_id}
      }) do
    previous_last_bot_id =
      case List.last(options) do
        {_name, id} -> id
        _ -> 1
      end

    current_screen_games = get_bots(player_id, previous_last_bot_id - 1, :asc)

    if !is_nil(current_screen_games) && length(current_screen_games),
      do:
        current_screen_games
        |> Enum.map(&format_bot_tuple/1),
      else: options
  end

  def make_process_tuple(selected_id, %State{
        player_session: player_session,
        extra_info: %{color: color}
      }) do
    [create_game_ms, create_game_rate] =
      Application.get_env(:chessh, RateLimits)
      |> Keyword.take([:create_game_ms, :create_game_rate])
      |> Keyword.values()

    case Hammer.check_rate_inc(
           :redis,
           "player-#{player_session.player_id}-create-game-rate",
           create_game_ms,
           create_game_rate,
           1
         ) do
      {:allow, _count} ->
        {:ok, game} =
          Game.changeset(
            Game.new_game(color, player_session.player_id),
            %{
              bot_id: selected_id
            }
          )
          |> Repo.insert()

        spawn(fn -> Bot.send_update(game |> Repo.preload([:bot])) end)

        {Chessh.SSH.Client.Game,
         %Chessh.SSH.Client.Game.State{player_session: player_session, color: color, game: game}}

      {:deny, _limit} ->
        {Chessh.SSH.Client.MainMenu,
         %Chessh.SSH.Client.SelectPaginatePoller.State{player_session: player_session}}
    end
  end
end
