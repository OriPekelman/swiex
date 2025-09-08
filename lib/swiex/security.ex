defmodule Swiex.Security do
  @moduledoc """
  Security module for Swiex that handles query sanitization and validation.

  This module prevents injection attacks and ensures queries are safe to execute.
  """

  @max_query_size 10_000
  @dangerous_patterns ["halt", "shell", "system", "exec", "eval", "call"]

  @doc """
  Sanitizes a Prolog query to prevent injection attacks.

  Returns `{:ok, sanitized_query}` on success or `{:error, reason}` on failure.
  """
  @spec sanitize_query(String.t()) :: {:ok, String.t()} | {:error, atom()}
  def sanitize_query(query) when byte_size(query) > @max_query_size do
    {:error, :query_too_large}
  end

  def sanitize_query(query) when is_binary(query) do
    # Check for injection patterns
    if contains_dangerous_patterns?(query) do
      {:error, :potentially_dangerous_query}
    else
      {:ok, escape_query(query)}
    end
  end

  def sanitize_query(_), do: {:error, :invalid_query_type}

  @doc """
  Validates that a query is safe to execute.

  Returns `:ok` if safe, `{:error, reason}` if unsafe.
  """
  @spec validate_query(String.t()) :: :ok | {:error, atom()}
  def validate_query(query) do
    case sanitize_query(query) do
      {:ok, _} -> :ok
      error -> error
    end
  end

  @doc """
  Escapes special characters in a Prolog query.
  """
  @spec escape_query(String.t()) :: String.t()
  def escape_query(query) do
    query
    |> String.replace("\\", "\\\\")
    |> String.replace("'", "\\'")
    |> String.replace("\"", "\\\"")
  end

  @spec contains_dangerous_patterns?(String.t()) :: boolean()
  defp contains_dangerous_patterns?(query) do
    query_lower = String.downcase(query)
    Enum.any?(@dangerous_patterns, &String.contains?(query_lower, &1))
  end
end
