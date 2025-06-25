defmodule Swiex.TestCTest do
  use ExUnit.Case

  test "compound query with multiple predicates and variables" do
    prolog_code = """
    p(1).
    p(2).
    q(a).
    q(b).
    """
    assert {:ok, []} = Swiex.MQI.consult_string(prolog_code, [])
    assert {:ok, results} = Swiex.MQI.query("p(X), q(Z), p(X)")
    assert Enum.any?(results, fn res -> res["X"] == 1 and res["Z"] == "a" end)
    assert Enum.any?(results, fn res -> res["X"] == 2 and res["Z"] == "a" end)
    assert Enum.any?(results, fn res -> res["X"] == 1 and res["Z"] == "b" end)
    assert Enum.any?(results, fn res -> res["X"] == 2 and res["Z"] == "b" end)
  end
end
