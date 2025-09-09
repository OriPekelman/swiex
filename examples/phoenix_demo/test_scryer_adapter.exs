#!/usr/bin/env elixir

# Simple test for ScryerAdapter

IO.puts("🧠 Testing ScryerAdapter")
IO.puts("=" |> String.duplicate(50))

alias Swiex.Adapters.ScryerAdapter

# Test 1: Check if Scryer is available
IO.puts("\n📋 Testing Scryer availability...")
case ScryerAdapter.health_check() do
  {:ok, :ready} ->
    IO.puts("  ✅ Scryer Prolog is available and ready")
  {:error, {:scryer_not_found, msg}} ->
    IO.puts("  ❌ Scryer Prolog not found: #{msg}")
    IO.puts("  💡 Install Scryer Prolog: https://github.com/mthom/scryer-prolog")
    System.halt(1)
  {:error, reason} ->
    IO.puts("  ❌ Scryer health check failed: #{inspect(reason)}")
    System.halt(1)
end

# Test 2: Session management
IO.puts("\n🔧 Testing ScryerAdapter session management...")
case ScryerAdapter.start_session() do
  {:ok, session} ->
    IO.puts("  ✅ Started Scryer session: #{inspect(session.session_id)}")
    
    # Test 3: Basic queries
    IO.puts("\n🧪 Testing basic queries...")
    
    # Test true query
    case ScryerAdapter.query(session, "true") do
      {:ok, results} ->
        IO.puts("  ✅ 'true' query succeeded: #{inspect(results)}")
      {:error, reason} ->
        IO.puts("  ❌ 'true' query failed: #{inspect(reason)}")
    end
    
    # Test arithmetic query (should work with Scryer)
    case ScryerAdapter.query(session, "X is 1 + 1") do
      {:ok, results} ->
        IO.puts("  ✅ Arithmetic 'X is 1 + 1' succeeded: #{inspect(results)}")
      {:error, reason} ->
        IO.puts("  ❌ Arithmetic 'X is 1 + 1' failed: #{inspect(reason)}")
    end
    
    # Test standard Prolog query
    case ScryerAdapter.query(session, "member(X, [1,2,3])") do
      {:ok, results} ->
        IO.puts("  ✅ Standard query 'member(X, [1,2,3])' succeeded: #{inspect(results)}")
      {:error, reason} ->
        IO.puts("  ❌ Standard query 'member(X, [1,2,3])' failed: #{inspect(reason)}")
    end
    
    # Test fact assertion
    case ScryerAdapter.assertz(session, "likes(john, pizza)") do
      {:ok, updated_session} ->
        IO.puts("  ✅ Asserted fact: likes(john, pizza)")
        
        # Query the asserted fact
        case ScryerAdapter.query(updated_session, "likes(john, X)") do
          {:ok, results} ->
            IO.puts("  ✅ Query asserted fact succeeded: #{inspect(results)}")
          {:error, reason} ->
            IO.puts("  ❌ Query asserted fact failed: #{inspect(reason)}")
        end
      {:error, reason} ->
        IO.puts("  ❌ Assert fact failed: #{inspect(reason)}")
    end
    
    # Cleanup
    :ok = ScryerAdapter.stop_session(session)
    IO.puts("  ✅ Stopped Scryer session")
    
  {:error, reason} ->
    IO.puts("  ❌ Failed to start Scryer session: #{inspect(reason)}")
end

IO.puts("\n✅ ScryerAdapter test completed!")