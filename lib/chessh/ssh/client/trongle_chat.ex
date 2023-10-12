defmodule Chessh.SSH.Client.TrongleChat do
  require Logger
  alias Chessh.{Player, Chat, Utils, Repo, PlayerSession}
  import Ecto.Query

  @colors [
    IO.ANSI.light_blue(),
    IO.ANSI.light_red(),
    IO.ANSI.green(),
    IO.ANSI.light_magenta(),
    IO.ANSI.cyan(),
    IO.ANSI.blue(),
    IO.ANSI.yellow()
  ]

  defmodule State do
    defstruct client_pid: nil,
              message: "",
              player_session: nil,
              width: 0,
              height: 0,
              chats: []
  end

  use Chessh.SSH.Client.Screen

  def handle_info(
        {:new_chat, %Chat{} = chat},
        %State{width: width, height: height, chats: chats} = state
      ) do
    new_state = %State{
      state
      | chats: [chat | chats]
    }

    {:noreply, render(width, height, new_state)}
  end

  def init([
        %State{
          client_pid: client_pid,
          player_session: %PlayerSession{player_id: player_id} = player_session
        } = state
      ]) do
    :syn.add_node_to_scopes([:chat])
    :ok = :syn.join(:chat, {:tronglechat}, self())

    send(client_pid, {:send_to_ssh, Utils.clear_codes()})

    {:ok,
     %State{
       state
       | chats: get_initial_chats(),
         player_session: %PlayerSession{player_session | player: Repo.get!(Player, player_id)}
     }}
  end

  def render(
        width,
        height,
        %State{
          client_pid: client_pid,
          chats: chats,
          message: message,
          player_session: %PlayerSession{player: %Player{username: username}}
        } = state
      ) do
    chat_msgs =
      chats
      |> Enum.slice(0, height - 1)
      |> Enum.map(&format_chat/1)
      |> Enum.join("\r\n")

    {prompt, prompt_len} = format_prompt(username, message)

    send(
      client_pid,
      {:send_to_ssh,
       [
         Utils.clear_codes(),
         prompt <>
           "\r\n" <> chat_msgs <> IO.ANSI.cursor(0, prompt_len + 1)
       ]}
    )

    %State{state | width: width, height: height}
  end

  def input(
        action,
        data,
        %State{
          player_session: %PlayerSession{player: player},
          message: message,
          width: width,
          height: height
        } = state
      ) do
    safe_char_regex = ~r/[ A-Za-z0-9._~()'!*:@,;+?-]/

    appended_message_state =
      case action do
        :backspace ->
          %State{state | message: String.slice(message, 0..-2)}

        :return ->
          if message != "" do
            {:ok, saved_chat} = Repo.insert(%Chat{message: message, chatter: player})
            :syn.publish(:chat, {:tronglechat}, {:new_chat, saved_chat})
            %State{state | message: ""}
          else
            state
          end

        _ ->
          if String.match?(data, safe_char_regex) do
            %State{state | message: message <> data}
          else
            state
          end
      end

    render(width, height, appended_message_state)
  end

  defp get_initial_chats() do
    from(c in Chat,
      order_by: [desc: c.id],
      limit: 100
    )
    |> Repo.all()
    |> Repo.preload([:chatter])
  end

  defp username_color(username, colors \\ @colors) do
    ind =
      String.to_charlist(username)
      |> Enum.sum()
      |> rem(length(colors))

    Enum.at(colors, ind)
  end

  defp format_prompt(username, message) do
    {
      [
        IO.ANSI.format_fragment([username_color(username), username, IO.ANSI.default_color()]),
        "> ",
        message
      ]
      |> Enum.join(""),
      String.length(username) + String.length(message) + 2
    }
  end

  defp format_chat(%Chat{chatter: %Player{username: username}, message: message}) do
    {prompt, _} = format_prompt(username, message)
    prompt
  end
end
