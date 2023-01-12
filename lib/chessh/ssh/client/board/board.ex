defmodule Chessh.SSH.Client.Board do
  alias IO.ANSI
  require Logger

  @chess_board_height 8
  @chess_board_width 8
  @tile_width 7
  @tile_height 4

  @dark_piece_color ANSI.magenta()
  @light_piece_color ANSI.red()
  @from_select_background ANSI.green_background()
  @to_select_background ANSI.blue_background()

  defmodule State do
    defstruct cursor: %{x: 0, y: 0},
              highlighted: %{},
              move_from: nil,
              game_id: nil,
              client_pid: nil
  end

  use Chessh.SSH.Client.Screen

  def init([%State{game_id: game_id} = state | _]) do
    :syn.add_node_to_scopes([:games])
    :ok = :syn.join(:games, {:game, game_id}, self())

    {:ok, state}
  end

  def handle_info({:attempted_move, move}, %State{client_pid: client_pid} = state) do
    send(client_pid, {:send_to_ssh, ["hello, world!"]})
    {:noreply, state}
  end

  def input(
        width,
        height,
        action,
        %State{
          move_from: move_from,
          game_id: game_id,
          cursor: %{x: cursor_x, y: cursor_y} = cursor,
          client_pid: client_pid
        } = state
      ) do
    new_cursor =
      case action do
        :left -> %{y: cursor_y, x: cursor_x - 1}
        :right -> %{y: cursor_y, x: cursor_x + 1}
        :down -> %{y: cursor_y + 1, x: cursor_x}
        :up -> %{y: cursor_y - 1, x: cursor_x}
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
      attempted_move = "#{to_chess_coord(move_from)}#{to_chess_coord(move_to)}"
      :syn.publish(:games, {:game, game_id}, {:new_move, attempted_move})
    end

    new_state = %State{
      state
      | cursor: new_cursor,
        move_from: new_move_from,
        highlighted: %{
          new_move_from => @from_select_background,
          {new_cursor.y, new_cursor.x} => @to_select_background
        }
    }

    send(client_pid, {:send_to_ssh, render_state(width, height, new_state)})
    new_state
  end

  def render(width, height, %State{client_pid: client_pid} = state) do
    send(client_pid, {:send_to_ssh, render_state(width, height, state)})
    state
  end

  defp render_state(width, height, %State{} = _state) do
    [ANSI.clear(), "#{width}#{height}"]
  end

  defp to_chess_coord({y, x})
       when x >= 0 and x < @chess_board_width and y >= 0 and y < @chess_board_height do
    "#{List.to_string([?a + x])}#{y + 1}"
  end

  defp piece_type(char) do
    case String.capitalize(char) do
      "P" -> "pawn"
      "N" -> "knight"
      "R" -> "rook"
      "B" -> "bishop"
      "K" -> "king"
      "Q" -> "queen"
      _ -> nil
    end
  end
end
