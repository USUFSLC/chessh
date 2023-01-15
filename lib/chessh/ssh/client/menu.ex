defmodule Chessh.SSH.Client.Menu do
  alias IO.ANSI
  alias Chessh.{Utils, Repo, Game}
  import Ecto.Query

  require Logger

  defmodule State do
    defstruct client_pid: nil,
              selected: 0,
              player_session: nil,
              options: []
  end

  @logo "                            Simponic's                           
         dP                MP\"\"\"\"\"\"`MM MP\"\"\"\"\"\"`MM M\"\"MMMMM\"\"MM 
         88                M  mmmmm..M M  mmmmm..M M  MMMMM  MM 
.d8888b. 88d888b. .d8888b. M.      `YM M.      `YM M         `M 
88'  `\"\" 88'  `88 88ooood8 MMMMMMM.  M MMMMMMM.  M M  MMMMM  MM 
88.  ... 88    88 88.  ... M. .MMM'  M M. .MMM'  M M  MMMMM  MM 
`88888P' dP    dP `88888P' Mb.     .dM Mb.     .dM M  MMMMM  MM 
                           MMMMMMMMMMM MMMMMMMMMMM MMMMMMMMMMMM"
  use Chessh.SSH.Client.Screen

  def init([%State{} = state | _]) do
    {:ok, %State{state | options: options(state)}}
  end

  def options(%State{player_session: player_session}) do
    current_games =
      Repo.all(
        from(g in Game,
          where: g.light_player_id == ^player_session.player_id,
          or_where: g.dark_player_id == ^player_session.player_id,
          where: g.status == :continue
        )
      )

    joinable_games =
      Repo.all(
        from(g in Game,
          where: is_nil(g.light_player_id),
          or_where: is_nil(g.dark_player_id)
        )
      )

    [
      {"Start A Game As Light",
       {Chessh.SSH.Client.Game,
        %Chessh.SSH.Client.Game.State{player_session: player_session, color: :light}}},
      {"Start A Game As Dark",
       {Chessh.SSH.Client.Game,
        %Chessh.SSH.Client.Game.State{player_session: player_session, color: :dark}}}
    ] ++
      Enum.map(current_games, fn game ->
        {"Current Game - #{game.id}",
         {Chessh.SSH.Client.Game,
          %Chessh.SSH.Client.Game.State{player_session: player_session, game: game}}}
      end) ++
      Enum.map(joinable_games, fn game ->
        {"Joinable Game - #{game.id}",
         {Chessh.SSH.Client.Game,
          %Chessh.SSH.Client.Game.State{player_session: player_session, game: game}}}
      end) ++
      [
        {"Settings", {}},
        {"Help", {}}
      ]
  end

  def input(
        width,
        height,
        action,
        %State{options: options, client_pid: client_pid, selected: selected} = state
      ) do
    new_state =
      case(action) do
        :up ->
          %State{
            state
            | selected: Utils.wrap_around(selected, -1, length(options))
          }

        :down ->
          %State{state | selected: Utils.wrap_around(selected, 1, length(options))}

        :return ->
          {_option, {module, state}} = Enum.at(options, selected)
          send(client_pid, {:set_screen_process, module, state})
          state

        _ ->
          state
      end

    if !(action == :return) do
      send(client_pid, {:send_to_ssh, render_state(width, height, new_state)})
    end

    new_state
  end

  def render(width, height, %State{client_pid: client_pid} = state) do
    send(client_pid, {:send_to_ssh, render_state(width, height, state)})
    state
  end

  defp render_state(
         width,
         height,
         %State{options: options, selected: selected} = state
       ) do
    logo_lines = String.split(@logo, "\n")
    {logo_width, logo_height} = Utils.text_dim(@logo)
    {y, x} = Utils.center_rect({logo_width, logo_height + length(logo_lines)}, {width, height})

    [ANSI.clear()] ++
      Enum.flat_map(
        Enum.zip(1..length(logo_lines), logo_lines),
        fn {i, line} ->
          [
            ANSI.cursor(y + i, x),
            line
          ]
        end
      ) ++
      Enum.flat_map(
        Enum.zip(0..(length(options) - 1), options),
        fn {i, {option, _}} ->
          [
            ANSI.cursor(y + length(logo_lines) + i + 1, x),
            if(i == selected, do: ANSI.format([:bright, :light_cyan, "+ #{option}"]), else: option)
          ]
        end
      ) ++ [ANSI.home()]
  end
end
