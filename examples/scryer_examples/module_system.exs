#!/usr/bin/env elixir

"""
Scryer Prolog Module System

This example demonstrates how to use Scryer Prolog's module system
to access built-in predicates and libraries. Scryer follows ISO Prolog
standards and requires explicit module loading for many features.
"""

# Add the parent directory to the path
Code.prepend_path("../../_build/dev/lib/swiex/ebin")

alias Swiex.Adapters.ScryerAdapter

IO.puts("🦀 Scryer Prolog Module System")
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

# Example 1: Loading the lists library
IO.puts("\n📋 Example 1: Loading Library Modules")
IO.puts("Loading the lists library for list predicates:")

case ScryerAdapter.query(session, "use_module(library(lists))") do
  {:ok, results} ->
    IO.puts("  ✅ Loaded lists library: #{inspect(results)}")
  {:error, reason} ->
    IO.puts("  ❌ Failed to load lists library: #{inspect(reason)}")
end

# Now we can use list predicates
IO.puts("\nTesting list predicates after loading library:")
list_queries = [
  "is_list([1,2,3])",
  "is_list(hello)",
  "member(2, [1,2,3])",
  "member(X, [a,b,c])"
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

# Example 2: Loading the arithmetic library
IO.puts("\n📋 Example 2: Loading Arithmetic Module")
IO.puts("Loading arithmetic predicates:")

case ScryerAdapter.query(session, "use_module(library(arithmetic))") do
  {:ok, results} ->
    IO.puts("  ✅ Loaded arithmetic library: #{inspect(results)}")
  {:error, reason} ->
    IO.puts("  ❌ Failed to load arithmetic library: #{inspect(reason)}")
    IO.puts("  💡 Note: Some arithmetic may be built-in")
end

# Test arithmetic predicates
arithmetic_queries = [
  "succ(5, X)",  # successor function
  "plus(3, 4, X)",  # addition
  "between(1, 5, X)"  # generate numbers between range
]

for query <- arithmetic_queries do
  case ScryerAdapter.query(session, query) do
    {:ok, results} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Result: #{inspect(results)} ✅")
    {:error, reason} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Error: #{inspect(reason)} (may not be available)")
  end
end

# Example 3: Loading the format library
IO.puts("\n📋 Example 3: Format and I/O Module")
IO.puts("Loading format library:")

case ScryerAdapter.query(session, "use_module(library(format))") do
  {:ok, results} ->
    IO.puts("  ✅ Loaded format library: #{inspect(results)}")
  {:error, reason} ->
    IO.puts("  ❌ Failed to load format library: #{inspect(reason)}")
end

# Example 4: Demonstrating module-based predicates
IO.puts("\n📋 Example 4: Built-in vs Module Predicates")

# These should work without modules (built-in)
builtin_queries = [
  "atom(hello)",
  "number(42)",
  "var(X)",
  "nonvar(hello)"
]

IO.puts("Testing built-in type predicates (no module needed):")
for query <- builtin_queries do
  case ScryerAdapter.query(session, query) do
    {:ok, results} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Result: #{inspect(results)} ✅")
    {:error, reason} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Error: #{inspect(reason)} ❌")
  end
end

# Example 5: Creating our own module predicates
IO.puts("\n📋 Example 5: Custom Module-style Predicates")
IO.puts("Defining utility predicates that work like modules:")

utility_rules = [
  # List utilities
  "last([X], X)",
  "last([_|T], X) :- last(T, X)",
  
  # Math utilities
  "square(X, Y) :- Y is X * X",
  "even(X) :- 0 is X mod 2",
  "odd(X) :- 1 is X mod 2",
  
  # String/atom utilities  
  "longer_than([], N) :- N < 0",
  "longer_than([_|T], N) :- N1 is N - 1, longer_than(T, N1)"
]

IO.puts("Adding custom utility predicates:")
for rule <- utility_rules do
  case ScryerAdapter.assertz(session, rule) do
    {:ok, updated_session} ->
      IO.puts("  ✅ Added: #{rule}")
      session = updated_session
    {:error, reason} ->
      IO.puts("  ❌ Failed: #{rule} - #{inspect(reason)}")
  end
end

# Test custom utilities
IO.puts("\nTesting custom utility predicates:")
utility_queries = [
  "last([1,2,3,4], X)",
  "square(7, X)", 
  "even(4)",
  "odd(5)",
  "longer_than([a,b,c], 2)"
]

for query <- utility_queries do
  case ScryerAdapter.query(session, query) do
    {:ok, results} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Result: #{inspect(results)} ✅")
    {:error, reason} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Error: #{inspect(reason)} ❌")
  end
end

# Example 6: Available modules in Scryer
IO.puts("\n📋 Example 6: Exploring Available Modules")
IO.puts("Common Scryer Prolog modules to try:")

modules_to_try = [
  "library(lists)",
  "library(arithmetic)", 
  "library(format)",
  "library(dcgs)",
  "library(iso_ext)",
  "library(debug)"
]

for module <- modules_to_try do
  case ScryerAdapter.query(session, "use_module(#{module})") do
    {:ok, _results} ->
      IO.puts("  ✅ Available: #{module}")
    {:error, reason} ->
      IO.puts("  ❌ Not available: #{module} - #{inspect(reason)}")
  end
end

# Clean up
:ok = ScryerAdapter.stop_session(session)

IO.puts("\n💡 Module System Key Points:")
IO.puts("  🔧 Scryer follows ISO Prolog module system")
IO.puts("  📚 Built-in predicates: atom/1, number/1, var/1, etc.")
IO.puts("  📦 Library predicates need: use_module(library(name))")
IO.puts("  ⚡ Load modules before using their predicates")
IO.puts("  🎯 Common libraries: lists, arithmetic, format, dcgs")

IO.puts("\n🎯 Best Practices:")
IO.puts("  • Load required modules at session start")
IO.puts("  • Define custom predicates for missing functionality")  
IO.puts("  • Check module availability before use")
IO.puts("  • Use built-ins when possible for better performance")

IO.puts("\n✅ Module system examples completed!")