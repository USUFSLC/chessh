defmodule Chessh.Shell do
  use Sshd.ShellHandler

  def on_shell(_username, _public_key, _ip, _port) do
    :ok =
      IO.puts(
        "Interactive example SSH shell - type exit ENTER to quit and it is running on #{inspect(self())}"
      )
  end

  def on_connect(_username, _ip, _port, _method) do
    Logger.debug("Connection established")
  end

  def on_disconnect(_username, _ip, _port) do
    Logger.debug("Connection disestablished")
  end
end
