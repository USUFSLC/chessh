defmodule Chessh.SSH.Client.Game.PromotionScreen do
  alias Chessh.Utils
  alias Chessh.SSH.Client.Game
  alias IO.ANSI

  defmodule State do
    defstruct game_pid: nil,
              client_pid: nil,
              game_state: nil
  end

  use Chessh.SSH.Client.Screen

  @promotion_screen Utils.clear_codes() ++
                      [
                        "Press the key associated to the piece you'd like to promote",
                        "  'q' - queen",
                        "  'r' - rook",
                        "  'n' - knight",
                        "  'b' - bishop"
                      ]

  def init([%State{} = state | _]) do
    {:ok, state}
  end

  def render(_, _, %State{client_pid: client_pid} = state) do
    rendered =
      Enum.flat_map(
        Enum.zip(0..(length(@promotion_screen) - 1), @promotion_screen),
        fn {i, promotion} ->
          [
            ANSI.cursor(i, 0),
            promotion
          ]
        end
      ) ++ [ANSI.home()]

    send(
      client_pid,
      {:send_to_ssh, rendered}
    )

    state
  end

  def input(
        _,
        _,
        action,
        %State{client_pid: client_pid, game_pid: game_pid, game_state: %Game.State{} = game_state} =
          state
      ) do
    promotion = if Enum.member?(["q", "b", "n", "r"], action), do: action, else: nil

    if promotion do
      send(client_pid, {:go_back_one_screen, game_state})
      send(game_pid, {:promotion, promotion})
    end

    state
  end
end
