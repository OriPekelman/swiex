defmodule Swiex.StreamTest do
  use ExUnit.Case, async: true

  setup do
    # Setup some test facts
    Swiex.MQI.consult_string("""
      member(X, [X|_]).
      member(X, [_|T]) :- member(X, T).

      range(Start, End, List) :-
        findall(N, (between(Start, End, N)), List).
    """, [])

    :ok
  end

  test "query_stream with string query" do
    stream = Swiex.Stream.query_stream("member(X, [1,2,3,4,5])")

    assert is_struct(stream, Stream)

    results = stream |> Enum.to_list()
    assert length(results) == 5

    # Check that all results are maps with X key
    Enum.each(results, fn result ->
      assert Map.has_key?(result, "X")
      assert result["X"] in [1, 2, 3, 4, 5]
    end)
  end

  test "query_stream with DSL query" do
    member_ast = {:member, [], [{:X, [], nil}, [1, 2, 3, 4, 5]]}
    stream = Swiex.Stream.query_stream(member_ast)

    assert is_struct(stream, Stream)

    results = stream |> Enum.to_list()
    assert length(results) == 5
  end

  test "query_stream with custom chunk size" do
    stream = Swiex.Stream.query_stream("member(X, [1,2,3,4,5])", 2)

    results = stream |> Enum.to_list()
    assert length(results) == 5  # Should still get all results
  end

  test "query_stream_with_bindings" do
    member_ast = {:member, [], [{:^, [], [{:X, [], nil}]}, [1, 2, 3, 4, 5]]}
    stream = Swiex.Stream.query_stream_with_bindings(member_ast, [X: 3], 2)

    results = stream |> Enum.to_list()
    assert length(results) == 1
    assert results |> List.first() |> Map.get("X") == 3
  end

  test "stream with transformations" do
    stream = Swiex.Stream.query_stream("member(X, [1,2,3,4,5])")

    # Transform the stream
    transformed = stream
      |> Stream.map(fn result -> result["X"] end)
      |> Stream.filter(fn x -> rem(x, 2) == 0 end)  # Only even numbers
      |> Enum.to_list()

    assert transformed == [2, 4]
  end

  test "stream with large result set" do
    # Create a larger dataset
    Swiex.MQI.consult_string("range(1, 100, List).", [])

    stream = Swiex.Stream.query_stream("member(X, List)", 10)

    results = stream |> Enum.to_list()
    assert length(results) == 100

    # Check first and last values
    assert results |> List.first() |> Map.get("X") == 1
    assert results |> List.last() |> Map.get("X") == 100
  end

  test "stream error handling" do
    # Test with invalid query
    stream = Swiex.Stream.query_stream("invalid_predicate(X)")

    results = stream |> Enum.to_list()
    assert results == []  # Should handle errors gracefully
  end
end
