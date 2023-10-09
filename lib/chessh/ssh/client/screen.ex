defmodule Chessh.SSH.Client.Screen do
  @callback render(width :: integer(), height :: integer(), state :: any()) :: any()
  @callback input(
              action :: any(),
              data :: String.t(),
              state :: any()
            ) ::
              any()

  defmacro __using__(_) do
    quote do
      @behaviour Chessh.SSH.Client.Screen
      use GenServer

      def handle_info({:render, width, height}, state),
        do: {:noreply, render(width, height, state)}

      def handle_info({:input, action, data}, state),
        do: {:noreply, input(action, data, state)}
    end
  end
end
