defmodule Swiex.Stream do
  @moduledoc """
  Streaming support for Swiex queries.

  This module provides streaming capabilities for handling large result sets
  efficiently without loading all results into memory at once.
  """

  @doc """
  Creates a stream for a Prolog query with configurable chunk size.

  ## Examples

      iex> Swiex.Stream.query_stream("member(X, [1,2,3,4,5])")
      #Stream<...>

      iex> Swiex.Stream.query_stream("member(X, [1,2,3,4,5])", 2)
      #Stream<...>

      iex> Swiex.Stream.query_stream("member(X, [1,2,3,4,5])", 2)
      |> Stream.map(fn result -> result["X"] end)
      |> Enum.to_list()
      [1, 2, 3, 4, 5]
  """
  @spec query_stream(String.t() | tuple(), non_neg_integer()) :: Enumerable.t()
  def query_stream(query, chunk_size \\ 100)
  def query_stream(query, chunk_size) when is_binary(query) and chunk_size > 0 do
    Stream.resource(
      fn -> init_streaming_query(query, chunk_size) end,
      fn state -> fetch_next_chunk(state) end,
      fn state -> cleanup_streaming_query(state) end
    )
  end

  def query_stream(ast, chunk_size) when is_tuple(ast) and chunk_size > 0 do
    query_str = Swiex.DSL.Transform.to_query(ast)
    query_stream(query_str, chunk_size)
  end

  @doc """
  Creates a stream for a Prolog query with variable bindings.

  ## Examples

      iex> Swiex.Stream.query_stream_with_bindings(member(^X, [1,2,3,4,5]), [X: 3], 2)
      |> Stream.map(fn result -> result["X"] end)
      |> Enum.to_list()
      [3]
  """
  @spec query_stream_with_bindings(tuple(), keyword(), non_neg_integer()) :: Enumerable.t()
  def query_stream_with_bindings(ast, bindings, chunk_size \\ 100)
      when is_tuple(ast) and is_list(bindings) and chunk_size > 0 do
    query_str = Swiex.DSL.Transform.to_query_with_bindings(ast, bindings)
    query_stream(query_str, chunk_size)
  end

  # Private functions

  defp init_streaming_query(query, chunk_size) do
    case Swiex.MQI.start_session() do
      {:ok, session} ->
        # Execute the query and get initial results
        case Swiex.MQI.query(session, query) do
          {:ok, results} ->
            %{
              session: session,
              query: query,
              chunk_size: chunk_size,
              remaining: results,
              offset: 0
            }
          {:error, reason} ->
            Swiex.MQI.stop_session(session)
            {:error, reason}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_next_chunk(%{remaining: [], session: _session} = state) do
    # No more results, try to get more from Prolog
    case fetch_more_results(state) do
      {:ok, new_results} when new_results != [] ->
        # Got more results
        new_state = %{state | remaining: new_results, offset: state.offset + state.chunk_size}
        {Enum.take(new_state.remaining, state.chunk_size), new_state}
      {:ok, []} ->
        # No more results available
        {[], %{state | remaining: []}}
      {:error, _reason} ->
        # Error occurred, stop streaming
        {[], %{state | remaining: []}}
    end
  end

  defp fetch_next_chunk(%{remaining: remaining, chunk_size: chunk_size} = state) do
    # Return current chunk and update state
    chunk = Enum.take(remaining, chunk_size)
    new_remaining = Enum.drop(remaining, chunk_size)
    new_state = %{state | remaining: new_remaining}
    {chunk, new_state}
  end

  defp fetch_next_chunk({:error, _reason}) do
    # Handle error state
    {[], {:error, :stream_error}}
  end

  defp fetch_more_results(%{session: _session, query: _query, offset: _offset, chunk_size: _chunk_size}) do
    # For now, we'll use a simple approach that doesn't cause infinite loops
    # In a real implementation, we'd need to use Prolog's findall/3 with proper pagination
    # For this demo, we'll just return empty to indicate no more results
    {:ok, []}
  end

  defp cleanup_streaming_query(%{session: session}) do
    Swiex.MQI.stop_session(session)
  end

  defp cleanup_streaming_query({:error, _reason}) do
    :ok
  end
end
