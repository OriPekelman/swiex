defmodule Swiex.ReturnValTest do
  use ExUnit.Case

  test "returnVal/2 returns its argument" do
    prolog_code = "returnVal(X, X)."
    assert {:ok, []} = Swiex.MQI.consult_string(prolog_code, [])
    assert {:ok, [%{"Y" => 42}]} = Swiex.MQI.query("returnVal(42, Y)")
    assert {:ok, [%{"Y" => "hello"}]} = Swiex.MQI.query("returnVal('hello', Y)")
  end

  test "returnSet/1 returns a complex list" do
    prolog_code = """
    returnSet(X) :-
      X = ['"foo"', '''bar''', [1, 'hello', ('a','b',7)]].
    """
    assert {:ok, []} = Swiex.MQI.consult_string(prolog_code, [])
    assert {:ok, [%{"X" => result}]} = Swiex.MQI.query("returnSet(X)")
    assert result == ["\"foo\"", "'bar'", [1, "hello", {"a", {"b", 7}}]]
  end

  test "easy_returnSet/1 returns a set-like list" do
    prolog_code = "easy_returnSet(X) :- X = [1, 'hello', ('a','b',7)]."
    assert {:ok, []} = Swiex.MQI.consult_string(prolog_code, [])
    assert {:ok, [%{"X" => result}]} = Swiex.MQI.query("easy_returnSet(X)")
    assert result == [1, "hello", {"a", {"b", 7}}]
  end

  test "return_None/1 returns nil" do
    prolog_code = "return_None(X) :- X = nil."
    assert {:ok, []} = Swiex.MQI.consult_string(prolog_code, [])
    assert {:ok, [%{"X" => nil}]} = Swiex.MQI.query("return_None(X)")
  end

  test "return_True/1 returns true" do
    prolog_code = "return_True(X) :- X = true."
    assert {:ok, []} = Swiex.MQI.consult_string(prolog_code, [])
    assert {:ok, [%{"X" => true}]} = Swiex.MQI.query("return_True(X)")
  end

  test "return_False/1 returns false" do
    prolog_code = "return_False(X) :- X = false."
    assert {:ok, []} = Swiex.MQI.consult_string(prolog_code, [])
    assert {:ok, [%{"X" => false}]} = Swiex.MQI.query("return_False(X)")
  end

  test "return_pi/1 returns 3.14159" do
    prolog_code = "return_pi(X) :- X = 3.14159."
    assert {:ok, []} = Swiex.MQI.consult_string(prolog_code, [])
    assert {:ok, [%{"X" => _pi}]} = Swiex.MQI.query("return_pi(X)")
  end

  test "return_apostrophe_1/1 returns string with apostrophe" do
    prolog_code = "return_apostrophe_1(X) :- X = 'I''m a doofus'."
    assert {:ok, []} = Swiex.MQI.consult_string(prolog_code, [])
    assert {:ok, [%{"X" => "I'm a doofus"}]} = Swiex.MQI.query("return_apostrophe_1(X)")
  end

  test "return_apostrophe_2/1 returns concatenated string with apostrophe" do
    prolog_code = "return_apostrophe_2(X) :- X = 'Hello my name is John and I''m a doofus'."
    assert {:ok, []} = Swiex.MQI.consult_string(prolog_code, [])
    assert {:ok, [%{"X" => "Hello my name is John and I'm a doofus"}]} = Swiex.MQI.query("return_apostrophe_2(X)")
  end

  test "return_dictionary/1 returns a dict-like structure" do
    prolog_code = "return_dictionary(X) :- X = dict([('Name', 'Geeks'), (1, [1,2,3,4])])."
    assert {:ok, []} = Swiex.MQI.consult_string(prolog_code, [])
    assert {:ok, [%{"X" => %{"Name" => "Geeks", 1 => [1,2,3,4]}}]} = Swiex.MQI.query("return_dictionary(X)")
  end
end
