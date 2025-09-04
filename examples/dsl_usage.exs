#!/usr/bin/env elixir

# DSL Usage Examples for Swiex
# This file demonstrates the new Domain Specific Language features

# Import the DSL module
import Swiex.DSL

# Example 1: Using the DSL query macro
defmodule DSLExamples do
  def run_examples do
    IO.puts("=== Swiex DSL Examples ===\n")

    # First, let's define some Prolog predicates using the traditional method
    IO.puts("1. Setting up Prolog predicates:")
    Swiex.MQI.assertz("factorial(0, 1).")
    Swiex.MQI.assertz("factorial(N, Result) :- N > 0, N1 is N - 1, factorial(N1, F1), Result is N * F1.")
    IO.puts("   ✓ factorial predicate defined\n")

    # Example 1: Using the query macro
    IO.puts("2. Using query macro:")
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

    # Example 5: Traditional string queries still work
    IO.puts("\n6. Traditional string queries still work:")
    case all("member(X, [a, b, c])") do
      {:ok, results} ->
        IO.puts("   member(X, [a, b, c]) = #{inspect(results)}")
      {:error, reason} ->
        IO.puts("   Error: #{inspect(reason)}")
    end

    # Example 6: Security features in action
    IO.puts("\n7. Security features in action:")
    case all("halt") do
      {:error, {:security_error, :potentially_dangerous_query}} ->
        IO.puts("   ✓ Security: 'halt' query rejected")
      other ->
        IO.puts("   ✗ Security: Expected rejection, got #{inspect(other)}")
    end
  end
end

# Run the examples if this file is executed directly
if __DIR__ == __ENV__.file do
  DSLExamples.run_examples()
end
