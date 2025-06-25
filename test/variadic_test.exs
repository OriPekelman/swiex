defmodule Swiex.VariadicTest do
  use ExUnit.Case

  test "variadic_print/2 and opt_print/3 behave like Python version" do
    prolog_code = """
    % variadic_print(+Args, -Result)
    variadic_print(Args, Result) :-
      atomic_list_concat(Args, '|', Tmp),
      atom_concat('variadic_print: ', Tmp, Result).

    % opt_print(+Arg, ?OptArg, -Result)
    opt_print(Arg, Result) :-
      opt_print(Arg, 1, Result).
    opt_print(Arg, OptArg, Result) :-
      atom_concat(Arg, '|', Tmp),
      atom_concat(Tmp, OptArg, Result).
    """
    assert {:ok, []} = Swiex.MQI.consult_string(prolog_code, [])
    assert {:ok, [%{"Result" => result1}]} = Swiex.MQI.query("variadic_print(['a','b','c'], Result)")
    assert result1 == "variadic_print: a|b|c"
    assert {:ok, [%{"Result" => result2}]} = Swiex.MQI.query("opt_print('foo', Result)")
    assert result2 == "foo|1"
    assert {:ok, [%{"Result" => result3}]} = Swiex.MQI.query("opt_print('foo', 42, Result)")
    assert result3 == "foo|42"
  end
end
