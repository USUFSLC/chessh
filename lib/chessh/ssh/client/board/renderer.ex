defmodule Chessh.SSH.Client.Board.Renderer do
  alias IO.ANSI
  alias Chessh.Utils
  alias Chessh.SSH.Client.Board
  require Logger

  @chess_board_height 8
  @chess_board_width 8

  @tile_width 7
  @tile_height 4

  @from_select_background ANSI.light_blue_background()
  @to_select_background ANSI.blue_background()
  @dark_piece_color ANSI.light_red()
  @light_piece_color ANSI.light_magenta()

  def chess_board_height(), do: @chess_board_height
  def chess_board_width(), do: @chess_board_width
  def to_select_background(), do: @to_select_background
  def from_select_background(), do: @from_select_background

  def to_chess_coord({y, x})
      when x >= 0 and x < @chess_board_width and y >= 0 and y < @chess_board_height do
    "#{List.to_string([?a + x])}#{@chess_board_height - y}"
  end

  def render_board_state(fen, %Board.State{
        width: _width,
        height: _height,
        highlighted: highlighted,
        flipped: flipped
      }) do
    board =
      draw_board(
        fen,
        {@tile_width, @tile_height},
        highlighted,
        flipped
      )

    [ANSI.home()] ++
      Enum.map(
        Enum.zip(1..length(board), board),
        fn {i, line} ->
          [ANSI.cursor(i, 0), line]
        end
      )
  end

  defp tileIsLight(row, col) do
    rem(row, 2) == rem(col, 2)
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

  defp skip_cols_or_place_piece_reduce(char, {curr_column, data}, rowI) do
    case Integer.parse(char) do
      {skip, ""} ->
        {curr_column + skip, data}

      _ ->
        case piece_type(char) do
          nil ->
            {curr_column, data}

          type ->
            shade = if(char == String.capitalize(char), do: "light", else: "dark")

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

  defp draw_board(
         fen,
         {tile_width, tile_height} = tile_dims,
         highlights,
         flipped
       ) do
    coordinate_to_piece = make_coordinate_to_piece_art_map(fen)
    board = make_board(tile_dims)

    (Enum.zip_with([board, 0..(length(board) - 1)], fn [row_str, row] ->
       curr_y = div(row, tile_height)

       %{row_chars: row_chars} =
         Enum.reduce(
           Enum.zip(String.graphemes(row_str), 0..(String.length(row_str) - 1)),
           %{current_color: ANSI.black(), row_chars: []},
           fn {char, col}, %{current_color: current_color, row_chars: row_chars} = row_state ->
             curr_x = div(col, tile_width)

             key =
               "#{if !flipped, do: curr_y, else: @chess_board_height - curr_y - 1}, #{if !flipped, do: curr_x, else: @chess_board_width - curr_x - 1}"

             relative_to_tile_col = col - curr_x * tile_width

             prefix =
               if relative_to_tile_col == 0 do
                 case Map.fetch(highlights, {curr_y, curr_x}) do
                   {:ok, color} ->
                     color

                   _ ->
                     ANSI.default_background()
                 end
               end

             {color, row_chars} =
               case Map.fetch(coordinate_to_piece, key) do
                 {:ok, {shade, type}} ->
                   piece = Utils.ascii_chars()["pieces"][shade][type]
                   piece_line = Enum.at(piece, row - curr_y * tile_height)
                   pad_left_right = div(tile_width - String.length(piece_line), 2)

                   if relative_to_tile_col >= pad_left_right &&
                        relative_to_tile_col < tile_width - pad_left_right do
                     piece_char = String.at(piece_line, relative_to_tile_col - pad_left_right)
                     new_char = if piece_char == " ", do: char, else: piece_char

                     color =
                       if piece_char == " ",
                         do: ANSI.default_color(),
                         else:
                           if(shade == "dark", do: @dark_piece_color, else: @light_piece_color)

                     if color != current_color do
                       {color, row_chars ++ [prefix, color, new_char]}
                     else
                       {current_color, row_chars ++ [prefix, new_char]}
                     end
                   else
                     {ANSI.default_color(), row_chars ++ [prefix, ANSI.default_color(), char]}
                   end

                 _ ->
                   if ANSI.default_color() != current_color do
                     {ANSI.default_color(), row_chars ++ [prefix, ANSI.default_color(), char]}
                   else
                     {current_color, row_chars ++ [prefix, char]}
                   end
               end

             %{
               row_state
               | current_color: color,
                 row_chars: row_chars
             }
           end
         )

       curr_num =
         Utils.ascii_chars()["numbers"][
           Integer.to_string(if flipped, do: curr_y + 1, else: @chess_board_height - curr_y)
         ]

       curr_num_line_no = rem(row, @tile_height)

       Enum.join(
         [
           String.pad_trailing(
             if(curr_num_line_no < length(curr_num),
               do: Enum.at(curr_num, curr_num_line_no),
               else: ""
             ),
             @tile_width
           )
         ] ++ row_chars,
         ""
       )
     end) ++ column_coords(flipped))
    |> Enum.map(fn row_line -> "#{ANSI.default_background()}#{row_line}" end)
  end

  defp column_coords(flipped) do
    Enum.map(0..(@tile_height - 1), fn row ->
      String.duplicate(" ", @tile_width) <>
        (Enum.map(
           if(!flipped, do: 0..(@chess_board_width - 1), else: (@chess_board_width - 1)..0),
           fn col ->
             curr_letter = Utils.ascii_chars()["letters"][List.to_string([?a + col])]
             curr_letter_line_no = rem(row, @tile_height)

             curr_line =
               if(curr_letter_line_no < length(curr_letter),
                 do: Enum.at(curr_letter, curr_letter_line_no),
                 else: ""
               )

             center_prefix_len = div(@tile_width - String.length(curr_line), 2)

             String.pad_trailing(
               String.duplicate(" ", center_prefix_len) <> curr_line,
               @tile_width
             )
           end
         )
         |> Enum.join(""))
    end)
  end

  defp make_board({tile_width, tile_height}) do
    rows =
      Enum.map(0..(@chess_board_height - 1), fn row ->
        Enum.map(0..(@chess_board_width - 1), fn col ->
          if(tileIsLight(row, col), do: '▊', else: ' ')
          |> List.duplicate(tile_width)
        end)
        |> Enum.join("")
      end)

    Enum.flat_map(rows, fn row -> Enum.map(1..tile_height, fn _ -> row end) end)
  end
end
