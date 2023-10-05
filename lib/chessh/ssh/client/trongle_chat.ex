defmodule Chessh.SSH.Client.TrongleChat do
  require Logger
  alias Chessh.{Player, Chat, Utils, Repo, PlayerSession}
  import Ecto.Query

  defmodule State do
    defstruct client_pid: nil,
              message: "",
              player_session: nil,
              chats: []
  end

  use Chessh.SSH.Client.Screen

  defp get_initial_chats() do
    from(c in Chat,
      order_by: [desc: c.id],
      limit: 100
    )
    |> Repo.all()
    |> Repo.preload([:chatter])
  end

  def get_player(%PlayerSession{player_id: player_id} = player_session) do
    Repo.get!(Player, player_id)
  end

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
        width,
        height,
        %State{
          client_pid: client_pid,
          chats: chats,
          message: message,
          player_session: %PlayerSession{player: %Player{username: username}} = player_session
        } = state
      ) do
    send(client_pid, {:send_to_ssh, [Utils.clear_codes(), username <> "> " <> message]})

    state
  end

  def input(width, height, action, data, %State{message: message} = state) do
    appended_message =
      case action do
        :backspace ->
          %State{state | message: String.slice(message, 0..-2)}

        _ ->
          if String.match?(data, ~r/[a-zA-Z \.-]/) do
            %State{state | message: message <> data}
          else
            state
          end
      end

    render(width, height, appended_message)
  end
end
