defmodule Swiex.DSL do
  @moduledoc """
  Domain Specific Language for Swiex that provides elegant query construction.

  This module provides macros and functions that make Prolog queries more readable
  and less error-prone than raw strings.
  """

  @doc """
  Defines a Prolog predicate using a more natural Elixir syntax.

  ## Examples

      defprolog do
        factorial(0, 1)
        factorial(N, Result) when N > 0 do
          N1 = N - 1
          factorial(N1, F1)
          Result = N * F1
        end
      end
  """
  defmacro defprolog(do: block) do
    quote do
      def __prolog__ do
        unquote(block)
        |> Swiex.DSL.Transform.to_prolog()
        |> Swiex.MQI.consult_string()
      end
    end
  end

  @doc """
  Executes a Prolog query with a more natural syntax.

  ## Examples

      query(member(X, [1, 2, 3]))
      query(factorial(5, Result))
  """
  defmacro query(call) do
    quote do
      unquote(Macro.escape(call))
      |> Swiex.DSL.Transform.to_query()
      |> Swiex.MQI.query()
    end
  end

  @doc """
  Executes a Prolog query and returns all solutions.

  ## Examples

      all(member(X, [1, 2, 3]))
      all(factorial(N, Result))
  """
  def all(query_string) when is_binary(query_string) do
    Swiex.MQI.query(query_string)
  end

  def all(query_expr) do
    query_expr
    |> Swiex.DSL.Transform.to_query()
    |> Swiex.MQI.query()
  end

  @doc """
  Executes a Prolog query and returns the first solution.

  ## Examples

      one(member(X, [1, 2, 3]))
      one(factorial(5, Result))
  """
  def one(query_string) when is_binary(query_string) do
    case Swiex.MQI.query(query_string) do
      {:ok, [result | _]} -> {:ok, result}
      {:ok, []} -> {:error, :no_results}
      error -> error
    end
  end

  def one(query_expr) do
    case all(query_expr) do
      {:ok, [result | _]} -> {:ok, result}
      {:ok, []} -> {:error, :no_results}
      error -> error
    end
  end

  @doc """
  Executes a Prolog query and returns a limited number of solutions.

  ## Examples

      solutions(member(X, [1, 2, 3]), 2)
      solutions(factorial(N, Result), 5)
  """
  def solutions(query_string, limit) when is_binary(query_string) and is_integer(limit) do
    case Swiex.MQI.query(query_string) do
      {:ok, results} -> {:ok, Enum.take(results, limit)}
      error -> error
    end
  end

  def solutions(query_expr, limit) when is_integer(limit) do
    case all(query_expr) do
      {:ok, results} -> {:ok, Enum.take(results, limit)}
      error -> error
    end
  end

  @doc """
  Executes a Prolog query and returns all solutions (alias for all/1).
  """
  def solutions(query_string) when is_binary(query_string) do
    all(query_string)
  end

  def solutions(query_expr) do
    all(query_expr)
  end
end
