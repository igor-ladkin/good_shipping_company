defmodule GSCTest do
  use ExUnit.Case
  doctest GSC

  test "greets the world" do
    assert GSC.hello() == :world
  end
end
