defmodule Chessh.SSH.Client.Menu do
  alias Chessh.Utils
  alias IO.ANSI

  require Logger

  defmodule State do
    defstruct dy: 0,
              dx: 0,
              tui_pid: nil,
              selected: 0
  end

  use Chessh.SSH.Client.Screen

  def init([%State{} = state | _]) do
    {:ok, state}
  end

  @logo "                            Simponic's                           
         dP                MP\"\"\"\"\"\"`MM MP\"\"\"\"\"\"`MM M\"\"MMMMM\"\"MM 
         88                M  mmmmm..M M  mmmmm..M M  MMMMM  MM 
.d8888b. 88d888b. .d8888b. M.      `YM M.      `YM M         `M 
88'  `\"\" 88'  `88 88ooood8 MMMMMMM.  M MMMMMMM.  M M  MMMMM  MM 
88.  ... 88    88 88.  ... M. .MMM'  M M. .MMM'  M M  MMMMM  MM 
`88888P' dP    dP `88888P' Mb.     .dM Mb.     .dM M  MMMMM  MM 
                           MMMMMMMMMMM MMMMMMMMMMM MMMMMMMMMMMM"

  #  @options [
  #    {"Option 1", {Chessh.SSH.Client.Board, [%Chessh.SSH.Client.Board.State{}]}},
  #    {"Option 2", {Chessh.SSH.Client.Board, [%Chessh.SSH.Client.Board.State{}]}}
  #  ]
  @options [
    {"Option 1", {}},
    {"Option 2", {}},
    {"Option 3", {}}
  ]

  def handle_info({:render, width, height}, %State{} = state) do
    render(width, height, state)
    {:noreply, state}
  end

  def handle_info({:input, width, height, action}, %State{selected: selected} = state) do
    new_state =
      case(action) do
        :up ->
          %State{
            state
            | selected: wrap_around(selected, -1, length(@options))
          }

        :down ->
          %State{state | selected: wrap_around(selected, 1, length(@options))}

        #      :return ->
        #        {_, new_state} = Enum.at(@options, selected)
        #        new_state

        _ ->
          state
      end

    render(width, height, new_state)
    {:noreply, new_state}
  end

  def render(width, height, %State{tui_pid: tui_pid, dy: dy, dx: dx, selected: selected}) do
    text = String.split(@logo, "\n")
    {logo_width, logo_height} = Utils.text_dim(@logo)
    {y, x} = center_rect({logo_width, logo_height + length(text)}, {width, height})

    rendered =
      Enum.flat_map(
        Enum.zip(1..length(text), text),
        fn {i, line} ->
          [
            ANSI.cursor(y + i + dy, x + dx),
            line
          ]
        end
      ) ++
        Enum.flat_map(
          Enum.zip(0..(length(@options) - 1), @options),
          fn {i, {option, _}} ->
            [
              ANSI.cursor(y + length(text) + i + dy, x + dx),
              if(i == selected, do: ANSI.format([:light_cyan, "* #{option}"]), else: option)
            ]
          end
        ) ++ [ANSI.home()]

    send(tui_pid, {:send_data, rendered})
  end

  defp wrap_around(index, delta, length) do
    calc = index + delta
    if(calc < 0, do: length, else: 0) + rem(calc, length)
  end
end
