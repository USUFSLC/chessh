defmodule Chessh.SSH.Client.Board do
  alias Chessh.SSH.Client
  alias IO.ANSI

  require Logger

  defmodule State do
    defstruct cursor_x: 0,
              cursor_y: 0
  end

  use Chessh.SSH.Client.Screen

  def render(%Client.State{} = _state) do
    knight = @ascii_chars["pieces"]["white"]["knight"]

    [ANSI.home()] ++
      Enum.map(
        Enum.zip(0..(length(knight) - 1), knight),
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
