defmodule Swiex.Sumlist3Test do
  use ExUnit.Case

  test "sumlist3/3 adds X to each element of Y" do
    prolog_code = """
    sumlist3(X, Y, Z) :-
      sumlist3_(X, Y, Z).
    sumlist3_(_, [], []).
    sumlist3_(X, [H|T], [R|RT]) :-
      R is X + H,
      sumlist3_(X, T, RT).
    """
    assert {:ok, []} = Swiex.MQI.consult_string(prolog_code, [])
    assert {:ok, [%{"Z" => result}]} = Swiex.MQI.query("sumlist3(2, [1,2,3], Z)")
    assert result == [3, 4, 5]
  end
end
