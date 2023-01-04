defmodule Chessh.SSH.Client.Board do
  use Chessh.SSH.Client.Screen
  alias Chessh.SSH.Client.State

  def render(%State{} = _state) do
    @ascii_chars["pieces"]["white"]["knight"]
  end

  def handle_input(action, state) do
    case action do
      "q" -> state
      _ -> state
    end
  end
end
