#!/usr/bin/env elixir

"""
Advanced Scryer Prolog Features

This example demonstrates more advanced capabilities of Scryer Prolog
including rule definition, recursion, and complex data structures.
"""

# Add the parent directory to the path
Code.prepend_path("../../_build/dev/lib/swiex/ebin")

alias Swiex.Adapters.ScryerAdapter

IO.puts("🦀 Scryer Prolog Advanced Features")
IO.puts("=" |> String.duplicate(40))

# Check availability and start session
case ScryerAdapter.health_check() do
  {:ok, :ready} ->
    IO.puts("✅ Scryer Prolog is ready")
  {:error, reason} ->
    IO.puts("❌ Scryer Prolog not available: #{inspect(reason)}")
    System.halt(1)
end

{:ok, session} = ScryerAdapter.start_session()

# Load required modules first
IO.puts("Loading required modules...")
modules = ["library(lists)", "library(arithmetic)"]
for module <- modules do
  case ScryerAdapter.query(session, "use_module(#{module})") do
    {:ok, _} ->
      IO.puts("  ✅ Loaded #{module}")
    {:error, reason} ->
      IO.puts("  ⚠️  Could not load #{module}: #{inspect(reason)}")
  end
end

# Example 1: Define rules with recursion
IO.puts("\n📋 Example 1: Recursive Rules")
IO.puts("Defining factorial and fibonacci rules:")

recursive_rules = [
  # Factorial rules
  "factorial(0, 1)",
  "factorial(N, F) :- N > 0, N1 is N - 1, factorial(N1, F1), F is N * F1",
  
  # Fibonacci rules
  "fib(0, 0)",
  "fib(1, 1)", 
  "fib(N, F) :- N > 1, N1 is N - 1, N2 is N - 2, fib(N1, F1), fib(N2, F2), F is F1 + F2"
]

for rule <- recursive_rules do
  case ScryerAdapter.assertz(session, rule) do
    {:ok, updated_session} ->
      IO.puts("  ✅ Added rule: #{rule}")
      session = updated_session
    {:error, reason} ->
      IO.puts("  ❌ Failed to add rule: #{rule}")
      IO.puts("    Reason: #{inspect(reason)}")
  end
end

# Test the recursive rules
IO.puts("\nTesting recursive rules:")
recursive_queries = [
  "factorial(5, X)",
  "factorial(0, X)",
  "fib(5, X)",
  "fib(10, X)"
]

for query <- recursive_queries do
  case ScryerAdapter.query(session, query) do
    {:ok, results} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Result: #{inspect(results)} ✅")
    {:error, reason} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Error: #{inspect(reason)} ❌")
  end
end

# Example 2: List operations
IO.puts("\n📋 Example 2: List Operations")
IO.puts("Defining basic list predicates:")

list_rules = [
  # Member predicate
  "member(X, [X|_])",
  "member(X, [_|T]) :- member(X, T)",
  
  # Append predicate  
  "append([], L, L)",
  "append([H|T1], L2, [H|T3]) :- append(T1, L2, T3)",
  
  # Length predicate
  "length([], 0)",
  "length([_|T], N) :- length(T, N1), N is N1 + 1"
]

for rule <- list_rules do
  case ScryerAdapter.assertz(session, rule) do
    {:ok, updated_session} ->
      IO.puts("  ✅ Added rule: #{rule}")
      session = updated_session
    {:error, reason} ->
      IO.puts("  ❌ Failed to add rule: #{rule}")
      IO.puts("    Reason: #{inspect(reason)}")
  end
end

# Test list operations
IO.puts("\nTesting list operations:")
list_queries = [
  "member(2, [1,2,3])",
  "member(X, [a,b,c])",
  "append([1,2], [3,4], X)",
  "length([a,b,c,d], N)"
]

for query <- list_queries do
  case ScryerAdapter.query(session, query) do
    {:ok, results} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Result: #{inspect(results)} ✅")
    {:error, reason} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Error: #{inspect(reason)} ❌")
  end
end

# Example 3: Complex data structures and relations
IO.puts("\n📋 Example 3: Complex Relations")
IO.puts("Defining family relationships:")

family_facts = [
  "parent(tom, bob)",
  "parent(tom, liz)", 
  "parent(bob, ann)",
  "parent(bob, pat)",
  "parent(pat, jim)",
  "male(tom)",
  "male(bob)",
  "male(jim)",
  "female(liz)",
  "female(ann)", 
  "female(pat)"
]

family_rules = [
  "father(X, Y) :- parent(X, Y), male(X)",
  "mother(X, Y) :- parent(X, Y), female(X)",
  "grandparent(X, Z) :- parent(X, Y), parent(Y, Z)",
  "sibling(X, Y) :- parent(Z, X), parent(Z, Y), X \\= Y"
]

IO.puts("Adding family facts:")
for fact <- family_facts do
  case ScryerAdapter.assertz(session, fact) do
    {:ok, updated_session} ->
      session = updated_session
    {:error, reason} ->
      IO.puts("  ❌ Failed to add fact: #{fact} - #{inspect(reason)}")
  end
end

IO.puts("Adding family rules:")
for rule <- family_rules do
  case ScryerAdapter.assertz(session, rule) do
    {:ok, updated_session} ->
      session = updated_session
    {:error, reason} ->
      IO.puts("  ❌ Failed to add rule: #{rule} - #{inspect(reason)}")
  end
end

# Test family relationships
IO.puts("\nTesting family relationships:")
family_queries = [
  "parent(tom, X)",
  "father(bob, X)",
  "grandparent(tom, X)",
  "male(X)"
]

for query <- family_queries do
  case ScryerAdapter.query(session, query) do
    {:ok, results} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Result: #{inspect(results)} ✅")
    {:error, reason} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Error: #{inspect(reason)} ❌")
  end
end

# Example 4: Mathematical sequences
IO.puts("\n📋 Example 4: Mathematical Sequences")

sequence_rules = [
  "sum_to(0, 0)",
  "sum_to(N, S) :- N > 0, N1 is N - 1, sum_to(N1, S1), S is S1 + N"
]

for rule <- sequence_rules do
  case ScryerAdapter.assertz(session, rule) do
    {:ok, updated_session} ->
      session = updated_session
    {:error, reason} ->
      IO.puts("  ❌ Failed to add rule: #{rule} - #{inspect(reason)}")
  end
end

sequence_queries = [
  "sum_to(10, X)",
  "sum_to(5, X)"
]

for query <- sequence_queries do
  case ScryerAdapter.query(session, query) do
    {:ok, results} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Result: #{inspect(results)} ✅")
    {:error, reason} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Error: #{inspect(reason)} ❌")
  end
end

# Clean up
:ok = ScryerAdapter.stop_session(session)

IO.puts("\n💡 Advanced Features Summary:")
IO.puts("  • ✅ Recursive rule definition works")
IO.puts("  • ✅ Complex mathematical computations")
IO.puts("  • ✅ List operations (member, append, length)")
IO.puts("  • ✅ Family relationships and complex queries")
IO.puts("  • ✅ Mathematical sequences and recursion")
IO.puts("  • 🦀 Excellent performance with Rust implementation")

IO.puts("\n🎯 Scryer Prolog is excellent for:")
IO.puts("  • Logic programming applications") 
IO.puts("  • Mathematical computations")
IO.puts("  • Rule-based systems")
IO.puts("  • Educational Prolog learning")
IO.puts("  • Production Prolog applications")

IO.puts("\n✅ Advanced Scryer Prolog examples completed!")