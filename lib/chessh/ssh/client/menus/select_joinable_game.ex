defmodule Chessh.SSH.Client.SelectJoinableGame do
  alias Chessh.{Utils, Repo, Game, PlayerSession}
  alias Chessh.SSH.Client.Selector
  import Ecto.Query
  require Logger

  use Chessh.SSH.Client.SelectPaginatePoller

  def refresh_options_ms(), do: 4000
  def max_displayed_options(), do: 10
  def tick_delay_ms(), do: 600
  def title(), do: ["-- Joinable Games --"]
  def dynamic_options(), do: true

  def get_player_joinable_games_with_id(player_id, current_id \\ nil, direction \\ :desc) do
    Selector.paginate_ish_query(
      Game
      |> where([g], g.status == :continue)
      |> where(
        [g],
        (is_nil(g.dark_player_id) or is_nil(g.light_player_id)) and
          (g.dark_player_id != ^player_id or g.light_player_id != ^player_id) and
          is_nil(g.bot_id)
      )
      |> limit(^max_displayed_options()),
      current_id,
      direction
    )
    |> Repo.preload([:light_player, :dark_player, :bot])
  end

  def format_game_selection_tuple(%Game{id: game_id} = game) do
    {Chessh.SSH.Client.Game.Renderer.make_status_line(game, false), game_id}
  end

  def next_page_options(%State{
        options: options,
        player_session: %PlayerSession{player_id: player_id}
      }) do
    {_label, previous_last_game_id} = List.last(options)
    next_games = get_player_joinable_games_with_id(player_id, previous_last_game_id, :desc)

    if !is_nil(next_games) && length(next_games) > 0,
      do:
        next_games
        |> Enum.map(&format_game_selection_tuple/1),
      else: options
  end

  def previous_page_options(%State{
        options: options,
        player_session: %PlayerSession{player_id: player_id}
      }) do
    {_label, previous_first_game_id} = List.first(options)

    previous_games = get_player_joinable_games_with_id(player_id, previous_first_game_id, :asc)

    if !is_nil(previous_games) && length(previous_games) > 0,
      do:
        previous_games
        |> Enum.map(&format_game_selection_tuple/1),
      else: options
  end

  def initial_options(%State{player_session: %PlayerSession{player_id: player_id}}) do
    Logger.info(player_id)

    get_player_joinable_games_with_id(player_id)
    |> Enum.map(&format_game_selection_tuple/1)
  end

  def refresh_options(%State{
        options: options,
        player_session: %PlayerSession{player_id: player_id}
      }) do
    previous_last_game_id =
      case List.last(options) do
        {_label, id} -> id
        _ -> 1
      end

    current_screen_games =
      get_player_joinable_games_with_id(player_id, previous_last_game_id - 1, :asc)

    if !is_nil(current_screen_games) && length(current_screen_games),
      do:
        current_screen_games
        |> Enum.map(&format_game_selection_tuple/1),
      else: options
  end

  def make_process_tuple(selected_id, %State{
        player_session: player_session
      }) do
    game = Repo.get(Game, selected_id)

    {Chessh.SSH.Client.Game,
     %Chessh.SSH.Client.Game.State{
       player_session: player_session,
       game: game
     }}
  end
end
