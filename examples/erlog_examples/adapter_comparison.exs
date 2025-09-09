#!/usr/bin/env elixir

"""
Erlog vs Other Adapters Comparison

This example shows how Erlog compares to other Prolog adapters
available in the Swiex ecosystem.
"""

# Add the parent directory to the path
Code.prepend_path("../../_build/dev/lib/swiex/ebin")

alias Swiex.Adapters.{ErlogAdapter, SwiAdapter, ScryerAdapter}

IO.puts("🧠 Erlog Adapter Comparison")
IO.puts("=" |> String.duplicate(40))

# Test queries to compare
test_queries = [
  "true",
  "fail", 
  "X = 1",
  "X is 1 + 1",
  "member(X, [1,2,3])"
]

adapters = [
  {ErlogAdapter, "Erlog (Embedded)"},
  {SwiAdapter, "SWI-Prolog (External)"},
  {ScryerAdapter, "Scryer Prolog (External)"}
]

IO.puts("\n📋 Adapter Health Check:")
for {adapter, name} <- adapters do
  case adapter.health_check() do
    {:ok, :ready} ->
      IO.puts("  ✅ #{name}: Available")
    {:error, reason} ->
      IO.puts("  ❌ #{name}: #{inspect(reason)}")
  end
end

IO.puts("\n📋 Query Comparison:")
for query <- test_queries do
  IO.puts("\n  Query: #{query}")
  
  for {adapter, name} <- adapters do
    case adapter.health_check() do
      {:ok, :ready} ->
        case adapter.query(query) do
          {:ok, results} ->
            IO.puts("    #{name}: #{inspect(results)} ✅")
          {:error, {:unsupported_query, _}} ->
            IO.puts("    #{name}: Unsupported")
          {:error, {:adapter_not_available, _}} ->
            IO.puts("    #{name}: Not Available")
          {:error, reason} ->
            IO.puts("    #{name}: Error - #{inspect(reason)}")
        end
      {:error, _} ->
        IO.puts("    #{name}: Not Available")
    end
  end
end

IO.puts("\n💡 Comparison Summary:")
IO.puts("  📊 Capability Levels:")
IO.puts("    🥇 SWI-Prolog: Full Prolog implementation")
IO.puts("    🥈 Scryer Prolog: Modern ISO-compliant Prolog")  
IO.puts("    🥉 Erlog: Basic embedded logic queries")

IO.puts("\n  🏗️  Architecture:")
IO.puts("    • SWI-Prolog: External process via MQI protocol")
IO.puts("    • Scryer Prolog: External process via subprocess")
IO.puts("    • Erlog: Embedded Erlang/Elixir library")

IO.puts("\n  🎯 Use Cases:")
IO.puts("    • SWI-Prolog: Full Prolog applications")
IO.puts("    • Scryer Prolog: Modern Prolog with good performance")
IO.puts("    • Erlog: Simple embedded logic, no external deps")

IO.puts("\n✅ Comparison completed!")