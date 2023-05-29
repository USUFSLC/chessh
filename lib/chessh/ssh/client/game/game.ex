defmodule Chessh.SSH.Client.Game do
  require Logger
  alias Chessh.{Game, Utils, Repo, Bot}
  alias Chessh.SSH.Client.Game.Renderer

  defmodule State do
    defstruct cursor: %{x: 7, y: 7},
              highlighted: %{},
              move_from: nil,
              game: nil,
              client_pid: nil,
              binbo_pid: nil,
              flipped: false,
              color: nil,
              player_session: nil
  end

  use Chessh.SSH.Client.Screen

  defp initialize_game(game_id, fen) do
    :syn.add_node_to_scopes([:games])
    :ok = :syn.join(:games, {:game, game_id}, self())

    {:ok, binbo_pid} = :binbo.new_server()
    :binbo.new_game(binbo_pid, fen)

    binbo_pid
  end

  def init([
        %State{
          color: color,
          game: %Game{
            dark_player_id: dark_player_id,
            light_player_id: light_player_id
          },
          player_session: %{player_id: player_id}
        } = state
        | tail
      ])
      when is_nil(color) do
    # Joining a game
    {is_dark, is_light} = {player_id == dark_player_id, player_id == light_player_id}

    new_state =
      if is_dark || is_light do
        %State{state | color: if(is_light, do: :light, else: :dark)}
      else
        case {is_nil(dark_player_id), is_nil(light_player_id)} do
          {true, false} -> %State{state | color: :dark}
          {_, _} -> %State{state | color: :light}
        end
      end

    init([new_state | tail])
  end

  def init([
        %State{player_session: player_session, color: color, game: nil, client_pid: client_pid} =
          state
        | tail
      ]) do
    [create_game_ms, create_game_rate] =
      Application.get_env(:chessh, RateLimits)
      |> Keyword.take([:create_game_ms, :create_game_rate])
      |> Keyword.values()

    case Hammer.check_rate_inc(
           :redis,
           "player-#{state.player_session.player_id}-create-game-rate",
           create_game_ms,
           create_game_rate,
           1
         ) do
      {:allow, _count} ->
        game = Game.new_game(color, player_session.player_id) |> Repo.insert!()
        %Game{id: game_id} = game

        GenServer.cast(
          :discord_notifier,
          {:schedule_notification, {:game_created, game_id},
           Application.get_env(:chessh, DiscordNotifications)[:game_created_notif_delay_ms]}
        )

        init([
          %State{
            state
            | game: game
          }
          | tail
        ])

      {:deny, _limit} ->
        send(
          client_pid,
          {:send_to_ssh,
           [
             Utils.clear_codes(),
             "You are creating too many games, and have been rate limited. Try again later.\n"
           ]}
        )

        {:stop, :normal, state}
    end
  end

  def init([
        %State{
          player_session: player_session,
          color: color,
          client_pid: client_pid,
          game:
            %Game{
              id: game_id,
              fen: fen,
              dark_player_id: dark_player_id,
              light_player_id: light_player_id,
              bot_id: bot_id
            } = game
        } = state
        | _
      ]) do
    maybe_changeset =
      if !bot_id do
        case(color) do
          :light ->
            if !light_player_id,
              do: Game.changeset(game, %{light_player_id: player_session.player_id})

          :dark ->
            if !dark_player_id,
              do: Game.changeset(game, %{dark_player_id: player_session.player_id})
        end
      end

    {status, maybe_joined_game} =
      if maybe_changeset do
        maybe_changeset
        |> Repo.update()
      else
        {:undefined, nil}
      end

    if status == :ok && maybe_joined_game do
      :syn.publish(:games, {:game, game_id}, :player_joined)

      GenServer.cast(
        :discord_notifier,
        {:schedule_notification, {:player_joined, game_id},
         Application.get_env(:chessh, DiscordNotifications)[:game_player_joined_notif_delay_ms]}
      )
    end

    binbo_pid = initialize_game(game_id, fen)
    game = Repo.get(Game, game_id) |> Repo.preload([:light_player, :dark_player, :bot])

    player_color = if(game.light_player_id == player_session.player_id, do: :light, else: :dark)

    new_state =
      (fn new_state ->
         %State{
           new_state
           | highlighted: make_highlight_map(new_state)
         }
       end).(%State{
        state
        | binbo_pid: binbo_pid,
          color: player_color,
          game: game,
          flipped: player_color == :dark
      })

    # Clear screen and do initial render
    send(client_pid, {:send_to_ssh, Utils.clear_codes()})
    render(new_state)
    {:ok, new_state}
  end

  def handle_info(
        {:new_move, move},
        %State{
          game: %Game{id: game_id},
          client_pid: client_pid,
          binbo_pid: binbo_pid
        } = state
      ) do
    :binbo.move(binbo_pid, move)

    new_state =
      (fn new_state ->
         %State{
           new_state
           | highlighted: make_highlight_map(new_state)
         }
       end).(%State{
        state
        | game: Repo.get(Game, game_id) |> Repo.preload([:light_player, :dark_player, :bot])
      })

    send(client_pid, {:send_to_ssh, Renderer.render_board_state(new_state)})

    {:noreply, new_state}
  end

  def handle_info(
        :player_joined,
        %State{client_pid: client_pid, game: %Game{id: game_id}} = state
      ) do
    game = Repo.get(Game, game_id) |> Repo.preload([:light_player, :dark_player, :bot])
    new_state = %State{state | game: game}
    send(client_pid, {:send_to_ssh, Renderer.render_board_state(new_state)})
    {:noreply, new_state}
  end

  def handle_info(x, state) do
    Logger.debug("unknown message in game process #{inspect(x)}")
    {:noreply, state}
  end

  def input(
        _width,
        _height,
        action,
        %State{
          move_from: move_from,
          cursor: %{x: cursor_x, y: cursor_y} = cursor,
          client_pid: client_pid,
          flipped: flipped,
          binbo_pid: binbo_pid,
          color: color
        } = state
      ) do
    new_cursor =
      case action do
        :left ->
          %{y: cursor_y, x: Utils.wrap_around(cursor_x, -1, Renderer.chess_board_width())}

        :right ->
          %{y: cursor_y, x: Utils.wrap_around(cursor_x, 1, Renderer.chess_board_width())}

        :down ->
          %{y: Utils.wrap_around(cursor_y, 1, Renderer.chess_board_height()), x: cursor_x}

        :up ->
          %{y: Utils.wrap_around(cursor_y, -1, Renderer.chess_board_height()), x: cursor_x}

        _ ->
          cursor
      end

    maybe_flipped_cursor_tup =
      if flipped,
        do: Renderer.flip({new_cursor.y, new_cursor.x}),
        else: {new_cursor.y, new_cursor.x}

    {new_move_from, move_to} =
      if action == :return do
        coords = {new_cursor.y, new_cursor.x}

        case move_from do
          nil ->
            if :binbo_position.get_piece(
                 :binbo_board.notation_to_index(
                   Renderer.to_chess_coord(maybe_flipped_cursor_tup)
                 ),
                 :binbo.game_state(binbo_pid)
               ) == 0 do
              {move_from, nil}
            else
              {coords, nil}
            end

          _ ->
            {nil, coords}
        end
      else
        {move_from, nil}
      end

    new_state =
      (fn new_state ->
         %State{
           new_state
           | highlighted:
               make_highlight_map(new_state, %{
                 {new_cursor.y, new_cursor.x} => Renderer.to_select_background(),
                 new_move_from => Renderer.from_select_background()
               })
         }
       end).(%State{
        state
        | cursor: new_cursor,
          move_from: new_move_from,
          flipped: if(action == "f", do: !flipped, else: flipped)
      })

    if move_from && move_to do
      [maybe_flipped_to, maybe_flipped_from] =
        [move_to, move_from]
        |> Enum.map(fn coord -> if flipped, do: Renderer.flip(coord), else: coord end)

      promotion_possible =
        case :binbo_position.get_piece(
               :binbo_board.notation_to_index(Renderer.to_chess_coord(maybe_flipped_from)),
               :binbo.game_state(binbo_pid)
             ) do
          1 ->
            # Light pawn
            {y, _} = maybe_flipped_to
            y == 0 && color == :light

          17 ->
            # Dark pawn
            {y, _} = maybe_flipped_to
            y == Renderer.chess_board_height() - 1 && color == :dark

          _ ->
            false
        end

      if promotion_possible do
        send(
          client_pid,
          {:set_screen_process, Chessh.SSH.Client.Game.PromotionScreen,
           %Chessh.SSH.Client.Game.PromotionScreen.State{
             client_pid: client_pid,
             game_pid: self(),
             game_state: new_state
           }}
        )

        receive do
          {:promotion, promotion} ->
            attempt_move(move_from, move_to, state, promotion)
        end
      else
        attempt_move(move_from, move_to, state)
      end
    end

    render(new_state)
    new_state
  end

  defp attempt_move(
         from,
         to,
         %State{} = state
       ),
       do: attempt_move(from, to, state, nil)

  defp attempt_move(
         from,
         to,
         %State{
           game: %Game{game_moves: game_moves, id: game_id, turn: turn},
           binbo_pid: binbo_pid,
           flipped: flipped,
           color: turn
         },
         promotion
       ) do
    game = Repo.get(Game, game_id)

    [from, to] =
      [from, to]
      |> Enum.map(fn coord -> if flipped, do: Renderer.flip(coord), else: coord end)
      |> Enum.map(&Renderer.to_chess_coord/1)

    attempted_move =
      from <>
        to <>
        if(promotion, do: promotion, else: "")

    case :binbo.move(
           binbo_pid,
           attempted_move
         ) do
      {:ok, status} ->
        {:ok, fen} = :binbo.get_fen(binbo_pid)

        {:ok, %Game{status: after_move_status} = game} =
          game
          |> Game.update_with_status(attempted_move, fen, status)
          |> Repo.update()

        if !is_nil(game.bot) do
          spawn(fn -> Bot.send_update(Repo.get(Game, game.id) |> Repo.preload([:bot])) end)
        end

        :syn.publish(:games, {:game, game_id}, {:new_move, attempted_move})

        if after_move_status == :continue do
          GenServer.cast(
            :discord_notifier,
            {:schedule_notification, {:move_reminder, game_id},
             Application.get_env(:chessh, DiscordNotifications)[:game_move_notif_delay_ms]}
          )
        else
          GenServer.cast(
            :discord_notifier,
            {:schedule_notification, {:cleanup_thread, game_id}, 0}
          )
        end

      _ ->
        nil
    end
  end

  defp attempt_move(_, _, _, _) do
    Logger.debug("No matching clause for move attempt - must be illegal?")

    nil
  end

  defp make_highlight_map(
         %State{
           game: %Game{last_move: last_move, turn: turn},
           binbo_pid: binbo_pid,
           flipped: flipped
         },
         extra_highlights \\ %{}
       ) do
    if last_move do
      [prev_move_from, prev_move_to] =
        [String.slice(last_move, 0..1), String.slice(last_move, 2..4)]
        |> Enum.map(fn coord -> Renderer.from_chess_coord(coord, flipped) end)

      binbo_bin_color = if(turn == :light, do: 0, else: 16)
      binbo_atom_color = if(turn == :light, do: :white, else: :black)

      check_highlight =
        if :binbo_position.is_in_check(binbo_bin_color, :binbo.game_state(binbo_pid)) do
          {:ok, pieces_list} = :binbo.get_pieces_list(binbo_pid, :notation)

          {king_square, _, _} =
            Enum.find(pieces_list, fn piece ->
              case piece do
                {_, ^binbo_atom_color, :king} -> true
                _ -> false
              end
            end)

          %{Renderer.from_chess_coord(king_square, flipped) => Renderer.in_check_color()}
        else
          %{}
        end

      Map.merge(
        %{
          prev_move_from => Renderer.previous_move_background(),
          prev_move_to => Renderer.previous_move_background()
        },
        check_highlight
      )
    else
      %{}
    end
    |> Map.merge(extra_highlights)
  end

  def render(_width, _height, %State{} = state), do: render(state)

  def render(%State{client_pid: client_pid} = state) do
    send(client_pid, {:send_to_ssh, Renderer.render_board_state(state)})
    state
  end
end
