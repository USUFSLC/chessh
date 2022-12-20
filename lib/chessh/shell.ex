defmodule Chessh.Shell do
  use Sshd.ShellHandler

  def on_shell(_username, _pubkey, _ip, _port) do
    IO.puts("Looks like you're on #{inspect(self())}")
    loop()
  end

  def on_connect(username, ip, port, method) do
    Logger.debug(fn ->
      """
      Incoming SSH shell #{inspect(self())} requested for #{username} from #{inspect(ip)}:#{inspect(port)} using #{inspect(method)}
      """
    end)
  end

  def on_disconnect(username, ip, port) do
    Logger.debug(fn ->
      "Disconnecting SSH shell for #{username} from #{inspect(ip)}:#{inspect(port)}"
    end)
  end

  defp loop() do
    self_pid = self()
    IO.write([IO.ANSI.home(), IO.ANSI.clear()])
    IO.puts("#{inspect(:io.columns())}")
    IO.puts("#{inspect(:io.rows())}")
    input = spawn(fn -> io_get(self_pid) end)
    wait_input(input)
  end

  defp wait_input(input) do
    receive do
      {:hello, message} ->
        IO.puts(message)
        loop()

      {:input, ^input, x} ->
        IO.puts(x)
        loop()

      x ->
        Logger.debug(inspect(x))
        loop()
    end
  end

  defp io_get(pid) do
    send(pid, {:input, self(), IO.gets("")})
  end
end
