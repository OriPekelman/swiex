#!/usr/bin/env elixir

# Advanced Features Demo for Swiex
# This file demonstrates the new features implemented:
# 1. Enhanced Pin Operator Support with Variable Interpolation
# 2. Streaming Results for Large Datasets
# 3. Transaction Support with Rollback

IO.puts("🚀 Swiex Advanced Features Demo")
IO.puts("=" |> String.duplicate(50))
IO.puts("")

# Setup some test data
IO.puts("📚 Setting up test data...")
Swiex.MQI.consult_string("""
  % Factorial predicate
  factorial(0, 1).
  factorial(N, Result) :-
    N > 0,
    N1 is N - 1,
    factorial(N1, F1),
    Result is N * F1.

  % Member predicate
  member(X, [X|_]).
  member(X, [_|T]) :- member(X, T).

  % Range generator
  range(Start, End, List) :-
    findall(N, (between(Start, End, N)), List).

  % Person facts
  person(john, 30).
  person(jane, 25).
  person(bob, 35).
""", [])

IO.puts("✅ Test data loaded")
IO.puts("")

# 1. Enhanced Pin Operator Support
IO.puts("🎯 1. Enhanced Pin Operator Support")
IO.puts("-" |> String.duplicate(30))

# Basic pin operator usage
IO.puts("\n📌 Basic pin operator:")
member_ast = {:member, [], [{:^, [], [{:X, [], nil}]}, [1, 2, 3, 4, 5]]}
query = Swiex.DSL.Transform.to_query(member_ast)
IO.puts("  Query: #{query}")

# Pin operator with variable interpolation
IO.puts("\n📌 Pin operator with variable interpolation:")
query_with_binding = Swiex.DSL.Transform.to_query_with_bindings(member_ast, [X: 3])
IO.puts("  Query with X=3: #{query_with_binding}")

# Using the DSL with bindings
IO.puts("\n📌 DSL query with bindings:")
case Swiex.DSL.query_with_bindings(member_ast, [X: 3]) do
  {:ok, results} ->
    IO.puts("  Results: #{inspect(results)}")
  {:error, reason} ->
    IO.puts("  Error: #{inspect(reason)}")
end

# Factorial with pin operator
IO.puts("\n📌 Factorial with pin operator:")
factorial_ast = {:factorial, [], [{:^, [], [{:N, [], nil}]}, {:Result, [], nil}]}
case Swiex.DSL.query_with_bindings(factorial_ast, [N: 5]) do
  {:ok, results} ->
    IO.puts("  factorial(5, Result): #{inspect(results)}")
  {:error, reason} ->
    IO.puts("  Error: #{inspect(reason)}")
end

IO.puts("")

# 2. Streaming Results
IO.puts("🌊 2. Streaming Results")
IO.puts("-" |> String.duplicate(30))

# Basic streaming
IO.puts("\n🌊 Basic streaming:")
stream = Swiex.Stream.query_stream("member(X, [1,2,3,4,5])")
results = stream |> Enum.to_list()
IO.puts("  Stream results: #{inspect(results)}")

# Streaming with transformations
IO.puts("\n🌊 Streaming with transformations:")
transformed = stream
  |> Stream.map(fn result -> result["X"] end)
  |> Stream.filter(fn x -> rem(x, 2) == 0 end)  # Only even numbers
  |> Enum.to_list()
IO.puts("  Even numbers only: #{inspect(transformed)}")

# Streaming with custom chunk size
IO.puts("\n🌊 Streaming with custom chunk size:")
chunked_stream = Swiex.Stream.query_stream("member(X, [1,2,3,4,5])", 2)
chunked_results = chunked_stream |> Enum.to_list()
IO.puts("  Chunked results: #{inspect(chunked_results)}")

# Streaming with bindings
IO.puts("\n🌊 Streaming with bindings:")
binding_stream = Swiex.Stream.query_stream_with_bindings(member_ast, [X: 3], 2)
binding_results = binding_stream |> Enum.to_list()
IO.puts("  Binding stream results: #{inspect(binding_results)}")

IO.puts("")

# 3. Transaction Support
IO.puts("💼 3. Transaction Support")
IO.puts("-" |> String.duplicate(30))

# Simple transaction
IO.puts("\n💼 Simple transaction:")
case Swiex.Transaction.transaction(fn session ->
  Swiex.MQI.assertz(session, "person(alice, 28)")
  Swiex.MQI.assertz(session, "person(david, 32)")
  {:ok, "Both persons added"}
end) do
  {:ok, message} ->
    IO.puts("  ✅ #{message}")
  {:error, reason} ->
    IO.puts("  ❌ Error: #{inspect(reason)}")
end

# Verify the transaction worked
case Swiex.MQI.query("person(alice, Age)") do
  {:ok, results} ->
    IO.puts("  alice age: #{inspect(results)}")
  {:error, reason} ->
    IO.puts("  Error: #{inspect(reason)}")
end

# Batch operations
IO.puts("\n💼 Batch operations:")
operations = [
  {"person(emma, 27)", :assertz},
  {"person(frank, 29)", :assertz},
  {"person(emma, Age)", :query}
]

case Swiex.Transaction.batch(operations) do
  {:ok, results} ->
    IO.puts("  ✅ Batch results: #{inspect(results)}")
  {:error, reason} ->
    IO.puts("  ❌ Error: #{inspect(reason)}")
end

# Transaction with error (rollback)
IO.puts("\n💼 Transaction with error (rollback):")
case Swiex.Transaction.transaction(fn session ->
  Swiex.MQI.assertz(session, "person(grace, 31)")
  # This will cause an error and trigger rollback
  Swiex.MQI.query(session, "invalid_predicate(X)")
  {:ok, "Should not reach here"}
end) do
  {:ok, message} ->
    IO.puts("  ✅ #{message}")
  {:error, reason} ->
    IO.puts("  ❌ Transaction failed (expected): #{inspect(reason)}")
end

# Verify rollback worked
case Swiex.MQI.query("person(grace, Age)") do
  {:ok, results} ->
    IO.puts("  grace age: #{inspect(results)}")
  {:ok, []} ->
    IO.puts("  ✅ grace was not added (rollback worked)")
  {:error, reason} ->
    IO.puts("  Error: #{inspect(reason)}")
end

IO.puts("")
IO.puts("🎉 Demo completed successfully!")
IO.puts("=" |> String.duplicate(50))
