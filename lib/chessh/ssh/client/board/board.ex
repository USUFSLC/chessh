defmodule Chessh.SSH.Client.Board do
  require Logger
  alias Chessh.Utils
  alias Chessh.SSH.Client.Board.Renderer

  defmodule State do
    defstruct cursor: %{x: 7, y: 7},
              highlighted: %{},
              move_from: nil,
              game_id: nil,
              client_pid: nil,
              binbo_pid: nil,
              width: 0,
              height: 0,
              flipped: false
  end

  use Chessh.SSH.Client.Screen

  def init([%State{client_pid: client_pid, game_id: game_id} = state | _]) do
    :syn.add_node_to_scopes([:games])
    :ok = :syn.join(:games, {:game, game_id}, self())

    :binbo.start()
    {:ok, binbo_pid} = :binbo.new_server()
    :binbo.new_game(binbo_pid)

    send(client_pid, {:send_to_ssh, Utils.clear_codes()})

    {:ok, %State{state | binbo_pid: binbo_pid}}
  end

  def handle_info({:new_move, move}, %State{binbo_pid: binbo_pid, client_pid: client_pid} = state) do
    case :binbo.move(binbo_pid, move) do
      {:ok, :continue} ->
        send(client_pid, {:send_to_ssh, render_state(state)})

      _ ->
        nil
    end

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

    # TODO: Check move here, then publish new move, subscribers get from DB instead
    if move_from && move_to do
      attempted_move =
        if flipped,
          do:
            "#{Renderer.to_chess_coord(flip(move_from))}#{Renderer.to_chess_coord(flip(move_to))}",
          else: "#{Renderer.to_chess_coord(move_from)}#{Renderer.to_chess_coord(move_to)}"

      :syn.publish(:games, {:game, game_id}, {:new_move, attempted_move})
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
    send(client_pid, {:send_to_ssh, render_state(state)})
    %State{state | width: width, height: height}
  end

  def flip({y, x}),
    do: {Renderer.chess_board_height() - 1 - y, Renderer.chess_board_width() - 1 - x}

  defp render_state(
         %State{
           binbo_pid: binbo_pid
         } = state
       ) do
    {:ok, fen} = :binbo.get_fen(binbo_pid)

    Renderer.render_board_state(fen, state)
  end
end
