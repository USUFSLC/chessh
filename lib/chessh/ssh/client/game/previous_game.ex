defmodule Chessh.SSH.Client.PreviousGame do
  @start_fen "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

  alias Chessh.{Game, Utils}
  alias Chessh.SSH.Client.Game.Renderer
  alias IO.ANSI

  require Logger

  defmodule State do
    defstruct move_fens: %{},
              move_idx: 0,
              binbo_pid: nil,
              game: %Game{},
              client_pid: nil,
              flipped: false,
              viewing_uci: false
  end

  use Chessh.SSH.Client.Screen

  def init([
        %State{
          client_pid: client_pid,
          game: %Game{
            game_moves: game_moves
          }
        } = state
      ]) do
    {:ok, binbo_pid} = :binbo.new_server()
    :binbo.new_game(binbo_pid, @start_fen)

    {move_fens, _moves} =
      game_moves
      |> String.trim()
      |> String.split(" ")
      |> Enum.reduce({%{"0" => @start_fen}, 1}, fn move, {move_idx_fen_map, curr_turn} ->
        {:ok, _status} = :binbo.move(binbo_pid, move)
        {:ok, fen} = :binbo.get_fen(binbo_pid)

        {Map.put(move_idx_fen_map, "#{curr_turn}", fen), curr_turn + 1}
      end)

    new_state = %State{
      state
      | binbo_pid: binbo_pid,
        move_fens: move_fens
    }

    send(client_pid, {:send_to_ssh, Utils.clear_codes()})
    render(new_state)

    {:ok, new_state}
  end

  def input(
        action,
        _data,
        %State{
          move_idx: move_idx,
          flipped: flipped,
          viewing_uci: viewing_uci,
          game: %Game{
            moves: num_moves
          }
        } = state
      ) do
    new_move_idx =
      case action do
        :left ->
          Utils.wrap_around(move_idx, -1, num_moves + 1)

        :right ->
          Utils.wrap_around(move_idx, 1, num_moves + 1)

        _ ->
          move_idx
      end

    new_state = %State{
      state
      | move_idx: new_move_idx,
        flipped: if(action == "f", do: !flipped, else: flipped),
        viewing_uci: if(action == "m", do: !viewing_uci, else: viewing_uci)
    }

    render(new_state)
    new_state
  end

  def render(
        %State{
          flipped: flipped,
          client_pid: client_pid,
          move_fens: move_fens,
          move_idx: move_idx,
          game: %Game{id: game_id, moves: total_moves, game_moves: game_moves},
          viewing_uci: viewing_uci
        } = state
      ) do
    lines =
      case viewing_uci do
        false ->
          {:ok, fen} = Map.fetch(move_fens, "#{move_idx}")

          [
            "Game #{game_id} | Move #{move_idx} / #{total_moves}",
            "| <- previous move | next move ->",
            "| press 'm' to view move history",
            "==="
          ] ++
            Renderer.draw_board(fen, flipped)

        true ->
          [
            Utils.clear_codes(),
            "UCI Notation For Game #{game_id}",
            "- Press 'm' to go back to the board",
            "- Use https://dcode.fr/uci-chess-notation to convert to PGN",
            "",
            game_moves
          ]
      end

    send(
      client_pid,
      {:send_to_ssh,
       [ANSI.home()] ++
         Enum.map(
           Enum.zip(1..length(lines), lines),
           fn {i, line} ->
             [ANSI.cursor(i, 0), ANSI.clear_line(), line]
           end
         ) ++ [ANSI.home()]}
    )

    state
  end

  def render(_width, _height, %State{} = state), do: render(state)
end
