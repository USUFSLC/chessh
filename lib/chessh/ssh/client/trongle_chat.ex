defmodule Chessh.SSH.Client.TrongleChat do
  require Logger
  alias Chessh.{Player, Chat, Utils, Repo, PlayerSession}
  import Ecto.Query

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

  defp get_initial_chats() do
    from(c in Chat,
      order_by: [desc: c.id],
      limit: 100
    )
    |> Repo.all()
    |> Repo.preload([:chatter])
  end

  defp get_player(%PlayerSession{player_id: player_id}), do: Repo.get!(Player, player_id)

  def init([%State{client_pid: client_pid, player_session: player_session} = state]) do
    :syn.add_node_to_scopes([:chat])
    :ok = :syn.join(:chat, {:tronglechat}, self())

    send(client_pid, {:send_to_ssh, Utils.clear_codes()})

    chats = get_initial_chats()

    {:ok,
     %State{
       state
       | chats: chats,
         player_session: %PlayerSession{player_session | player: get_player(player_session)}
     }}
  end

  def render(
        _width,
        _height,
        %State{
          client_pid: client_pid,
          chats: chats,
          message: message,
          player_session: %PlayerSession{player: %Player{username: username}}
        } = state
      ) do
    chat_msgs =
      Enum.map(chats, fn %Chat{message: message, chatter: %Player{username: chat_username}} =
                           _chat ->
        chat_username <> "> " <> message
      end)
      |> Enum.join("\r\n")

    prompt = username <> "> " <> message

    send(
      client_pid,
      {:send_to_ssh,
       [
         Utils.clear_codes(),
         prompt <> "\r\n" <> chat_msgs <> IO.ANSI.cursor(0, String.length(prompt))
       ]}
    )

    state
  end

  def input(
        width,
        height,
        action,
        data,
        %State{
          player_session: %PlayerSession{player: player},
          chats: chats,
          message: message
        } = state
      ) do
    appended_message =
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
          if String.match?(data, ~r/[a-zA-Z \.!-]/) do
            %State{state | message: message <> data}
          else
            state
          end
      end

    render(width, height, appended_message)
  end
end
