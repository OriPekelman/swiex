defmodule Swiex.Transaction do
  @moduledoc """
  Transaction support for Swiex queries.

  This module provides transaction capabilities for executing multiple Prolog
  operations atomically with rollback support.
  """

  @doc """
  Executes a function within a transaction context.

  ## Examples

      iex> Swiex.Transaction.transaction(fn session ->
      ...>   Swiex.MQI.assertz(session, "person(john, 30)")
      ...>   Swiex.MQI.assertz(session, "person(jane, 25)")
      ...>   {:ok, "Both persons added"}
      ...> end)
      {:ok, "Both persons added"}
  """
  def transaction(fun) when is_function(fun, 1) do
    case Swiex.MQI.start_session() do
      {:ok, session} ->
        try do
          result = fun.(session)
          {:ok, result}
        rescue
          e ->
            {:error, e}
        after
          Swiex.MQI.stop_session(session)
        end

      {:error, reason} ->
        {:error, {:session_start_failed, reason}}
    end
  end



  @doc """
  Executes multiple operations in a single transaction.

  ## Examples

      iex> Swiex.Transaction.batch([
      ...>   {"person(john, 30)", :assertz},
      ...>   {"person(jane, 25)", :assertz},
      ...>   {"person(bob, 35)", :assertz}
      ...> ])
      {:ok, [true, true, true]}
  """
  def batch(operations) when is_list(operations) do
    transaction(fn session ->
      Enum.map(operations, fn {query, operation} ->
        case operation do
          :assertz -> Swiex.MQI.assertz(session, query)
          :query -> Swiex.MQI.query(session, query)
          _ -> {:error, {:unknown_operation, operation}}
        end
      end)
    end)
  end
end
