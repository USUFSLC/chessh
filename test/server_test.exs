defmodule ChesshTest do
  use ExUnit.Case
  doctest Chessh

  test "greets the world" do
    assert Chessh.hello() == :world
  end
end
