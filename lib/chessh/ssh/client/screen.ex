defmodule Chessh.SSH.Client.Screen do
  @callback render(width :: integer(), height :: integer(), state :: any()) :: any()
  @callback input(width :: integer(), height :: integer(), action :: any(), state :: any()) ::
              any()

  defmacro __using__(_) do
    quote do
      @behaviour Chessh.SSH.Client.Screen
      use GenServer

      @clear_codes [
        IO.ANSI.clear(),
        IO.ANSI.home()
      ]

      @ascii_chars Application.compile_env!(:chessh, :ascii_chars_json_file)
                   |> File.read!()
                   |> Jason.decode!()

      def center_rect({rect_width, rect_height}, {parent_width, parent_height}) do
        {
          div(parent_height - rect_height, 2),
          div(parent_width - rect_width, 2)
        }
      end

      def handle_info({:render, width, height}, state),
        do: {:noreply, render(width, height, state)}

      def handle_info({:input, width, height, action}, state),
        do: {:noreply, input(width, height, action, state)}
    end
  end
end
