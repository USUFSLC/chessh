defmodule Chessh.SSH.Client.SelectPaginatePoller do
  @callback dynamic_options() :: boolean()

  @callback tick_delay_ms() :: integer()
  @callback max_displayed_options() :: integer()
  @callback max_box_cols() :: integer()
  @callback make_process_tuple(selected :: any(), state :: any()) ::
              {module :: module(), state :: any()}

  @callback initial_options(state :: any()) ::
              [{line :: any(), selected :: any()}]

  @callback refresh_options_ms() :: integer()
  @callback refresh_options(state :: any()) ::
              [{line :: any(), selected :: any()}]
  @callback next_page_options(state :: any()) ::
              [{line :: any(), selected :: any()}]
  @callback previous_page_options(state :: any()) ::
              [{line :: any(), selected :: any()}]

  @callback title() :: [any()]

  defmodule State do
    defstruct client_pid: nil,
              selected_option_idx: 0,
              player_session: nil,
              options: [],
              tick: 0,
              cursor: nil
  end

  defmacro __using__(_) do
    quote do
      @behaviour Chessh.SSH.Client.SelectPaginatePoller
      use Chessh.SSH.Client.Screen

      alias IO.ANSI
      alias Chessh.{Utils, PlayerSession}
      alias Chessh.SSH.Client.SelectPaginatePoller.State
      alias Chessh.SSH.Client.SelectPaginatePoller

      require Logger

      def init([%State{} = state | _]) do
        if dynamic_options() do
          Process.send_after(self(), :refresh_options, refresh_options_ms())
        end

        Process.send_after(self(), :tick, tick_delay_ms())

        {:ok, %State{state | options: initial_options(state)}}
      end

      def handle_info(
            :refresh_options,
            %State{
              selected_option_idx: selected_option_idx,
              tick: tick,
              client_pid: client_pid
            } = state
          ) do
        if dynamic_options() do
          options = refresh_options(state)
          Process.send_after(self(), :refresh_options, refresh_options_ms())

          {:noreply,
           %State{
             state
             | selected_option_idx: min(selected_option_idx, length(options) - 1),
               options: options
           }}
        else
          {:noreply, state}
        end
      end

      def handle_info(
            :tick,
            %State{
              tick: tick,
              client_pid: client_pid
            } = state
          ) do
        Process.send_after(self(), :tick, tick_delay_ms())

        if client_pid do
          send(client_pid, :refresh)
        end

        {:noreply, %State{state | tick: tick + 1}}
      end

      def handle_info(
            x,
            state
          ) do
        Logger.debug("unknown message in pagination poller - #{inspect(x)}")

        {:noreply, state}
      end

      def render(
            width,
            height,
            %State{
              client_pid: client_pid
            } = state
          ) do
        send(
          client_pid,
          {:send_to_ssh, render_state(width, height, state)}
        )

        state
      end

      def input(
            width,
            height,
            action,
            %State{
              client_pid: client_pid,
              options: options,
              selected_option_idx: selected_option_idx
            } = state
          ) do
        max_item = min(length(options), max_displayed_options())

        new_state =
          if(max_item > 0,
            do:
              case action do
                :up ->
                  %State{
                    state
                    | selected_option_idx: Utils.wrap_around(selected_option_idx, -1, max_item),
                      tick: 0
                  }

                :down ->
                  %State{
                    state
                    | selected_option_idx: Utils.wrap_around(selected_option_idx, 1, max_item),
                      tick: 0
                  }

                :left ->
                  if dynamic_options(),
                    do: %State{
                      state
                      | options: previous_page_options(state),
                        selected_option_idx: 0,
                        tick: 0
                    }

                :right ->
                  if dynamic_options(),
                    do: %State{
                      state
                      | options: next_page_options(state),
                        selected_option_idx: 0,
                        tick: 0
                    }

                :return ->
                  {_, selected} = Enum.at(options, selected_option_idx)
                  {module, state} = make_process_tuple(selected, state)
                  send(client_pid, {:set_screen_process, module, state})
                  state

                _ ->
                  nil
              end
          ) || state

        if !(action == :return) do
          render(width, height, new_state)
        end

        new_state
      end

      defp render_state(
             width,
             height,
             %State{} = state
           ) do
        lines =
          title() ++
            [""] ++
            render_lines(width, height, state) ++
            if dynamic_options(), do: ["", "<= Previous | Next =>"], else: []

        {y, x} = Utils.center_rect({min(width, max_box_cols()), length(lines)}, {width, height})

        [ANSI.clear()] ++
          Enum.flat_map(
            Enum.zip(0..(length(lines) - 1), lines),
            fn {i, line} ->
              [
                ANSI.cursor(y + i, x),
                line
              ]
            end
          ) ++ [ANSI.home()]
      end

      defp render_lines(width, _height, %State{
             tick: tick,
             options: options,
             selected_option_idx: selected_option_idx
           }) do
        if options && length(options) > 0 do
          Enum.map(
            Enum.zip(0..(max_displayed_options() - 1), options),
            fn {i, {line, _}} ->
              box_cols = min(max_box_cols(), width)
              linelen = String.length(line)

              line =
                if linelen > box_cols do
                  delta = max(box_cols - 3 - 1, 0)
                  overflow = linelen - delta
                  start = if i == selected_option_idx, do: rem(tick, overflow), else: 0
                  "#{String.slice(line, start..(start + delta))}..."
                else
                  line
                end

              if i == selected_option_idx do
                ANSI.format_fragment(
                  [:light_cyan, :bright, "> #{line} <", :reset],
                  true
                )
              else
                line
              end
            end
          )
        else
          ["Looks like there's nothing here.", "Use Ctrl+b to go back"]
        end
      end

      def refresh_options_ms(), do: 3000
      def next_page_options(%State{options: options}), do: options
      def previous_page_options(%State{options: options}), do: options
      def refresh_options(%State{options: options}), do: options

      def tick_delay_ms(), do: 1000
      def max_displayed_options(), do: 10
      def max_box_cols(), do: 90

      defoverridable refresh_options_ms: 0,
                     next_page_options: 1,
                     previous_page_options: 1,
                     refresh_options: 1,
                     tick_delay_ms: 0,
                     max_displayed_options: 0,
                     max_box_cols: 0
    end
  end
end
