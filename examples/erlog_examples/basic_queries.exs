#!/usr/bin/env elixir

"""
Basic Erlog Usage Examples

This example demonstrates the basic capabilities of the Erlog adapter.
Erlog is an embedded Prolog interpreter for Erlang/Elixir with limited
but useful functionality.
"""

# Add the parent directory to the path so we can use Swiex
Code.prepend_path("../../_build/dev/lib/swiex/ebin")

alias Swiex.Adapters.ErlogAdapter

IO.puts("🧠 Erlog Basic Usage Examples")
IO.puts("=" |> String.duplicate(40))

# Check if Erlog is available (only in phoenix_demo project)
case ErlogAdapter.health_check() do
  {:ok, :ready} ->
    IO.puts("✅ Erlog is available")
  {:error, reason} ->
    IO.puts("❌ Erlog not available: #{inspect(reason)}")
    IO.puts("💡 Note: Erlog is only available in the phoenix_demo project")
    System.halt(1)
end

# Example 1: Basic truth queries
IO.puts("\n📋 Example 1: Basic Truth Queries")
IO.puts("Erlog supports very basic logical queries:")

{:ok, session} = ErlogAdapter.start_session()

case ErlogAdapter.query(session, "true") do
  {:ok, results} ->
    IO.puts("  Query: true")
    IO.puts("  Result: #{inspect(results)} ✅")
  {:error, reason} ->
    IO.puts("  Query: true")
    IO.puts("  Error: #{inspect(reason)} ❌")
end

case ErlogAdapter.query(session, "fail") do
  {:ok, results} ->
    IO.puts("  Query: fail") 
    IO.puts("  Result: #{inspect(results)} (empty list means no solutions) ✅")
  {:error, reason} ->
    IO.puts("  Query: fail")
    IO.puts("  Error: #{inspect(reason)} ❌")
end

# Example 2: Unsupported queries
IO.puts("\n📋 Example 2: Unsupported Queries")
IO.puts("Most complex Prolog features are unsupported:")

test_queries = [
  "X = 1",
  "member(X, [1,2,3])",
  "factorial(5, N)",
  "append([1,2], [3,4], X)"
]

for query <- test_queries do
  case ErlogAdapter.query(session, query) do
    {:ok, results} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Result: #{inspect(results)} ✅")
    {:error, {:unsupported_query, msg}} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Result: Unsupported (as expected) ✅")
    {:error, reason} ->
      IO.puts("  Query: #{query}")
      IO.puts("  Error: #{inspect(reason)} ❌")
  end
end

# Example 3: Simple fact assertion  
IO.puts("\n📋 Example 3: Simple Fact Assertion")
IO.puts("Only very simple atom facts are supported:")

case ErlogAdapter.assertz(session, "hello") do
  {:ok, updated_session} ->
    IO.puts("  Asserted: hello ✅")
    
    # Try to query it (this might not work as expected)
    case ErlogAdapter.query(updated_session, "hello") do
      {:ok, results} ->
        IO.puts("  Query: hello")
        IO.puts("  Result: #{inspect(results)} ✅")
      {:error, reason} ->
        IO.puts("  Query: hello") 
        IO.puts("  Result: #{inspect(reason)} (expected - querying facts is complex)")
    end
  {:error, reason} ->
    IO.puts("  Failed to assert: #{inspect(reason)}")
end

# Clean up
:ok = ErlogAdapter.stop_session(session)

IO.puts("\n💡 Key Takeaways:")
IO.puts("  • Erlog is very limited but embedded")
IO.puts("  • Only supports basic true/fail queries")
IO.puts("  • Most Prolog features return :unsupported")
IO.puts("  • Best for simple logical validation")
IO.puts("  • No external dependencies required")

IO.puts("\n✅ Erlog examples completed!")