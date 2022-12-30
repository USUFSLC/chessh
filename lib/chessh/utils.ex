defmodule Chessh.Utils do
  def pid_to_str(pid) do
    pid
    |> :erlang.pid_to_list()
    |> List.delete_at(0)
    |> List.delete_at(-1)
    |> to_string()
  end
end
