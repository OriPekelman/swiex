defmodule Swiex.DSL do
  @moduledoc """
  Domain Specific Language for Swiex that provides elegant query construction.
  
  This module provides two approaches:
  1. **Elixir DSL**: Natural Elixir syntax for queries
  2. **Inline Prolog**: Direct Prolog code embedded in Elixir
  
  See examples/hybrid_dsl_usage.exs for comprehensive examples.
  """

  @doc """
  Executes a Prolog query and returns all solutions.
  
  ## Examples
  
      iex> all("member(X, [1,2,3])")
      {:ok, [%{"X" => 1}, %{"X" => 2}, %{"X" => 3}]}
      
      iex> all(member(X, [1,2,3]))
      {:ok, [%{"X" => 1}, %{"X" => 2}, %{"X" => 3}]}
  """
  @spec all(String.t() | tuple()) :: {:ok, list()} | {:error, term()}
  def all(query) when is_binary(query) do
    Swiex.MQI.query(query)
  end

  def all(ast) when is_tuple(ast) do
    query_str = Swiex.DSL.Transform.to_query(ast)
    Swiex.MQI.query(query_str)
  end

  @doc """
  Executes a Prolog query and returns the first solution.
  
  ## Examples
  
      iex> one("member(X, [1,2,3])")
      {:ok, %{"X" => 1}}
      
      iex> one(member(X, [1,2,3]))
      {:ok, %{"X" => 1}}
  """
  @spec one(String.t() | tuple()) :: {:ok, map()} | {:error, term()}
  def one(query) when is_binary(query) do
    case Swiex.MQI.query(query) do
      {:ok, [first | _]} -> {:ok, first}
      {:ok, []} -> {:error, :no_solutions}
      error -> error
    end
  end

  def one(ast) when is_tuple(ast) do
    query_str = Swiex.DSL.Transform.to_query(ast)
    one(query_str)
  end

  @doc """
  Executes a Prolog query and returns solutions with an optional limit.
  
  ## Examples
  
      iex> solutions("member(X, [1,2,3])")
      {:ok, [%{"X" => 1}, %{"X" => 2}, %{"X" => 3}]}
      
      iex> solutions("member(X, [1,2,3])", 2)
      {:ok, [%{"X" => 1}, %{"X" => 2}]}
      
      iex> solutions(member(X, [1,2,3]), 2)
      {:ok, [%{"X" => 1}, %{"X" => 2}]}
  """
  @spec solutions(String.t() | tuple(), non_neg_integer() | :all) :: {:ok, list()} | {:error, term()}
  def solutions(query, limit \\ :all)
  def solutions(query, limit) when is_binary(query) do
    case Swiex.MQI.query(query) do
      {:ok, results} when limit == :all ->
        {:ok, results}
      {:ok, results} when is_integer(limit) and limit >= 0 ->
        {:ok, Enum.take(results, limit)}
      error -> error
    end
  end

  def solutions(ast, limit) when is_tuple(ast) do
    query_str = Swiex.DSL.Transform.to_query(ast)
    solutions(query_str, limit)
  end

  @doc """
  Executes a Prolog query using the Elixir DSL syntax.
  
  ## Examples
  
      iex> query(member(X, [1,2,3]))
      {:ok, [%{"X" => 1}, %{"X" => 2}, %{"X" => 3}]}
      
      iex> query(factorial(5, Result))
      {:ok, [%{"Result" => 120}]}
  """
  @spec query(tuple()) :: {:ok, list()} | {:error, term()}
  def query(ast) when is_tuple(ast) do
    all(ast)
  end

  @doc """
  Defines Prolog predicates inline using raw Prolog syntax.
  
  This allows you to write actual Prolog code directly in your Elixir files.
  
  See examples/hybrid_dsl_usage.exs for comprehensive examples.
  """
  defmacro prolog(do: block) do
    quote do
      def __prolog__ do
        prolog_code = unquote(block)
        Swiex.MQI.consult_string(prolog_code)
      end
    end
  end

  @doc """
  Executes a raw Prolog query string.
  
  This is useful when you want to write complex Prolog queries
  that would be difficult to express in the Elixir DSL.
  
  ## Examples
  
      iex> query_prolog("member(X, [1,2,3]), X > 2")
      {:ok, [%{"X" => 3}]}
      
      iex> query_prolog("""
      ...>   factorial(5, Result),
      ...>   Result > 100
      ...> """)
      {:ok, [%{"Result" => 120}]}
  """
  @spec query_prolog(String.t()) :: {:ok, list()} | {:error, term()}
  def query_prolog(prolog_query) when is_binary(prolog_query) do
    Swiex.MQI.query(prolog_query)
  end

  @doc """
  Executes a raw Prolog query string and returns the first solution.
  
  ## Examples
  
      iex> query_prolog_one("member(X, [1,2,3]), X > 2")
      {:ok, %{"X" => 3}}
  """
  @spec query_prolog_one(String.t()) :: {:ok, map()} | {:error, term()}
  def query_prolog_one(prolog_query) when is_binary(prolog_query) do
    one(prolog_query)
  end

  @doc """
  Executes a raw Prolog query string with a solution limit.
  
  ## Examples
  
      iex> query_prolog_solutions("member(X, [1,2,3,4,5]), X > 2", 2)
      {:ok, [%{"X" => 3}, %{"X" => 4}]}
  """
  @spec query_prolog_solutions(String.t(), non_neg_integer()) :: {:ok, list()} | {:error, term()}
  def query_prolog_solutions(prolog_query, limit) when is_binary(prolog_query) and is_integer(limit) do
    solutions(prolog_query, limit)
  end
end
