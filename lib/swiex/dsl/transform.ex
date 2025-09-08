defmodule Swiex.DSL.Transform do
  @moduledoc """
  Transforms Elixir expressions to Prolog queries.

  This module handles the conversion from Elixir AST to Prolog syntax.
  """

  @doc """
  Transforms an Elixir function call to a Prolog query string.

  ## Examples

      iex> Swiex.DSL.Transform.to_query({:factorial, [], [5, {:Result, [], nil}]})
      "factorial(5, Result)"

      iex> Swiex.DSL.Transform.to_query({:member, [], [{:^, [], [{:X, [], nil}]}, [1, 2, 3]]})
      "member(X, [1, 2, 3])"
  """
  @spec to_query(tuple()) :: String.t()
  def to_query({functor, _meta, args}) when is_atom(functor) do
    args_str = args
    |> Enum.map(&format_arg/1)
    |> Enum.join(", ")

    "#{functor}(#{args_str})"
  end

  def to_query(other) do
    raise ArgumentError, "Expected function call tuple, got: #{inspect(other)}"
  end

  @doc """
  Transforms an Elixir function call to a Prolog query string with variable bindings.

  ## Examples

      iex> Swiex.DSL.Transform.to_query_with_bindings({:member, [], [{:^, [], [{:X, [], nil}]}, [1, 2, 3]]}, [X: 2])
      "member(2, [1, 2, 3])"

      iex> Swiex.DSL.Transform.to_query_with_bindings({:factorial, [], [{:^, [], [{:N, [], nil}]}, {:Result, [], nil}]}, [N: 5])
      "factorial(5, Result)"
  """
  @spec to_query_with_bindings(tuple(), keyword()) :: String.t()
  def to_query_with_bindings({functor, _meta, args}, bindings) when is_atom(functor) do
    args_str = args
    |> Enum.map(&format_arg_with_bindings(&1, bindings))
    |> Enum.join(", ")

    "#{functor}(#{args_str})"
  end

  def to_query_with_bindings(other, _bindings) do
    raise ArgumentError, "Expected function call tuple, got: #{inspect(other)}"
  end

  @doc """
  Transforms a block of Elixir code to Prolog syntax.

  ## Examples

      iex> Swiex.DSL.Transform.to_prolog(quote do
      ...>   factorial(0, 1)
      ...>   factorial(N, Result) when N > 0 do
      ...>     N1 = N - 1
      ...>     factorial(N1, F1)
      ...>     Result = N * F1
      ...>   end
      ...> end)
      "factorial(0, 1).\\nfactorial(N, Result) :- N > 0, N1 is N - 1, factorial(N1, F1), Result is N * F1."
  """
  @spec to_prolog(Macro.t()) :: String.t()
  def to_prolog(ast) do
    clauses = ast
    |> extract_clauses()
    |> Enum.map(&clause_to_prolog/1)

    Enum.join(clauses, ".\n") <> "."
  end

  # Private functions

  defp format_arg({:^, _meta1, [{var, _meta2, nil}]}) when is_atom(var) do
    to_string(var)
  end

  defp format_arg({var, _meta, nil}) when is_atom(var) do
    to_string(var)
  end

  defp format_arg(literal) when is_number(literal) do
    to_string(literal)
  end

  defp format_arg(literal) when is_binary(literal) do
    "'#{escape_string(literal)}'"
  end

  defp format_arg(literal) when is_list(literal) do
    "[" <> Enum.map_join(literal, ",", &format_arg/1) <> "]"
  end

  defp format_arg({:__aliases__, _meta, [var]}) when is_atom(var) do
    to_string(var)
  end

  defp format_arg(other) do
    inspect(other)
  end

  defp format_arg_with_bindings({:^, _meta1, [{var, _meta2, nil}]}, bindings) when is_atom(var) do
    case Keyword.fetch(bindings, var) do
      {:ok, value} -> to_string(value)
      :error -> to_string(var) # Fallback to variable name if not found
    end
  end

  defp format_arg_with_bindings({var, _meta, nil}, bindings) when is_atom(var) do
    case Keyword.fetch(bindings, var) do
      {:ok, value} -> to_string(value)
      :error -> to_string(var) # Fallback to variable name if not found
    end
  end

  defp format_arg_with_bindings(literal, _bindings) when is_number(literal) do
    to_string(literal)
  end

  defp format_arg_with_bindings(literal, _bindings) when is_binary(literal) do
    "'#{escape_string(literal)}'"
  end

  defp format_arg_with_bindings(literal, bindings) when is_list(literal) do
    "[" <> Enum.map_join(literal, ",", &format_arg_with_bindings(&1, bindings)) <> "]"
  end

  defp format_arg_with_bindings({:__aliases__, _meta, [var]}, _bindings) when is_atom(var) do
    to_string(var)
  end

  defp format_arg_with_bindings(other, _bindings) do
    inspect(other)
  end

  defp escape_string(str) do
    str
    |> String.replace("'", "\\'")
    |> String.replace("\\", "\\\\")
  end

  defp extract_clauses({:__block__, _meta, contents}) do
    contents
  end

  defp extract_clauses(other) do
    [other]
  end

  defp clause_to_prolog({:when, _meta, [clause, guard]}) do
    head = clause_to_prolog(clause)
    guard_str = guard_to_prolog(guard)
    "#{head} :- #{guard_str}"
  end

  defp clause_to_prolog({functor, _meta, args}) when is_atom(functor) do
    args_str = args
    |> Enum.map(&format_arg/1)
    |> Enum.join(", ")

    "#{functor}(#{args_str})"
  end

  defp clause_to_prolog(other) do
    clause_to_prolog(other)
  end

  defp guard_to_prolog({:>, _meta, [left, right]}) do
    "#{format_arg(left)} > #{format_arg(right)}"
  end

  defp guard_to_prolog({:<, _meta, [left, right]}) do
    "#{format_arg(left)} < #{format_arg(right)}"
  end

  defp guard_to_prolog({:>=, _meta, [left, right]}) do
    "#{format_arg(left)} >= #{format_arg(right)}"
  end

  defp guard_to_prolog({:<=, _meta, [left, right]}) do
    "#{format_arg(left)} <= #{format_arg(right)}"
  end

  defp guard_to_prolog({:==, _meta, [left, right]}) do
    "#{format_arg(left)} = #{format_arg(right)}"
  end

  defp guard_to_prolog({:!=, _meta, [left, right]}) do
    "#{format_arg(left)} \\= #{format_arg(right)}"
  end

  defp guard_to_prolog(other) do
    format_arg(other)
  end
end
