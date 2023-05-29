defmodule Chessh.SSH.Client.Game.Renderer do
  alias IO.ANSI
  alias Chessh.{Utils, Player}
  alias Chessh.SSH.Client.Game
  require Logger

  @chess_board_height 8
  @chess_board_width 8

  @tile_width 7
  @tile_height 4

  @previous_move_background ANSI.light_magenta_background()
  @from_select_background ANSI.light_green_background()
  @to_select_background ANSI.light_yellow_background()
  @in_check_color ANSI.yellow_background()

  @dark_piece_color ANSI.red()
  @light_piece_color ANSI.light_cyan()

  def chess_board_height(), do: @chess_board_height
  def chess_board_width(), do: @chess_board_width
  def to_select_background(), do: @to_select_background
  def from_select_background(), do: @from_select_background
  def previous_move_background(), do: @previous_move_background
  def in_check_color(), do: @in_check_color

  def to_chess_coord({y, x})
      when x >= 0 and x < @chess_board_width and y >= 0 and y < @chess_board_height do
    "#{List.to_string([?a + x])}#{@chess_board_height - y}"
  end

  def flip({y, x}),
    do: {@chess_board_height - 1 - y, @chess_board_width - 1 - x}

  def from_chess_coord(s, flipped \\ false) do
    [x, y | _] = String.downcase(s) |> String.to_charlist()
    coords = {?8 - y, x - ?i + @chess_board_width}
    if flipped, do: flip(coords), else: coords
  end

  def render_board_state(
        %Game.State{
          game:
            %Chessh.Game{
              light_player: light_player,
              dark_player: dark_player
            } = game
        } = state
      )
      when is_nil(light_player) or is_nil(dark_player) do
    {light_player, dark_player} = get_players(game)

    render_board_state(%Game.State{
      state
      | game: %Chessh.Game{game | light_player: light_player, dark_player: dark_player}
    })
  end

  def render_board_state(%Game.State{
        highlighted: highlighted,
        flipped: flipped,
        game:
          %Chessh.Game{
            fen: fen,
            light_player: light_player,
            dark_player: dark_player
          } = game
      })
      when not is_nil(light_player) and not is_nil(dark_player) do
    rendered = [
      ANSI.clear_line(),
      make_status_line(game, true)
      | draw_board(
          fen,
          {@tile_width, @tile_height},
          highlighted,
          flipped
        )
    ]

    [ANSI.home()] ++
      Enum.map(
        Enum.zip(1..length(rendered), rendered),
        fn {i, line} ->
          [ANSI.cursor(i, 0), line]
        end
      )
  end

  def make_status_line(
        %Chessh.Game{
          light_player: light_player,
          dark_player: dark_player
        } = game,
        fancy
      )
      when is_nil(light_player) or is_nil(dark_player) do
    {light_player, dark_player} = get_players(game)

    make_status_line(
      %Chessh.Game{game | light_player: light_player, dark_player: dark_player},
      fancy
    )
  end

  def make_status_line(
        %Chessh.Game{
          id: game_id,
          dark_player: %Player{username: dark_player},
          light_player: %Player{username: light_player},
          turn: turn,
          status: status,
          winner: winner,
          moves: moves
        },
        fancy
      ) do
    Enum.join(
      [
        if(fancy,
          do: ANSI.clear_line(),
          else: ""
        ),
        "Game #{game_id} - ",
        if(fancy,
          do: ANSI.format_fragment([@light_piece_color, light_player]),
          else: "♔ #{light_player}"
        ),
        "#{if fancy, do: ANSI.default_color(), else: ""} --vs-- ",
        if(fancy,
          do: ANSI.format_fragment([@dark_piece_color, dark_player]),
          else: "♚ #{dark_player}"
        ),
        if(fancy, do: ANSI.default_color(), else: ""),
        case status do
          :continue ->
            ", #{moves} moves, #{ANSI.format_fragment([if(fancy, do: if(turn == :light, do: @light_piece_color, else: @dark_piece_color), else: ""), if(turn == :dark, do: dark_player, else: light_player)])} to move"

          :draw ->
            "ended in a draw after #{moves} moves"

          :winner ->
            ", #{ANSI.format_fragment([if(fancy, do: if(winner == :light, do: @light_piece_color, else: @dark_piece_color), else: ""), if(winner == :dark, do: dark_player, else: light_player)])} won after #{moves} moves!"
        end,
        if(fancy, do: ANSI.default_color(), else: "")
      ],
      ""
    )
  end

  def draw_board(
        fen,
        flipped
      ),
      do: draw_board(fen, {@tile_width, @tile_height}, %{}, flipped)

  def draw_board(
        fen,
        {tile_width, tile_height} = tile_dims,
        highlights,
        flipped
      ) do
    board_coord_to_piece_art = make_board_coordinate_to_piece_art_map(fen)
    tile_rows = make_board_tiles(tile_dims)

    (Enum.zip_with([tile_rows, 0..(tile_height * @chess_board_height - 1)], fn [row_str, row] ->
       curr_y = div(row, tile_height)

       %{row_chars: row_chars} =
         Enum.reduce(
           Enum.zip(String.graphemes(row_str), 0..(tile_width * @chess_board_width - 1)),
           %{tile_chunk: [], current_color: ANSI.default_color(), row_chars: []},
           fn {tile_char, col},
              %{tile_chunk: tile_chunk, current_color: current_color, row_chars: row_chars} =
                row_acc_state ->
             curr_x = div(col, tile_width)
             col_relative_to_tile = col - curr_x * tile_width

             board_coord =
               {if(!flipped, do: curr_y, else: @chess_board_height - curr_y - 1),
                if(!flipped, do: curr_x, else: @chess_board_width - curr_x - 1)}

             {color, char} =
               case Map.fetch(board_coord_to_piece_art, board_coord) do
                 {:ok, {shade, type}} ->
                   piece = Utils.ascii_chars()["pieces"][shade][type]
                   piece_line = Enum.at(piece, row - curr_y * tile_height)
                   spaces_pad_piece_line = div(tile_width - String.length(piece_line), 2)

                   piece_char =
                     if col_relative_to_tile >= spaces_pad_piece_line &&
                          col_relative_to_tile < tile_width - spaces_pad_piece_line,
                        do: String.at(piece_line, col_relative_to_tile - spaces_pad_piece_line)

                   new_char = if !piece_char || piece_char == " ", do: tile_char, else: piece_char

                   tile_char_color =
                     if !piece_char || piece_char == " ",
                       do: ANSI.default_color(),
                       else: if(shade == "dark", do: @dark_piece_color, else: @light_piece_color)

                   {tile_char_color, new_char}

                 _ ->
                   {current_color, tile_char}
               end

             tile_chunk =
               if col_relative_to_tile == 0 do
                 case Map.fetch(highlights, {curr_y, curr_x}) do
                   {:ok, highlighted_background_color} ->
                     [highlighted_background_color]

                   _ ->
                     [ANSI.default_background(), ANSI.default_color()]
                 end
               else
                 tile_chunk
               end ++ if(color == current_color, do: [char], else: [color, char])

             new_accumulated_state = %{
               row_acc_state
               | current_color:
                   if(col_relative_to_tile == 0, do: ANSI.default_color(), else: color),
                 tile_chunk: tile_chunk
             }

             if col_relative_to_tile == @tile_width - 1 do
               %{new_accumulated_state | row_chars: row_chars ++ tile_chunk}
             else
               new_accumulated_state
             end
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

  defp make_board_tiles({tile_width, tile_height}) do
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

  defp tileIsLight(row, col), do: rem(row, 2) == rem(col, 2)

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

  defp skip_cols_or_place_piece_reduce(char, {curr_column, data}, row_i) do
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
               {row_i, curr_column},
               {shade, type}
             )}
        end
    end
  end

  defp make_board_coordinate_to_piece_art_map(fen) do
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

  defp get_players(
         %Chessh.Game{light_player: light_player, dark_player: dark_player, bot: bot} = game
       ) do
    case {is_nil(light_player), is_nil(dark_player), is_nil(bot)} do
      {false, true, false} ->
        {game.light_player, %Player{username: bot.name}}

      {true, false, false} ->
        {%Player{username: bot.name}, game.dark_player}

      {true, false, true} ->
        {%Player{username: "(no opponent)"}, game.dark_player}

      {false, true, true} ->
        {game.light_player, %Player{username: "(no opponent)"}}

      {false, false, true} ->
        {game.light_player, game.dark_player}
    end
  end
end
