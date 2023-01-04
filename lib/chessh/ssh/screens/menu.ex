defmodule Chessh.SSH.Client.Menu do
  alias Chessh.SSH.Client
  alias Chessh.Utils
  alias IO.ANSI

  require Logger

  defmodule State do
    defstruct y: 0,
              x: 0
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

  def render(%Client.State{
        width: width,
        height: height,
        state_stack: [{_this_module, %State{y: y, x: x}} | _tail]
      }) do
    {logo_width, logo_height} = Utils.text_dim(@logo)

    split = String.split(@logo, "\n")

    Enum.flat_map(
      Enum.zip(0..(length(split) - 1), split),
      fn {i, line} ->
        [
          ANSI.cursor(div(height - logo_height, 2) + i + y, div(width - logo_width, 2) + x),
          "#{line}\n"
        ]
      end
    )
  end

  def handle_input(
        data,
        %Client.State{state_stack: [{this_module, %State{y: y, x: x} = screen_state} | tail]} =
          state
      ) do
    case data do
      :left ->
        %Client.State{
          state
          | state_stack: [{this_module, %State{screen_state | x: x - 1}} | tail]
        }

      :right ->
        %Client.State{
          state
          | state_stack: [{this_module, %State{screen_state | x: x + 1}} | tail]
        }

      :up ->
        %Client.State{
          state
          | state_stack: [{this_module, %State{screen_state | y: y - 1}} | tail]
        }

      :down ->
        %Client.State{
          state
          | state_stack: [{this_module, %State{screen_state | y: y + 1}} | tail]
        }

      _ ->
        state
    end
  end
end
