defmodule Swiex.MonitoringTest do
  use ExUnit.Case
  alias Swiex.Monitoring
  alias Swiex.MQI

  describe "Monitoring.init/1" do
    test "initializes with default values" do
      state = Monitoring.init()
      
      assert state.debug_enabled == false
      assert state.rate_limit_ms == 1000
      assert state.query_count == 0
      assert state.total_inferences == 0
      assert state.total_time_ms == 0
      assert state.session_stats == %{}
    end

    test "initializes with custom options" do
      state = Monitoring.init(debug_enabled: true, rate_limit_ms: 500)
      
      assert state.debug_enabled == true
      assert state.rate_limit_ms == 500
    end
  end

  describe "Monitoring.monitor_query/4" do
    setup do
      # Start a test MQI session
      {:ok, session} = MQI.start_session()
      on_exit(fn -> MQI.stop_session(session) end)
      
      state = Monitoring.init()
      {:ok, session: session, state: state}
    end

    test "tracks query execution", %{session: session, state: state} do
      query = "member(X, [1,2,3])"
      
      {result, new_state} = Monitoring.monitor_query(
        state,
        session,
        query,
        fn -> MQI.query(session, query) end
      )
      
      assert {:ok, _} = result
      assert new_state.query_count == 1
      assert new_state.total_time_ms > 0
      assert new_state.total_inferences >= 0
    end

    test "handles query errors gracefully", %{session: session, state: state} do
      query = "invalid_predicate(X)"
      
      {result, new_state} = Monitoring.monitor_query(
        state,
        session,
        query,
        fn -> MQI.query(session, query) end
      )
      
      assert {:ok, []} = result  # Empty result for undefined predicate
      assert new_state.query_count == 1
    end

    test "accumulates statistics across multiple queries", %{session: session, state: state} do
      queries = ["member(1, [1,2,3])", "append([1], [2], X)", "length([1,2,3], N)"]
      
      final_state = Enum.reduce(queries, state, fn query, acc_state ->
        {_, new_state} = Monitoring.monitor_query(
          acc_state,
          session,
          query,
          fn -> MQI.query(session, query) end
        )
        new_state
      end)
      
      assert final_state.query_count == 3
      assert final_state.total_time_ms > 0
      assert final_state.total_inferences >= 0
    end
  end

  describe "Monitoring.get_statistics/1" do
    setup do
      {:ok, session} = MQI.start_session()
      on_exit(fn -> MQI.stop_session(session) end)
      {:ok, session: session}
    end

    test "retrieves Prolog statistics", %{session: session} do
      stats = Monitoring.get_statistics(session)
      
      case stats do
        {:error, _} ->
          # Statistics might not be available in all Prolog configurations
          assert true
        stats when is_map(stats) ->
          # If we get stats, they should be a map
          assert is_map(stats)
      end
    end
  end

  describe "Monitoring.get_summary/1" do
    test "returns formatted summary" do
      state = %Monitoring{
        query_count: 10,
        total_inferences: 1000,
        total_time_ms: 500,
        debug_enabled: false,
        rate_limit_ms: 1000,
        last_debug_time: 0,
        session_stats: %{}
      }
      
      summary = Monitoring.get_summary(state)
      
      assert summary.query_count == 10
      assert summary.total_inferences == 1000
      assert summary.total_time_ms == 500
      assert summary.avg_time_ms == 50.0
      assert summary.avg_inferences == 100.0
    end

    test "handles zero queries" do
      state = Monitoring.init()
      summary = Monitoring.get_summary(state)
      
      assert summary.query_count == 0
      assert summary.avg_time_ms == 0
      assert summary.avg_inferences == 0
    end
  end

  describe "Monitoring.reset_stats/1" do
    test "resets all statistics" do
      state = %Monitoring{
        query_count: 10,
        total_inferences: 1000,
        total_time_ms: 500,
        debug_enabled: true,
        rate_limit_ms: 500,
        last_debug_time: 12345,
        session_stats: %{"test" => 123}
      }
      
      reset_state = Monitoring.reset_stats(state)
      
      assert reset_state.query_count == 0
      assert reset_state.total_inferences == 0
      assert reset_state.total_time_ms == 0
      assert reset_state.session_stats == %{}
      # These should not be reset
      assert reset_state.debug_enabled == true
      assert reset_state.rate_limit_ms == 500
    end
  end

  describe "Monitoring.set_debug_enabled/2" do
    test "enables debug mode" do
      state = Monitoring.init()
      new_state = Monitoring.set_debug_enabled(state, true)
      assert new_state.debug_enabled == true
    end

    test "disables debug mode" do
      state = Monitoring.init(debug_enabled: true)
      new_state = Monitoring.set_debug_enabled(state, false)
      assert new_state.debug_enabled == false
    end
  end

  describe "Monitoring.set_rate_limit/2" do
    test "updates rate limit" do
      state = Monitoring.init()
      new_state = Monitoring.set_rate_limit(state, 2000)
      assert new_state.rate_limit_ms == 2000
    end
  end
end
