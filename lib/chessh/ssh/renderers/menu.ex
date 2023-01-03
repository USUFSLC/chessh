defmodule Chessh.SSH.Client.Menu do
  alias Chessh.SSH.Client.State
  alias Chessh.Utils

  alias IO.ANSI

  @logo "                            Simponic's                           

         dP                MP\"\"\"\"\"\"`MM MP\"\"\"\"\"\"`MM M\"\"MMMMM\"\"MM 
         88                M  mmmmm..M M  mmmmm..M M  MMMMM  MM 
.d8888b. 88d888b. .d8888b. M.      `YM M.      `YM M         `M 
88'  `\"\" 88'  `88 88ooood8 MMMMMMM.  M MMMMMMM.  M M  MMMMM  MM 
88.  ... 88    88 88.  ... M. .MMM'  M M. .MMM'  M M  MMMMM  MM 
`88888P' dP    dP `88888P' Mb.     .dM Mb.     .dM M  MMMMM  MM 
                           MMMMMMMMMMM MMMMMMMMMMM MMMMMMMMMMMM"

  def render(
        %State{width: width, height: height, state_stack: [_current_state | _tail]} = _state,
        _args
      ) do
    {logo_width, logo_height} = Utils.text_dim(@logo)

    split = String.split(@logo, "\n")

    Enum.flat_map(
      Enum.zip(0..(length(split) - 1), split),
      fn {i, x} ->
        [
          ANSI.cursor(div(height - logo_height, 2) + i, div(width - logo_width, 2)),
          "#{x}\n"
        ]
      end
    )
  end
end
