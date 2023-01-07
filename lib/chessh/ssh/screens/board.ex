defmodule Chessh.SSH.Client.Board do
  alias Chessh.SSH.Client
  alias IO.ANSI

  require Logger

  defmodule State do
    defstruct cursor_x: 0,
              cursor_y: 0
  end

  use Chessh.SSH.Client.Screen

  @chess_board_height 8
  @chess_board_width 8

  @dark_piece_color ANSI.magenta()
  @light_piece_color ANSI.red()

  def tileIsLight(row, col) do
    rem(row, 2) == rem(col, 2)
  end

  def piece_type(char) do
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

  def make_board({tile_width, tile_height}) do
    rows =
      Enum.map(0..(@chess_board_height - 1), fn i ->
        Enum.map(0..(@chess_board_width - 1), fn j ->
          List.duplicate(if(tileIsLight(i, j), do: ' ', else: '▊'), tile_width)
        end)
        |> Enum.join("")
      end)

    Enum.flat_map(rows, fn row -> Enum.map(1..tile_height, fn _ -> row end) end)
  end

  defp skip_cols_or_place_piece_reduce(char, {curr_column, data}, rowI) do
    case Integer.parse(char) do
      {skip, ""} ->
        {curr_column + skip, data}

      _ ->
        case piece_type(char) do
          nil ->
            {curr_column, data}

          type ->
            shade = if(char != String.capitalize(char), do: "dark", else: "light")

            {curr_column + 1,
             Map.put(
               data,
               "#{rowI}, #{curr_column}",
               {shade, type}
             )}
        end
    end
  end

  defp make_coordinate_to_piece_art_map(fen) do
    rows =
      String.split(fen, " ")
      |> List.first()
      |> String.split("/")

    Enum.zip(rows, 0..(length(rows) - 1))
    |> Enum.map(fn {row, rowI} ->
      {@chess_board_height, pieces_per_row} =
        Enum.reduce(
          String.split(row, ""),
          {0, %{}},
          &skip_cols_or_place_piece_reduce(&1, &2, rowI)
        )

      pieces_per_row
    end)
    |> Enum.reduce(%{}, fn pieces_map_for_this_row, acc ->
      Map.merge(acc, pieces_map_for_this_row)
    end)
  end

  def make_board(fen, {tile_width, tile_height} = tile_dims) do
    coordinate_to_piece = make_coordinate_to_piece_art_map(fen)
    board = make_board(tile_dims)

    Enum.zip_with([board, 0..(length(board) - 1)], fn [rowStr, row] ->
      curr_y = div(row, tile_height)

      %{row_chars: row_chars} =
        Enum.reduce(
          Enum.zip(String.graphemes(rowStr), 0..(String.length(rowStr) - 1)),
          %{current_color: ANSI.black(), row_chars: []},
          fn {char, col}, %{current_color: current_color, row_chars: row_chars} = row_state ->
            curr_x = div(col, tile_width)
            key = "#{curr_y}, #{curr_x}"

            case Map.fetch(coordinate_to_piece, key) do
              {:ok, {shade, type}} ->
                piece = @ascii_chars["pieces"][shade][type]
                piece_line = Enum.at(piece, row - curr_y * tile_height)

                piece_line_len = String.length(piece_line)
                pad_left_right = div(tile_width - piece_line_len, 2)
                relative_to_tile_col = col - curr_x * tile_width

                if relative_to_tile_col >= pad_left_right &&
                     relative_to_tile_col < tile_width - pad_left_right do
                  piece_char = String.at(piece_line, relative_to_tile_col - pad_left_right)
                  new_char = if piece_char == " ", do: char, else: piece_char

                  color =
                    if piece_char == " ",
                      do: ANSI.default_color(),
                      else: if(shade == "dark", do: @dark_piece_color, else: @light_piece_color)

                  if color != current_color do
                    %{
                      row_state
                      | current_color: color,
                        row_chars: row_chars ++ [color, new_char]
                    }
                  else
                    %{
                      row_state
                      | current_color: current_color,
                        row_chars: row_chars ++ [new_char]
                    }
                  end
                else
                  %{
                    row_state
                    | current_color: ANSI.default_color(),
                      row_chars: row_chars ++ [ANSI.default_color(), char]
                  }
                end

              _ ->
                if ANSI.white() != current_color do
                  %{
                    row_state
                    | current_color: ANSI.default_color(),
                      row_chars: row_chars ++ [ANSI.default_color(), char]
                  }
                else
                  %{
                    row_state
                    | row_chars: row_chars ++ [char]
                  }
                end
            end
          end
        )

      row_chars
      |> Enum.join("")
    end)
  end

  def render(%Client.State{} = _state) do
    board = make_board("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", {7, 4})

    [ANSI.home()] ++
      Enum.map(
        Enum.zip(1..length(board), board),
        fn {i, line} ->
          [ANSI.cursor(i, 0), line]
        end
      )
  end

  def handle_input(action, %Client.State{} = state) do
    case action do
      _ -> state
    end
  end
end
