#!/usr/bin/env elixir

# Simple test for ErlogAdapter without loading the entire Phoenix app
IO.puts("🧠 Testing ErlogAdapter with proper Erlang term formats")
IO.puts("=" |> String.duplicate(50))

alias Swiex.Adapters.ErlogAdapter

# Test 1: Basic Erlog availability
IO.puts("\n📋 Testing Erlog availability...")
try do
  {:ok, _} = :erlog.new()
  IO.puts("  ✅ Erlog is available")
rescue
  _ ->
    IO.puts("  ❌ Erlog is not available")
    System.halt(1)
end

# Test 2: ErlogAdapter session management
IO.puts("\n🔧 Testing ErlogAdapter session management...")
case ErlogAdapter.start_session() do
  {:ok, session} ->
    IO.puts("  ✅ Started ErlogAdapter session: #{inspect(session)}")
    
    # Test 3: Simple queries
    IO.puts("\n🧪 Testing simple queries...")
    
    # Test true query
    case ErlogAdapter.query(session, "true") do
      {:ok, results} ->
        IO.puts("  ✅ 'true' query succeeded: #{inspect(results)}")
      {:error, reason} ->
        IO.puts("  ❌ 'true' query failed: #{inspect(reason)}")
    end
    
    # Test fail query  
    case ErlogAdapter.query(session, "fail") do
      {:ok, results} ->
        IO.puts("  ✅ 'fail' query returned: #{inspect(results)}")
      {:error, reason} ->
        IO.puts("  ❌ 'fail' query failed: #{inspect(reason)}")
    end
    
    # Test standard Prolog query (should be unsupported to maintain MQI consistency)
    case ErlogAdapter.query(session, "member(X, [1,2,3])") do
      {:ok, results} ->
        IO.puts("  ⚠️ Standard query 'member(X, [1,2,3])' unexpectedly succeeded: #{inspect(results)}")
      {:error, {:unsupported_query, _}} ->
        IO.puts("  ✅ Standard query correctly returned :unsupported (consistent with MQI interface)")
      {:error, reason} ->
        IO.puts("  ❌ Standard query failed unexpectedly: #{inspect(reason)}")
    end
    
    # Test unsupported query
    case ErlogAdapter.query(session, "complex_unsupported_query(X, Y, Z)") do
      {:ok, results} ->
        IO.puts("  ✅ Unsupported query unexpectedly succeeded: #{inspect(results)}")
      {:error, {:unsupported_query, _}} ->
        IO.puts("  ✅ Unsupported query correctly returned :unsupported")
      {:error, reason} ->
        IO.puts("  ❌ Unsupported query failed unexpectedly: #{inspect(reason)}")
    end
    
    # Cleanup
    :ok = ErlogAdapter.stop_session(session)
    IO.puts("  ✅ Stopped ErlogAdapter session")
    
  {:error, reason} ->
    IO.puts("  ❌ Failed to start ErlogAdapter session: #{inspect(reason)}")
end

IO.puts("\n✅ ErlogAdapter test completed!")