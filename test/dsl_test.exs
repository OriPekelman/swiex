defmodule Swiex.DSLTest do
  use ExUnit.Case
  alias Swiex.DSL
  alias Swiex.DSL.Transform

  describe "DSL functions" do
    test "all/1 with string query" do
      assert {:ok, [%{"X" => 1}, %{"X" => 2}, %{"X" => 3}]} =
        DSL.all("member(X, [1,2,3])")
    end

    test "one/1 with string query" do
      assert {:ok, %{"X" => 1}} =
        DSL.one("member(X, [1,2,3])")
    end

    test "solutions/2 with string query and limit" do
      assert {:ok, [%{"X" => 1}, %{"X" => 2}]} =
        DSL.solutions("member(X, [1,2,3])", 2)
    end

    test "solutions/1 with string query" do
      assert {:ok, [%{"X" => 1}, %{"X" => 2}, %{"X" => 3}]} =
        DSL.solutions("member(X, [1,2,3])")
    end
  end

  test "DSL query_with_bindings functionality" do
    # Setup some facts
    Swiex.MQI.consult_string("""
      factorial(0, 1).
      factorial(N, Result) :-
        N > 0,
        N1 is N - 1,
        factorial(N1, F1),
        Result is N * F1.
    """, [])

    # Test query with bindings - create AST manually
    factorial_ast = {:factorial, [], [{:^, [], [{:N, [], nil}]}, {:Result, [], nil}]}
    member_ast = {:member, [], [{:^, [], [{:X, [], nil}]}, [1, 2, 3, 4, 5]]}

    # Test query with bindings
    assert {:ok, [%{"Result" => 120}]} = Swiex.DSL.query_with_bindings(factorial_ast, [N: 5])
    assert {:ok, [%{"Result" => 720}]} = Swiex.DSL.query_with_bindings(factorial_ast, [N: 6])

    # Test with member query - when X is bound to 3, the query becomes member(3, [1,2,3,4,5])
    # which returns true (empty map) since 3 is a member
    assert {:ok, [%{}]} = Swiex.DSL.query_with_bindings(member_ast, [X: 3])
    assert {:ok, []} = Swiex.DSL.query_with_bindings(member_ast, [X: 10])
  end

  describe "Transform module" do
    test "to_query with simple function call" do
      ast = {:factorial, [], [5, {:Result, [], nil}]}
      assert "factorial(5, Result)" = Transform.to_query(ast)
    end

    test "to_query with multiple arguments" do
      ast = {:member, [], [{:X, [], nil}, [1, 2, 3]]}
      assert "member(X, [1,2,3])" = Transform.to_query(ast)
    end

    test "to_query with string argument" do
      ast = {:test, [], ["hello"]}
      assert "test('hello')" = Transform.to_query(ast)
    end

    test "to_query with number argument" do
      ast = {:test, [], [42]}
      assert "test(42)" = Transform.to_query(ast)
    end

    test "to_query with list argument" do
      ast = {:test, [], [[1, 2, 3]]}
      assert "test([1,2,3])" = Transform.to_query(ast)
    end

    test "to_prolog with simple clause" do
      ast = quote do
        factorial(0, 1)
      end

      assert "factorial(0, 1)." = Transform.to_prolog(ast)
    end

    test "to_prolog with multiple clauses" do
      ast = quote do
        factorial(0, 1)
        factorial(1, 1)
      end

      assert "factorial(0, 1).\nfactorial(1, 1)." = Transform.to_prolog(ast)
    end

    test "to_prolog with guard clause" do
      ast = quote do
        factorial(N, Result) when N > 0
      end

      assert "factorial(N, Result) :- N > 0." = Transform.to_prolog(ast)
    end
  end

  describe "error handling" do
    test "to_query with invalid input" do
      assert_raise ArgumentError, "Expected function call tuple, got: :invalid", fn ->
        Transform.to_query(:invalid)
      end
    end
  end
end
