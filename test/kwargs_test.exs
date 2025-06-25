defmodule Swiex.KwargsTest do
  use ExUnit.Case

  test "kwargs_append/3 works like Python version" do
    prolog_code = """
    kwargs_append(X, Features, Result) :-
      Result = [X | Features].
    """
    assert {:ok, []} = Swiex.MQI.consult_string(prolog_code, [])
    assert {:ok, [%{"Result" => result}]} = Swiex.MQI.query("kwargs_append(hello, [(foo, bar), (baz, qux)], Result)")
    assert result == ["hello", {"foo", "bar"}, {"baz", "qux"}]
  end
end
