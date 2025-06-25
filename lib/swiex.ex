defmodule Swiex do
  @moduledoc """
  Swiex - Inline Prolog code in Elixir using SWI-Prolog MQI

  This module provides macros and functions to seamlessly integrate Prolog code
  into your Elixir applications with variable sharing and hot-code loading support.

  ## Examples

      defmodule MyLogic do
        use Swiex

        def find_members do
          Swiex.query("member(X, [:first, :second, :third]).")
        end

        def factorial(n) do
          Swiex.query("factorial(" <> Integer.to_string(n) <> ", Result).")
          |> Swiex.get_var(:Result)
        end
      end

      # Usage
      iex> MyLogic.find_members()
      {:ok, [%{"X" => :first}, %{"X" => :second}, %{"X" => :third}]}

  ## Installation

  Make sure you have SWI-Prolog installed and available in your PATH.
  """

  defmacro __using__(_opts) do
    quote do
      import Swiex
      import Swiex.Macros
    end
  end

  @doc """
  Execute a Prolog query and return all solutions.
  """
  @spec query(String.t()) :: {:ok, [map()]} | {:error, term()}
  def query(prolog_query) do
    Swiex.MQI.query(prolog_query)
  end

  @doc """
  Execute a Prolog query asynchronously.
  """
  @spec query_async(String.t()) :: {:ok, non_neg_integer()} | {:error, term()}
  def query_async(prolog_query) do
    Swiex.MQI.query_async(prolog_query)
  end

  @doc """
  Get results from an asynchronous query.
  """
  @spec get_async_result(non_neg_integer(), integer()) :: {:ok, [map()]} | {:error, term()}
  def get_async_result(query_id, timeout \\ -1) do
    Swiex.MQI.get_async_result(query_id, timeout)
  end

  @doc """
  Cancel an asynchronous query.
  """
  @spec cancel_async(non_neg_integer()) :: :ok | {:error, term()}
  def cancel_async(query_id) do
    Swiex.MQI.cancel_async(query_id)
  end

  @doc """
  Extract a specific variable from query results.
  """
  @spec get_var({:ok, [map()]} | {:error, term()}, atom()) :: {:ok, [term()]} | {:error, term()}
  def get_var({:ok, results}, var_name) do
    var_results = Enum.map(results, fn result ->
      case result do
        %{^var_name => value} -> value
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    
    {:ok, var_results}
  end
  def get_var({:error, reason}, _var_name), do: {:error, reason}

  @doc """
  Load Prolog code from a file or string.
  """
  @spec load_code(String.t()) :: :ok | {:error, term()}
  def load_code(code) when is_binary(code) do
    # Wrap the code in a query that loads it
    query = "consult_from_string('#{escape_string(code)}')."
    case query(query) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def load_code(file_path) when is_binary(file_path) do
    case File.read(file_path) do
      {:ok, content} -> load_code(content)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Define Prolog facts and rules that can be used in subsequent queries.
  """
  @spec define(String.t()) :: :ok | {:error, term()}
  def define(prolog_code) do
    load_code(prolog_code)
  end

  # Private functions

  defp escape_string(str) do
    str
    |> String.replace("'", "\\'")
    |> String.replace("\n", "\\n")
    |> String.replace("\r", "\\r")
    |> String.replace("\t", "\\t")
  end
end 