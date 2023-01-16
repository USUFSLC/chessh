defmodule Chessh.SSH.Client.Game do
  require Logger
  alias Chessh.{Game, Utils, Repo}
  alias Chessh.SSH.Client.Game.Renderer

  @default_fen "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

  defmodule State do
    defstruct cursor: %{x: 7, y: 7},
              highlighted: %{},
              move_from: nil,
              game: nil,
              client_pid: nil,
              binbo_pid: nil,
              width: 0,
              height: 0,
              flipped: false,
              color: nil,
              player_session: nil
  end

  use Chessh.SSH.Client.Screen

  defp initialize_game(game_id, fen) do
    :syn.add_node_to_scopes([:games])
    :ok = :syn.join(:games, {:game, game_id}, self())

    :binbo.start()
    {:ok, binbo_pid} = :binbo.new_server()
    :binbo.new_game(binbo_pid, fen)

    binbo_pid
  end

  def init([
        %State{
          color: color,
          game: %Game{dark_player_id: dark_player_id, light_player_id: light_player_id}
        } = state
        | tail
      ])
      when is_nil(color) do
    new_state =
      case {is_nil(dark_player_id), is_nil(light_player_id)} do
        {true, false} -> %State{state | color: :dark}
        {false, true} -> %State{state | color: :light}
        {_, _} -> %State{state | color: Enum.random([:light, :dark])}
      end

    init([new_state | tail])
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
              light_player_id: light_player_id
            } = game
        } = state
        | _
      ]) do
    maybe_changeset =
      case color do
        :light ->
          if !light_player_id,
            do: Game.changeset(game, %{light_player_id: player_session.player_id})

        :dark ->
          if !dark_player_id,
            do: Game.changeset(game, %{dark_player_id: player_session.player_id})
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
    end

    binbo_pid = initialize_game(game_id, fen)
    send(client_pid, {:send_to_ssh, Utils.clear_codes()})

    new_game = Repo.get(Game, game_id) |> Repo.preload([:light_player, :dark_player])

    new_state = %State{
      state
      | binbo_pid: binbo_pid,
        color: if(new_game.light_player_id == player_session.player_id, do: :light, else: :dark),
        game: new_game
    }

    Logger.debug("asdfaldfjalsdkfjal #{inspect(new_state)}")
    {:ok, new_state}
  end

  def init([
        %State{player_session: player_session, color: color, client_pid: client_pid, game: nil} =
          state
        | _
      ]) do
    {:ok, %Game{id: game_id, fen: fen}} =
      Game.changeset(
        %Game{},
        Map.merge(
          if(color == :light,
            do: %{light_player_id: player_session.player_id},
            else: %{dark_player_id: player_session.player_id}
          ),
          %{
            fen: @default_fen,
            increment_sec: 3,
            light_clock_ms: 5 * 60 * 1000,
            dark_clock_ms: 5 * 60 * 1000
          }
        )
      )
      |> Repo.insert()

    binbo_pid = initialize_game(game_id, fen)
    send(client_pid, {:send_to_ssh, Utils.clear_codes()})

    {:ok,
     %State{
       state
       | game: Repo.get(Game, game_id) |> Repo.preload([:light_player, :dark_player]),
         binbo_pid: binbo_pid
     }}
  end

  def handle_info(
        {:new_move, move},
        %State{game: %Game{id: game_id}, client_pid: client_pid, binbo_pid: binbo_pid} = state
      ) do
    :binbo.move(binbo_pid, move)

    new_state = %State{
      state
      | game: Repo.get(Game, game_id) |> Repo.preload([:light_player, :dark_player])
    }

    send(client_pid, {:send_to_ssh, render_state(new_state)})

    {:noreply, new_state}
  end

  def handle_info(
        :player_joined,
        %State{client_pid: client_pid, game: %Game{id: game_id}} = state
      ) do
    game = Repo.get(Game, game_id) |> Repo.preload([:light_player, :dark_player])
    new_state = %State{state | game: game}
    send(client_pid, {:send_to_ssh, render_state(new_state)})
    {:noreply, new_state}
  end

  def input(
        width,
        height,
        action,
        %State{
          move_from: move_from,
          cursor: %{x: cursor_x, y: cursor_y} = cursor,
          client_pid: client_pid,
          flipped: flipped
        } = state
      ) do
    new_cursor =
      case action do
        :left -> %{y: cursor_y, x: Utils.wrap_around(cursor_x, -1, Renderer.chess_board_width())}
        :right -> %{y: cursor_y, x: Utils.wrap_around(cursor_x, 1, Renderer.chess_board_width())}
        :down -> %{y: Utils.wrap_around(cursor_y, 1, Renderer.chess_board_height()), x: cursor_x}
        :up -> %{y: Utils.wrap_around(cursor_y, -1, Renderer.chess_board_height()), x: cursor_x}
        _ -> cursor
      end

    {new_move_from, move_to} =
      if action == :return do
        coords = {new_cursor.y, new_cursor.x}

        case move_from do
          nil -> {coords, nil}
          _ -> {nil, coords}
        end
      else
        {move_from, nil}
      end

    if move_from && move_to do
      attempt_move(move_from, move_to, state)
    end

    new_state = %State{
      state
      | cursor: new_cursor,
        move_from: new_move_from,
        highlighted: %{
          {new_cursor.y, new_cursor.x} => Renderer.to_select_background(),
          new_move_from => Renderer.from_select_background()
        },
        width: width,
        height: height,
        flipped: if(action == "f", do: !flipped, else: flipped)
    }

    send(client_pid, {:send_to_ssh, render_state(new_state)})
    new_state
  end

  def render(width, height, %State{client_pid: client_pid} = state) do
    new_state = %State{state | width: width, height: height}
    send(client_pid, {:send_to_ssh, render_state(new_state)})
    new_state
  end

  defp attempt_move(
         from,
         to,
         %State{
           game: %Game{id: game_id, turn: turn},
           binbo_pid: binbo_pid,
           flipped: flipped,
           color: turn
         }
       ) do
    attempted_move =
      if flipped,
        do: "#{Renderer.to_chess_coord(flip(from))}#{Renderer.to_chess_coord(flip(to))}",
        else: "#{Renderer.to_chess_coord(from)}#{Renderer.to_chess_coord(to)}"

    case :binbo.move(binbo_pid, attempted_move) do
      {:ok, :continue} ->
        {:ok, fen} = :binbo.get_fen(binbo_pid)
        game = Repo.get(Game, game_id)

        {:ok, _new_game} =
          Game.changeset(game, %{
            fen: fen,
            moves: game.moves + 1,
            turn: if(game.turn == :dark, do: :light, else: :dark),
            last_move: DateTime.utc_now()
          })
          |> Repo.update()

        :syn.publish(:games, {:game, game_id}, {:new_move, attempted_move})

      _ ->
        nil
    end
  end

  defp attempt_move(_, _, _) do
    Logger.debug("No matching clause for move attempt - must be illegal?")
    nil
  end

  defp flip({y, x}),
    do: {Renderer.chess_board_height() - 1 - y, Renderer.chess_board_width() - 1 - x}

  defp render_state(
         %State{
           game: %Game{fen: fen}
         } = state
       ) do
    Renderer.render_board_state(fen, state)
  end
end
