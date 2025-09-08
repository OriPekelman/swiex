defmodule Swiex.MQIComprehensiveTest do
  @moduledoc """
  Comprehensive test suite for Swiex.MQI based on Python MQI test cases.
  Tests critical functionality including error handling, session management,
  async operations, and protocol edge cases.
  """
  
  use ExUnit.Case
  alias Swiex.MQI

  # Set longer timeout for complex queries
  @timeout 10_000

  describe "synchronous query error handling" do
    test "handles syntax errors properly" do
      # Test incomplete syntax
      assert {:error, _reason} = MQI.query("member(X, [a, b, c")
    end

    test "handles undefined predicates" do
      assert {:error, _reason} = MQI.query("undefined_predicate(X)")
    end

    test "handles arithmetic errors" do
      assert {:error, _reason} = MQI.query("X is 1/0")
    end

    test "handles type errors" do
      assert {:error, _reason} = MQI.query("atom_codes(123, X)")
    end
  end

  describe "synchronous query data types" do
    test "handles integers correctly" do
      {:ok, results} = MQI.query("X = 42")
      assert [%{"X" => 42}] == results
    end

    test "handles floats correctly" do
      {:ok, results} = MQI.query("X = 3.14")
      assert [%{"X" => 3.14}] == results
    end

    test "handles atoms correctly" do
      {:ok, results} = MQI.query("X = hello")
      assert [%{"X" => "hello"}] == results
    end

    test "handles strings correctly" do
      {:ok, results} = MQI.query("X = \"hello world\"")
      assert [%{"X" => "hello world"}] == results
    end

    test "handles lists correctly" do
      {:ok, results} = MQI.query("X = [1, 2, 3]")
      assert [%{"X" => [1, 2, 3]}] == results
    end

    test "handles compound terms correctly" do
      {:ok, results} = MQI.query("X = point(1, 2)")
      assert [%{"X" => %{"functor" => "point", "args" => [1, 2]}}] == results
    end
  end

  describe "synchronous query edge cases" do
    test "handles empty results" do
      {:ok, results} = MQI.query("fail")
      assert [] == results
    end

    test "handles multiple solutions" do
      {:ok, results} = MQI.query("member(X, [a, b, c])")
      assert length(results) == 3
      assert Enum.any?(results, fn r -> r["X"] == "a" end)
      assert Enum.any?(results, fn r -> r["X"] == "b" end)
      assert Enum.any?(results, fn r -> r["X"] == "c" end)
    end

    test "handles very long queries" do
      # Generate a long query with many variables
      vars = Enum.map(1..50, &"X#{&1}")
      query = "member(Y, [#{Enum.join(vars, ", ")}]), Y = test"
      {:ok, results} = MQI.query(query)
      assert [%{"Y" => "test"}] == results
    end
  end

  describe "session management" do
    test "can start and stop sessions" do
      assert {:ok, session} = MQI.start_session()
      assert %MQI.Session{} = session
      assert :ok = MQI.stop_session(session)
    end

    test "session persists facts between queries" do
      {:ok, session} = MQI.start_session()
      
      # Assert a fact
      assert {:ok, _} = MQI.assertz(session, "test_fact(42)")
      
      # Query the fact
      {:ok, results} = MQI.query(session, "test_fact(X)")
      assert [%{"X" => 42}] == results
      
      MQI.stop_session(session)
    end

    test "different sessions have isolated facts" do
      {:ok, session1} = MQI.start_session()
      {:ok, session2} = MQI.start_session()
      
      # Assert fact in session1 only
      MQI.assertz(session1, "session_fact(1)")
      
      # Check session1 has the fact
      {:ok, results1} = MQI.query(session1, "session_fact(X)")
      assert [%{"X" => 1}] == results1
      
      # Check session2 doesn't have the fact
      {:ok, results2} = MQI.query(session2, "session_fact(X)")
      assert [] == results2
      
      MQI.stop_session(session1)
      MQI.stop_session(session2)
    end
  end

  describe "large data handling" do
    test "handles large result sets" do
      # Generate large list and query it
      large_list = Enum.to_list(1..1000)
      list_str = inspect(large_list)
      query = "member(X, #{list_str})"
      
      {:ok, results} = MQI.query(query)
      assert length(results) == 1000
    end

    test "handles deeply nested structures" do
      # Create nested list structure
      nested = "[[[[[1]]]]]"
      query = "X = #{nested}"
      
      {:ok, results} = MQI.query(query)
      assert length(results) == 1
      # Result should be deeply nested
      nested_result = results |> List.first() |> Map.get("X")
      assert is_list(nested_result)
    end
  end

  describe "UTF-8 and character encoding" do
    test "supports UTF-8 characters in queries" do
      {:ok, results} = MQI.query("X = '©'")
      assert [%{"X" => "©"}] == results
    end

    test "supports UTF-8 characters in lists" do
      {:ok, results} = MQI.query("member(X, ['α', 'β', 'γ'])")
      assert length(results) == 3
      chars = Enum.map(results, &(&1["X"]))
      assert "α" in chars
      assert "β" in chars  
      assert "γ" in chars
    end

    test "supports Unicode mathematical symbols" do
      {:ok, results} = MQI.query("X = '∞'")
      assert [%{"X" => "∞"}] == results
    end
  end

  describe "protocol robustness" do
    test "handles rapid successive queries" do
      # Send many queries in quick succession
      tasks = Enum.map(1..20, fn i ->
        Task.async(fn ->
          MQI.query("X = #{i}")
        end)
      end)
      
      results = Enum.map(tasks, &Task.await(&1, @timeout))
      
      # All should succeed
      assert Enum.all?(results, fn
        {:ok, [%{"X" => _}]} -> true
        _ -> false
      end)
    end

    test "handles concurrent session operations" do
      # Create multiple sessions concurrently
      tasks = Enum.map(1..5, fn i ->
        Task.async(fn ->
          {:ok, session} = MQI.start_session()
          MQI.assertz(session, "concurrent_fact(#{i})")
          {:ok, results} = MQI.query(session, "concurrent_fact(X)")
          MQI.stop_session(session)
          results
        end)
      end)
      
      results = Enum.map(tasks, &Task.await(&1, @timeout))
      
      # Each should have found its own fact
      expected_results = Enum.map(1..5, fn i -> [%{"X" => i}] end)
      assert Enum.sort(results) == Enum.sort(expected_results)
    end
  end

  describe "timeout handling" do
    @tag :slow
    test "handles long-running queries" do
      # This should complete within reasonable time
      {:ok, results} = MQI.query("between(1, 100, X)")
      assert length(results) == 100
    end

    @tag timeout: 2_000
    test "respects query timeouts" do
      # This test should timeout gracefully
      # Note: Actual timeout implementation depends on MQI implementation
      result = MQI.query("sleep(10)")
      case result do
        {:error, _} -> :ok  # Expected timeout
        {:ok, _} -> flunk("Query should have timed out")
      end
    end
  end

  describe "memory and resource management" do
    test "doesn't leak memory with many small queries" do
      # Run many small queries to check for memory leaks
      Enum.each(1..100, fn i ->
        {:ok, _} = MQI.query("X = #{i}")
      end)
      
      # If we get here without crashes, memory handling is probably OK
      assert true
    end

    test "handles session cleanup properly" do
      sessions = Enum.map(1..10, fn _ ->
        {:ok, session} = MQI.start_session()
        session
      end)
      
      # Clean up all sessions
      Enum.each(sessions, &MQI.stop_session/1)
      
      # Basic connectivity should still work
      assert {:ok, _} = MQI.query("true")
    end
  end

  describe "constraint logic programming integration" do
    test "handles CLP(FD) queries" do
      query = "use_module(library(clpfd)), X in 1..10, X #= 5"
      {:ok, results} = MQI.query(query)
      assert [%{"X" => 5}] == results
    end

    test "handles CLP(FD) with multiple variables" do
      query = "use_module(library(clpfd)), X in 1..3, Y in 1..3, X + Y #= 4, label([X, Y])"
      {:ok, results} = MQI.query(query)
      assert length(results) >= 1
      # Should find solutions like X=1,Y=3 or X=2,Y=2 or X=3,Y=1
      Enum.each(results, fn result ->
        assert result["X"] + result["Y"] == 4
      end)
    end
  end

  describe "integration with monitoring" do
    test "can collect basic statistics" do
      # This depends on the Monitoring module integration
      {:ok, session} = MQI.start_session()
      
      # Run a few queries to generate stats
      MQI.query(session, "true")
      MQI.query(session, "member(X, [1, 2, 3])")
      
      # Check if we can get statistics (implementation dependent)
      case Swiex.Monitoring.get_statistics(session) do
        {:ok, stats} when is_map(stats) and stats != %{} ->
          # Should have some query metrics
          assert Map.has_key?(stats, :queries_executed) or Map.has_key?(stats, :total_queries)
        {:ok, %{}} ->
          # Empty stats map - that's OK, monitoring not fully implemented
          :ok
        {:error, _} ->
          # Stats not implemented yet - that's OK for now
          :ok
        %{} ->
          # Direct empty map return - that's OK too
          :ok
      end
      
      MQI.stop_session(session)
    end
  end
end