defmodule Chessh.SSH.Client.Menu do
  alias Chessh.SSH.Client
  alias Chessh.Utils
  alias IO.ANSI

  require Logger

  defmodule State do
    defstruct y: 0,
              x: 0,
              selected: 0
  end

  use Chessh.SSH.Client.Screen

  @logo "                            Simponic's                           
         dP                MP\"\"\"\"\"\"`MM MP\"\"\"\"\"\"`MM M\"\"MMMMM\"\"MM 
         88                M  mmmmm..M M  mmmmm..M M  MMMMM  MM 
.d8888b. 88d888b. .d8888b. M.      `YM M.      `YM M         `M 
88'  `\"\" 88'  `88 88ooood8 MMMMMMM.  M MMMMMMM.  M M  MMMMM  MM 
88.  ... 88    88 88.  ... M. .MMM'  M M. .MMM'  M M  MMMMM  MM 
`88888P' dP    dP `88888P' Mb.     .dM Mb.     .dM M  MMMMM  MM 
                           MMMMMMMMMMM MMMMMMMMMMM MMMMMMMMMMMM"

  @options [
    {"Option 1", {Chessh.SSH.Client.Board, %{}}},
    {"Option 2", {Chessh.SSH.Client.Board, %{}}},
    {"Option 3", {Chessh.SSH.Client.Board, %{}}}
  ]

  def render(%Client.State{
        width: width,
        height: height,
        state_stack: [{_this_module, %State{selected: selected, y: dy, x: dx}} | _tail]
      }) do
    text = String.split(@logo, "\n")
    {logo_width, logo_height} = Utils.text_dim(@logo)
    {y, x} = center_rect({logo_width, logo_height + length(text)}, {width, height})

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
  end

  def wrap_around(index, delta, length) do
    calc = index + delta
    if(calc < 0, do: length, else: 0) + rem(calc, length)
  end

  def handle_input(
        data,
        %Client.State{
          state_stack:
            [{this_module, %State{selected: selected} = screen_state} | tail] = state_stack
        } = state
      ) do
    case(data) do
      :up ->
        %Client.State{
          state
          | state_stack: [
              {this_module,
               %State{screen_state | selected: wrap_around(selected, -1, length(@options))}}
              | tail
            ]
        }

      :down ->
        %Client.State{
          state
          | state_stack: [
              {this_module,
               %State{screen_state | selected: wrap_around(selected, 1, length(@options))}}
              | tail
            ]
        }

      :return ->
        {_, new_state} = Enum.at(@options, selected)

        %Client.State{
          state
          | state_stack: [new_state] ++ state_stack
        }

      _ ->
        state
    end
  end
end
