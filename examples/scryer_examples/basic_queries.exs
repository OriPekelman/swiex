#!/usr/bin/env elixir

"""
Basic Scryer Prolog Usage Examples

This example demonstrates the capabilities of the Scryer Prolog adapter.
Scryer Prolog is a modern, fast, ISO-compliant Prolog implementation 
written in Rust with excellent performance and standards compliance.
"""

# Add the parent directory to the path so we can use Swiex
Code.prepend_path("../../_build/dev/lib/swiex/ebin")

alias Swiex.Adapters.ScryerAdapter

IO.puts("🦀 Scryer Prolog Basic Usage Examples")
IO.puts("=" |> String.duplicate(40))

# Check if Scryer Prolog is available
case ScryerAdapter.health_check() do
  {:ok, :ready} ->
    IO.puts("✅ Scryer Prolog is available")
  {:error, {:scryer_not_found, _}} ->
    IO.puts("❌ Scryer Prolog not found")
    IO.puts("💡 Install: https://github.com/mthom/scryer-prolog")
    System.halt(1)
  {:error, reason} ->
    IO.puts("❌ Scryer Prolog error: #{inspect(reason)}")
    System.halt(1)
end

# Start a session
{:ok, session} = ScryerAdapter.start_session()
IO.puts("✅ Scryer Prolog session started")

# Example 1: Basic truth queries
IO.puts("\n📋 Example 1: Basic Truth Queries")
basic_queries = ["true", "false"]

for query <- basic_queries do
  case ScryerAdapter.query(session, query) do
    {:ok, results} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Result: #{inspect(results)} ✅")
    {:error, reason} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Error: #{inspect(reason)} ❌")
  end
end

# Example 2: Arithmetic queries
IO.puts("\n📋 Example 2: Arithmetic Queries")
IO.puts("Scryer Prolog supports full arithmetic:")

arithmetic_queries = [
  "X is 1 + 1",
  "X is 5 * 3", 
  "X is 10 / 2",
  "X is 7 - 3",
  "X is 2 ** 3"
]

for query <- arithmetic_queries do
  case ScryerAdapter.query(session, query) do
    {:ok, results} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Result: #{inspect(results)} ✅")
    {:error, reason} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Error: #{inspect(reason)} ❌")
  end
end

# Example 3: Variable unification
IO.puts("\n📋 Example 3: Variable Unification")
unification_queries = [
  "X = hello",
  "X = 42", 
  "X = [1,2,3]"
]

for query <- unification_queries do
  case ScryerAdapter.query(session, query) do
    {:ok, results} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Result: #{inspect(results)} ✅")
    {:error, reason} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Error: #{inspect(reason)} ❌")
  end
end

# Example 4: Fact assertion and querying
IO.puts("\n📋 Example 4: Fact Assertion and Querying")

# Assert some facts
facts = [
  "likes(mary, pizza)",
  "likes(john, pasta)",
  "likes(mary, pasta)"
]

IO.puts("Asserting facts:")
for fact <- facts do
  case ScryerAdapter.assertz(session, fact) do
    {:ok, updated_session} ->
      IO.puts("  ✅ Asserted: #{fact}")
      session = updated_session
    {:error, reason} ->
      IO.puts("  ❌ Failed to assert #{fact}: #{inspect(reason)}")
  end
end

IO.puts("\nQuerying facts:")
fact_queries = [
  "likes(mary, X)",
  "likes(X, pasta)",
  "likes(john, pizza)"
]

for query <- fact_queries do
  case ScryerAdapter.query(session, query) do
    {:ok, results} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Result: #{inspect(results)} ✅")
    {:error, reason} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Error: #{inspect(reason)} ❌")
  end
end

# Example 5: Comparison operations
IO.puts("\n📋 Example 5: Comparison Operations")
comparison_queries = [
  "5 > 3",
  "2 < 10",
  "1 + 1 =:= 2",
  "3 * 2 =\\= 7"
]

for query <- comparison_queries do
  case ScryerAdapter.query(session, query) do
    {:ok, results} ->
      status = if results == [%{}], do: "✅ (true)", else: "❌ (false)"
      IO.puts("  Query: #{query}")
      IO.puts("  Result: #{status}")
    {:error, reason} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Error: #{inspect(reason)} ❌")
  end
end

# Example 6: Testing predicates that need modules
IO.puts("\n📋 Example 6: Testing Module-based Predicates")
IO.puts("Some predicates require loading modules first:")

# Try to load the lists module
IO.puts("Loading lists module...")
case ScryerAdapter.query(session, "use_module(library(lists))") do
  {:ok, _} ->
    IO.puts("  ✅ Lists module loaded")
    
    # Now test list predicates
    list_queries = [
      "member(2, [1,2,3])",
      "is_list([1,2,3])", 
      "is_list(hello)"
    ]
    
    for query <- list_queries do
      case ScryerAdapter.query(session, query) do
        {:ok, results} ->
          IO.puts("  Query: #{query}")
          IO.puts("  Result: #{inspect(results)} ✅")
        {:error, reason} ->
          IO.puts("  Query: #{query}")
          IO.puts("  Error: #{inspect(reason)}")
      end
    end
  {:error, reason} ->
    IO.puts("  ⚠️  Could not load lists module: #{inspect(reason)}")
    IO.puts("  💡 List predicates need to be defined manually")
end

# Clean up
:ok = ScryerAdapter.stop_session(session)

IO.puts("\n💡 Key Takeaways:")
IO.puts("  • Scryer Prolog is ISO-compliant and feature-rich")
IO.puts("  • Excellent arithmetic and comparison support")
IO.puts("  • Variable unification works perfectly")
IO.puts("  • Fact assertion and querying supported") 
IO.puts("  • Uses module system: use_module(library(name))")
IO.puts("  • Some predicates need explicit module loading")
IO.puts("  • Fast performance with Rust implementation")

IO.puts("\n✅ Scryer Prolog examples completed!")