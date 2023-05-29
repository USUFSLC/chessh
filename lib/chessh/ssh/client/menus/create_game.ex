defmodule Chessh.SSH.Client.CreateGameMenu do
  alias IO.ANSI

  alias Chessh.PlayerSession
  alias Chessh.SSH.Client.Game

  require Logger

  use Chessh.SSH.Client.SelectPaginatePoller

  def dynamic_options(), do: false
  def tick_delay_ms(), do: 1000
  def max_displayed_options(), do: 4
  def title(), do: ["-- Create A New Game --"]

  def initial_options(%State{player_session: %PlayerSession{} = player_session}) do
    [
      {"😀 vs 😀 | ⬜ White", {Game, %Game.State{player_session: player_session, color: :light}}},
      {"😀 vs 😀 | ⬛ Black", {Game, %Game.State{player_session: player_session, color: :dark}}},
      {"😀 vs 🤖 | ⬜ White",
       {Chessh.SSH.Client.SelectBot,
        %Chessh.SSH.Client.SelectPaginatePoller.State{
          player_session: player_session,
          extra_info: %{
            color: :light
          }
        }}},
      {"🤖 vs 😀 | ⬛ Black",
       {Chessh.SSH.Client.SelectBot,
        %Chessh.SSH.Client.SelectPaginatePoller.State{
          player_session: player_session,
          extra_info: %{
            color: :dark
          }
        }}}
    ]
  end

  def make_process_tuple(selected, _state) do
    selected
  end
end
