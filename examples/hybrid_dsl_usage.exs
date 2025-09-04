#!/usr/bin/env elixir

# Hybrid DSL Usage Examples for Swiex
# This file demonstrates both Elixir DSL and inline Prolog approaches

# Import the DSL module
import Swiex.DSL

# Example 1: Using the Elixir DSL approach
defmodule ElixirDSLExamples do
  def run_elixir_dsl_examples do
    IO.puts("=== Elixir DSL Examples ===\n")

    # First, let's define some Prolog predicates using the traditional method
    IO.puts("1. Setting up Prolog predicates:")
    Swiex.MQI.assertz("factorial(0, 1).")
    Swiex.MQI.assertz("factorial(N, Result) :- N > 0, N1 is N - 1, factorial(N1, F1), Result is N * F1.")
    IO.puts("   ✓ factorial predicate defined\n")

    # Example 1: Using the query macro with Elixir syntax
    IO.puts("2. Using query macro with Elixir syntax:")
    case query(factorial(5, Result)) do
      {:ok, results} ->
        IO.puts("   factorial(5, Result) = #{inspect(results)}")
      {:error, reason} ->
        IO.puts("   Error: #{inspect(reason)}")
    end

    # Example 2: Using all/1 for multiple solutions
    IO.puts("\n3. Using all/1 for multiple solutions:")
    case all(factorial(N, 120)) do
      {:ok, results} ->
        IO.puts("   factorial(N, 120) = #{inspect(results)}")
      {:error, reason} ->
        IO.puts("   Error: #{inspect(reason)}")
    end

    # Example 3: Using one/1 for first solution
    IO.puts("\n4. Using one/1 for first solution:")
    case one(factorial(3, Result)) do
      {:ok, result} ->
        IO.puts("   factorial(3, Result) = #{inspect(result)}")
      {:error, reason} ->
        IO.puts("   Error: #{inspect(reason)}")
    end

    # Example 4: Using solutions/2 with limit
    IO.puts("\n5. Using solutions/2 with limit:")
    case solutions(factorial(N, Result), 3) do
      {:ok, results} ->
        IO.puts("   First 3 factorial solutions: #{inspect(results)}")
      {:error, reason} ->
        IO.puts("   Error: #{inspect(reason)}")
    end
  end
end

# Example 2: Using the Inline Prolog approach
defmodule InlinePrologExamples do
  # Define Prolog predicates using inline Prolog syntax
  prolog do
    """
    member(X, [X|_]).
    member(X, [_|T]) :- member(X, T).
    
    append([], L, L).
    append([H|T], L, [H|R]) :- append(T, L, R).
    
    reverse([], []).
    reverse([H|T], R) :- reverse(T, TR), append(TR, [H], R).
    """
  end

  def run_inline_prolog_examples do
    IO.puts("\n=== Inline Prolog Examples ===\n")

    # Load the inline Prolog predicates
    __prolog__()

    # Example 1: Using query_prolog with raw Prolog
    IO.puts("1. Using query_prolog with raw Prolog:")
    case query_prolog("member(X, [a, b, c])") do
      {:ok, results} ->
        IO.puts("   member(X, [a, b, c]) = #{inspect(results)}")
      {:error, reason} ->
        IO.puts("   Error: #{inspect(reason)}")
    end

    # Example 2: Using query_prolog_one for first solution
    IO.puts("\n2. Using query_prolog_one for first solution:")
    case query_prolog_one("member(X, [1, 2, 3, 4, 5]), X > 3") do
      {:ok, result} ->
        IO.puts("   member(X, [1, 2, 3, 4, 5]), X > 3 = #{inspect(result)}")
      {:error, reason} ->
        IO.puts("   Error: #{inspect(reason)}")
    end

    # Example 3: Using query_prolog_solutions with limit
    IO.puts("\n3. Using query_prolog_solutions with limit:")
    case query_prolog_solutions("member(X, [1, 2, 3, 4, 5]), X > 2", 2) do
      {:ok, results} ->
        IO.puts("   member(X, [1, 2, 3, 4, 5]), X > 2 (limit 2) = #{inspect(results)}")
      {:error, reason} ->
        IO.puts("   Error: #{inspect(reason)}")
    end

    # Example 4: Complex Prolog query
    IO.puts("\n4. Complex Prolog query:")
    case query_prolog("""
      append([1, 2], [3, 4], L),
      reverse(L, R)
    """) do
      {:ok, results} ->
        IO.puts("   append([1, 2], [3, 4], L), reverse(L, R) = #{inspect(results)}")
      {:error, reason} ->
        IO.puts("   Error: #{inspect(reason)}")
    end
  end
end

# Example 3: Mixed approach - using both DSL and inline Prolog
defmodule MixedApproachExamples do
  def run_mixed_examples do
    IO.puts("\n=== Mixed Approach Examples ===\n")

    # Example 1: Use inline Prolog for complex predicate definition
    IO.puts("1. Using inline Prolog for complex predicate definition:")
    Swiex.MQI.consult_string("""
      % Complex list processing predicates
      filter_positive([], []).
      filter_positive([H|T], [H|R]) :- H > 0, filter_positive(T, R).
      filter_positive([H|T], R) :- H =< 0, filter_positive(T, R).
      
      sum_list([], 0).
      sum_list([H|T], Sum) :- sum_list(T, RestSum), Sum is H + RestSum.
    """)
    IO.puts("   ✓ Complex predicates defined using inline Prolog\n")

    # Example 2: Use Elixir DSL for simple queries
    IO.puts("2. Using Elixir DSL for simple queries:")
    case all(filter_positive([-1, 2, -3, 4, -5], Result)) do
      {:ok, results} ->
        IO.puts("   filter_positive([-1, 2, -3, 4, -5], Result) = #{inspect(results)}")
      {:error, reason} ->
        IO.puts("   Error: #{inspect(reason)}")
    end

    # Example 3: Use inline Prolog for complex queries
    IO.puts("\n3. Using inline Prolog for complex queries:")
    case query_prolog("""
      filter_positive([-1, 2, -3, 4, -5], PosList),
      sum_list(PosList, Sum),
      Sum > 5
    """) do
      {:ok, results} ->
        IO.puts("   Complex query result = #{inspect(results)}")
      {:error, reason} ->
        IO.puts("   Error: #{inspect(reason)}")
    end
  end
end

# Run all examples if this file is executed directly
if __DIR__ == __ENV__.file do
  ElixirDSLExamples.run_elixir_dsl_examples()
  InlinePrologExamples.run_inline_prolog_examples()
  MixedApproachExamples.run_mixed_examples()
  
  IO.puts("\n=== Summary ===")
  IO.puts("✓ Elixir DSL: Natural Elixir syntax for simple queries")
  IO.puts("✓ Inline Prolog: Raw Prolog code for complex logic")
  IO.puts("✓ Mixed Approach: Best of both worlds")
  IO.puts("✓ All approaches work together seamlessly")
end
