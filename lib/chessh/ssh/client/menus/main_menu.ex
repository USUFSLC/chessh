defmodule Chessh.SSH.Client.MainMenu do
  alias IO.ANSI
  alias Chessh.PlayerSession

  require Logger

  @logo "                            Simponic's
         dP                MP\"\"\"\"\"\"`MM MP\"\"\"\"\"\"`MM M\"\"MMMMM\"\"MM
         88                M  mmmmm..M M  mmmmm..M M  MMMMM  MM
.d8888b. 88d888b. .d8888b. M.      `YM M.      `YM M         `M
88'  `\"\" 88'  `88 88ooood8 MMMMMMM.  M MMMMMMM.  M M  MMMMM  MM
88.  ... 88    88 88.  ... M. .MMM'  M M. .MMM'  M M  MMMMM  MM
`88888P' dP    dP `88888P' Mb.     .dM Mb.     .dM M  MMMMM  MM
                           MMMMMMMMMMM MMMMMMMMMMM MMMMMMMMMMMM" |> String.split("\n")
  @logo_cols @logo |> Enum.map(&String.length/1) |> Enum.max()

  use Chessh.SSH.Client.SelectPaginatePoller

  def dynamic_options(), do: false
  def tick_delay_ms(), do: 1000
  def max_displayed_options(), do: 5
  def max_box_cols(), do: @logo_cols
  def title(), do: @logo ++ ["- Connected on: #{System.get_env("NODE_ID")}"]

  def initial_options(%State{player_session: %PlayerSession{} = player_session}) do
    [
      {"My Current Games",
       {Chessh.SSH.Client.SelectCurrentGame,
        %Chessh.SSH.Client.SelectPaginatePoller.State{player_session: player_session}}},
      {"Joinable Games (lobby)",
       {Chessh.SSH.Client.SelectJoinableGame,
        %Chessh.SSH.Client.SelectPaginatePoller.State{player_session: player_session}}},
      {"Previous Games",
       {Chessh.SSH.Client.SelectPreviousGame,
        %Chessh.SSH.Client.SelectPaginatePoller.State{player_session: player_session}}},
      {"Start A Game (Light)",
       {Chessh.SSH.Client.Game,
        %Chessh.SSH.Client.Game.State{player_session: player_session, color: :light}}},
      {"Start A Game (Dark)",
       {Chessh.SSH.Client.Game,
        %Chessh.SSH.Client.Game.State{player_session: player_session, color: :dark}}}
    ]
  end

  def make_process_tuple(selected, _state) do
    selected
  end
end
