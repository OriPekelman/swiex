defmodule Swiex.TupleTest do
  use ExUnit.Case

  test "func/1 returns a tuple structure" do
    prolog_code = "func(X) :- X = [5, [], 'hello', [5,6,7]]."
    assert {:ok, []} = Swiex.MQI.consult_string(prolog_code, [])
    assert {:ok, [%{"X" => result}]} = Swiex.MQI.query("func(X)")
    assert result == [5, [], "hello", [5,6,7]]
  end
end
