#!/usr/bin/env elixir

# Simple test script for Prolog adapters
Mix.install([
  {:swiex, path: "../.."},
  {:erlog, github: "rvirding/erlog", branch: "develop"}
])

defmodule PrologAdapterTest do
  alias Swiex.Prolog
  alias Swiex.Adapters.{SwiAdapter, ErlogAdapter, ScryerAdapter}

  def test_all do
    IO.puts("\n🧠 Testing Prolog Adapter System")
    IO.puts("================================")
    
    # Test adapter listing
    IO.puts("\n📋 Available Adapters:")
    adapters = Prolog.list_adapters()
    for %{adapter: adapter, info: info, health: health} <- adapters do
      status_emoji = if health == :ok, do: "✅", else: "❌"
      IO.puts("  #{status_emoji} #{info.name} (#{info.type}) - #{adapter}")
    end
    
    # Test basic queries
    test_basic_queries()
    
    # Test session management if available
    test_sessions()
  end
  
  def test_basic_queries do
    IO.puts("\n🔍 Testing Basic Queries")
    IO.puts("------------------------")
    
    # Test with available adapters
    working_adapters = Enum.filter([SwiAdapter, ErlogAdapter], fn adapter ->
      case adapter.health_check() do
        {:ok, :ready} -> true
        _ -> false
      end
    end)
    
    for adapter <- working_adapters do
      info = adapter.info()
      IO.puts("\n🧪 Testing #{info.name}...")
      
      # Test simple true query
      case Prolog.query("true", adapter: adapter) do
        {:ok, results} ->
          IO.puts("  ✅ true query: #{inspect(results)}")
        {:error, reason} ->
          IO.puts("  ❌ true query failed: #{inspect(reason)}")
      end
      
      # Test simple fail query - should return empty list
      case Prolog.query("fail", adapter: adapter) do
        {:ok, []} ->
          IO.puts("  ✅ fail query returned empty list")
        {:ok, results} ->
          IO.puts("  ⚠️  fail query returned: #{inspect(results)}")
        {:error, reason} ->
          IO.puts("  ❌ fail query failed: #{inspect(reason)}")
      end
    end
    
    if working_adapters == [] do
      IO.puts("  ⚠️  No working adapters found for testing")
    end
  end
  
  def test_sessions do
    IO.puts("\n🔗 Testing Session Management")
    IO.puts("-----------------------------")
    
    # Test SWI-Prolog sessions if available
    case SwiAdapter.health_check() do
      {:ok, :ready} ->
        IO.puts("\n💡 Testing SWI-Prolog sessions...")
        test_swi_sessions()
      {:error, reason} ->
        IO.puts("  ⚠️  SWI-Prolog not available: #{inspect(reason)}")
    end
    
    # Test Erlog sessions if available  
    case ErlogAdapter.health_check() do
      {:ok, :ready} ->
        IO.puts("\n🔬 Testing Erlog sessions...")
        test_erlog_sessions()
      {:error, reason} ->
        IO.puts("  ⚠️  Erlog not available: #{inspect(reason)}")
    end
  end
  
  def test_swi_sessions do
    case Prolog.start_session(adapter: SwiAdapter) do
      {:ok, session} ->
        IO.puts("  ✅ Started SWI session")
        
        # Test assertion
        case Prolog.assertz(session, "likes(john, pizza)") do
          {:ok, updated_session} ->
            IO.puts("  ✅ Asserted fact: likes(john, pizza)")
            
            # Test query on asserted fact
            case Prolog.query(updated_session, "likes(john, X)") do
              {:ok, results} ->
                IO.puts("  ✅ Query result: #{inspect(results)}")
              {:error, reason} ->
                IO.puts("  ❌ Query failed: #{inspect(reason)}")
            end
            
            # Cleanup
            Prolog.stop_session(updated_session)
            IO.puts("  ✅ Stopped SWI session")
          {:error, reason} ->
            IO.puts("  ❌ Assertion failed: #{inspect(reason)}")
            Prolog.stop_session(session)
        end
      {:error, reason} ->
        IO.puts("  ❌ Failed to start SWI session: #{inspect(reason)}")
    end
  end
  
  def test_erlog_sessions do
    case Prolog.start_session(adapter: ErlogAdapter) do
      {:ok, session} ->
        IO.puts("  ✅ Started Erlog session")
        
        # Test simple query
        case Prolog.query(session, "true") do
          {:ok, results} ->
            IO.puts("  ✅ Simple query result: #{inspect(results)}")
          {:error, reason} ->
            IO.puts("  ❌ Simple query failed: #{inspect(reason)}")
        end
        
        # Cleanup
        Prolog.stop_session(session)
        IO.puts("  ✅ Stopped Erlog session")
      {:error, reason} ->
        IO.puts("  ❌ Failed to start Erlog session: #{inspect(reason)}")
    end
  end
end

# Run the tests
PrologAdapterTest.test_all()

IO.puts("\n🎉 Test completed!")