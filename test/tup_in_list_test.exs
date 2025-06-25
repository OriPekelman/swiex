defmodule Swiex.TupInListTest do
  use ExUnit.Case

  test "func/1 returns a list with ints, tuple, string, and list" do
    prolog_code = "func(X) :- X = [1,2,3, (5,6), 'hello', [11,17]]."
    assert {:ok, []} = Swiex.MQI.consult_string(prolog_code, [])
    assert {:ok, [%{"X" => result}]} = Swiex.MQI.query("func(X)")
    assert result == [1,2,3,{5,6},"hello",[11,17]]
  end

  test "func1/1 returns a nested tuple/list structure" do
    prolog_code = "func1(X) :- X = [5,6,[7,8],[9,10]]."
    assert {:ok, []} = Swiex.MQI.consult_string(prolog_code, [])
    assert {:ok, [%{"X" => result}]} = Swiex.MQI.query("func1(X)")
    assert result == [5,6,[7,8],[9,10]]
  end

  test "return_error/1 raises an error (division by zero)" do
    prolog_code = "return_error(X) :- X is 1/0."
    assert {:ok, []} = Swiex.MQI.consult_string(prolog_code, [])
    assert {:error, _} = Swiex.MQI.query("return_error(X)")
  end
end
