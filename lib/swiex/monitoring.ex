defmodule Swiex.Monitoring do
  @moduledoc """
  Monitoring and debugging capabilities for Swiex using SWI-Prolog's tdebug/1 and statistics/2.

  This module provides functions to monitor Prolog execution, collect statistics,
  and enable/disable debugging with rate limiting to prevent performance impact.
  """

  require Logger

  @default_rate_limit_ms 1000
  @default_debug_enabled false

  defstruct [
    :debug_enabled,
    :rate_limit_ms,
    :last_debug_time,
    :session_stats,
    :query_count,
    :total_inferences,
    :total_time_ms
  ]

  @doc """
  Initialize monitoring state with optional configuration.

  ## Options
  - `:debug_enabled` - Whether debugging is enabled (default: false)
  - `:rate_limit_ms` - Minimum time between debug calls in milliseconds (default: 1000)
  """
  def init(opts \\ []) do
    %__MODULE__{
      debug_enabled: Keyword.get(opts, :debug_enabled, @default_debug_enabled),
      rate_limit_ms: Keyword.get(opts, :rate_limit_ms, @default_rate_limit_ms),
      last_debug_time: 0,
      session_stats: %{},
      query_count: 0,
      total_inferences: 0,
      total_time_ms: 0
    }
  end

  @doc """
  Enable or disable debugging with rate limiting.
  """
  def set_debug_enabled(state, enabled) do
    %{state | debug_enabled: enabled}
  end

  @doc """
  Set the rate limit for debug calls in milliseconds.
  """
  def set_rate_limit(state, rate_limit_ms) do
    %{state | rate_limit_ms: rate_limit_ms}
  end

  @doc """
  Get comprehensive statistics from a Prolog session.
  """
  def get_statistics(session) do
    with {:ok, stats} <- Swiex.MQI.query(session, "statistics") do
      parse_statistics(stats)
    else
      {:error, reason} ->
        Logger.warning("Failed to get Prolog statistics: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Get specific statistics by key from a Prolog session.
  """
  def get_statistic(session, key) do
    query = "statistics(#{key}, Value)"
    case Swiex.MQI.query(session, query) do
      {:ok, [%{"Value" => value}]} ->
        {:ok, value}
      {:ok, []} ->
        {:error, "No value found for key: #{key}"}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Enable debugging for a specific goal with rate limiting.
  """
  def debug_goal(state, session, goal) do
    if should_debug(state) do
      do_debug_goal(session, goal)
      update_debug_time(state)
    else
      state
    end
  end

  @doc """
  Monitor a query execution with statistics collection.
  """
  def monitor_query(state, session, query, fun) do
    start_time = System.monotonic_time(:millisecond)

    # Get initial statistics (handle errors gracefully)
    initial_stats = case get_statistics(session) do
      {:error, _reason} -> %{}
      stats -> stats
    end

    # Execute the query
    result = fun.()

    # Get final statistics (handle errors gracefully)
    end_time = System.monotonic_time(:millisecond)
    final_stats = case get_statistics(session) do
      {:error, _reason} -> %{}
      stats -> stats
    end

    # Calculate differences
    execution_time = end_time - start_time
    inference_diff = calculate_inference_diff(initial_stats, final_stats)

    # Update state
    new_state = %{state |
      query_count: state.query_count + 1,
      total_inferences: state.total_inferences + inference_diff,
      total_time_ms: state.total_time_ms + execution_time
    }

    # Log monitoring info if debugging is enabled
    if state.debug_enabled do
      Logger.info("""
      Query Monitoring:
      - Query: #{query}
      - Execution time: #{execution_time}ms
      - Inferences: #{inference_diff}
      - Total queries: #{new_state.query_count}
      - Total inferences: #{new_state.total_inferences}
      - Total time: #{new_state.total_time_ms}ms
      """)
    end

    {result, new_state}
  end

  @doc """
  Get monitoring summary for the current session.
  """
  def get_summary(state) do
    avg_time = if state.query_count > 0 do
      state.total_time_ms / state.query_count
    else
      0
    end

    avg_inferences = if state.query_count > 0 do
      state.total_inferences / state.query_count
    else
      0
    end

    %{
      debug_enabled: state.debug_enabled,
      rate_limit_ms: state.rate_limit_ms,
      query_count: state.query_count,
      total_inferences: state.total_inferences,
      total_time_ms: state.total_time_ms,
      avg_time_ms: Float.round(avg_time, 2),
      avg_inferences: Float.round(avg_inferences, 2)
    }
  end

  @doc """
  Reset monitoring statistics.
  """
  def reset_stats(state) do
    %{state |
      query_count: 0,
      total_inferences: 0,
      total_time_ms: 0,
      session_stats: %{}
    }
  end

  # Private functions

  defp should_debug(state) do
    if not state.debug_enabled do
      false
    else
      current_time = System.monotonic_time(:millisecond)
      current_time - state.last_debug_time >= state.rate_limit_ms
    end
  end

  defp do_debug_goal(session, goal) do
    # Enable debugging for the goal
    case Swiex.MQI.query(session, "tdebug(#{goal})") do
      {:ok, _} ->
        Logger.debug("Debugging enabled for goal: #{goal}")
      {:error, reason} ->
        Logger.warning("Failed to enable debugging for goal #{goal}: #{inspect(reason)}")
    end
  end

  defp update_debug_time(state) do
    %{state | last_debug_time: System.monotonic_time(:millisecond)}
  end

  defp parse_statistics(stats) when is_list(stats) do
    Enum.reduce(stats, %{}, fn stat, acc ->
      case stat do
        %{"Key" => key, "Value" => value} ->
          Map.put(acc, key, value)
        _ ->
          acc
      end
    end)
  end
  defp parse_statistics(_), do: %{}

  defp calculate_inference_diff(initial_stats, final_stats) do
    initial_inferences = Map.get(initial_stats, "inferences", 0)
    final_inferences = Map.get(final_stats, "inferences", 0)
    max(0, final_inferences - initial_inferences)
  end
end
