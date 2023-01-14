defmodule Chessh.Utils do
  @ascii_chars Application.compile_env!(:chessh, :ascii_chars_json_file)
               |> File.read!()
               |> Jason.decode!()

  @clear_codes [
    IO.ANSI.clear(),
    IO.ANSI.home()
  ]

  def ascii_chars(), do: @ascii_chars
  def clear_codes(), do: @clear_codes

  def center_rect({rect_width, rect_height}, {parent_width, parent_height}) do
    {
      div(parent_height - rect_height, 2),
      div(parent_width - rect_width, 2)
    }
  end

  def pid_to_str(pid) do
    pid
    |> :erlang.pid_to_list()
    |> List.delete_at(0)
    |> List.delete_at(-1)
    |> to_string()
  end

  def text_dim(text) do
    split = String.split(text, "\n")
    {Enum.reduce(split, 0, fn x, acc -> max(acc, String.length(x)) end), length(split)}
  end

  def wrap_around(index, delta, length) do
    calc = index + delta
    if(calc < 0, do: length, else: 0) + rem(calc, length)
  end
end
