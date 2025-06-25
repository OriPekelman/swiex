defmodule SwiexTest do
  use ExUnit.Case
  use Swiex

  setup do
    # Ensure the application is started
    Application.ensure_all_started(:swiex)
    :ok
  end

  test "simple member query" do
    query = "member(X, [a, b, c])"
    case Swiex.query(query) do
      {:ok, results} ->
        assert length(results) == 3
        assert Enum.any?(results, fn r -> r["X"] == "a" end)
        assert Enum.any?(results, fn r -> r["X"] == "b" end)
        assert Enum.any?(results, fn r -> r["X"] == "c" end)

      {:error, reason} ->
        flunk("Query failed: #{reason}")
    end
  end

  test "factorial calculation" do
    # Define factorial predicate
    Swiex.MQI.consult_string("""
      factorial(0, 1).
      factorial(N, Result) :-
        N > 0,
        N1 is N - 1,
        factorial(N1, F1),
        Result is N * F1.
    """, [])

    # Test factorial of 5
    query = "factorial(5, Result)"
    case Swiex.query(query) do
      {:ok, results} ->
        [res | _] = results
        assert res["Result"] == 120

      {:error, reason} ->
        flunk("Factorial query failed: #{reason}")
    end
  end

  test "variable interpolation" do
    x = 10
    y = 5

    query = "#{x} > #{y}, Result is #{x} + #{y}"
    case Swiex.query(query) do
      {:ok, results} ->
        [res | _] = results
        assert res["Result"] == 15

      {:error, reason} ->
        flunk("Arithmetic query failed: #{reason}")
    end
  end

  test "list variable interpolation" do
    my_list = [1, 2, 3, 4, 5]

    query = "member(X, #{inspect(my_list)}), X > 3"
    case Swiex.query(query) do
      {:ok, results} ->
        values = Enum.map(results, fn r -> r["X"] end)
        assert Enum.member?(values, 4)
        assert Enum.member?(values, 5)

      {:error, reason} ->
        flunk("List query failed: #{reason}")
    end
  end

  test "async query" do
    # Define a simple predicate
    Swiex.MQI.consult_string("double(X, Result) :- Result is X * 2.", [])

    # Start async query
    query = "double(7, Result)"
    case Swiex.query(query) do
      {:ok, results} ->
        [res | _] = results
        assert res["Result"] == 14

      {:error, reason} ->
        flunk("No async result found: #{reason}")
    end
  end

  test "error handling for invalid query" do
    case Swiex.query("invalid_predicate(X)") do
      {:ok, _results} ->
        flunk("Should have failed with invalid predicate")

      {:error, _reason} ->
        assert true # Expected error
    end
  end
end
