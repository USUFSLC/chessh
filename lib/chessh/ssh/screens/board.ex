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

  def make_board(fen, {tile_width, tile_height} = tile_dims) do
    rows =
      String.split(fen, " ")
      |> List.first()
      |> String.split("/")

    coordinate_to_piece =
      Enum.zip(rows, 0..(length(rows) - 1))
      |> Enum.map(fn {row, rowI} ->
        {@chess_board_height, pieces_per_row} =
          Enum.reduce(
            String.split(row, ""),
            {0, %{}},
            fn char, {curr_column, data} ->
              case Integer.parse(char) do
                {skip, ""} ->
                  {curr_column + skip, data}

                _ ->
                  case piece_type(char) do
                    nil ->
                      {curr_column, data}

                    type ->
                      {curr_column + 1,
                       Map.put(
                         data,
                         "#{rowI}, #{curr_column}",
                         @ascii_chars["pieces"][
                           if(char != String.capitalize(char), do: "dark", else: "light")
                         ][type]
                       )}
                  end
              end
            end
          )

        pieces_per_row
      end)
      |> Enum.reduce(%{}, fn pieces_map_for_this_row, acc ->
        Map.merge(acc, pieces_map_for_this_row)
      end)

    board = make_board(tile_dims)

    Enum.zip_with([board, 0..(length(board) - 1)], fn [rowStr, row] ->
      curr_y = div(row, tile_height)

      Enum.zip_with([String.graphemes(rowStr), 0..(String.length(rowStr) - 1)], fn [char, col] ->
        curr_x = div(col, tile_width)
        key = "#{curr_y}, #{curr_x}"

        if Map.has_key?(coordinate_to_piece, key) do
          piece_row =
            Map.fetch!(coordinate_to_piece, key)
            |> Enum.at(row - curr_y * tile_height)

          piece_row_len = String.length(piece_row)
          centered_col = div(tile_width - piece_row_len, 2)
          relative_to_tile_col = col - curr_x * tile_width
          Logger.debug("#{piece_row_len}, #{centered_col}, #{relative_to_tile_col}")

          piece_char =
            if relative_to_tile_col >= centered_col &&
                 relative_to_tile_col <= tile_width - centered_col - 1,
               do: String.at(piece_row, relative_to_tile_col - centered_col),
               else: " "

          if piece_char == " ",
            do: char,
            else: piece_char
        else
          char
        end
      end)
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
