defmodule Swiex.Adapters.SwiAdapter do
  @moduledoc """
  SWI-Prolog adapter using the MQI (Machine Query Interface).
  
  This adapter provides access to SWI-Prolog through its built-in MQI protocol,
  supporting the full range of SWI-Prolog features including constraint logic
  programming (CLP) and modules.
  """
  
  @behaviour Swiex.PrologAdapter
  
  alias Swiex.MQI

  @impl true
  def start_session() do
    MQI.start_session()
  end

  @impl true
  def stop_session(session) do
    MQI.stop_session(session)
  end

  @impl true
  def query(session, query_string) when is_binary(query_string) do
    MQI.query(session, query_string)
  end

  @impl true
  def query(query_string) when is_binary(query_string) do
    MQI.query(query_string)
  end

  @impl true
  def assertz(session, fact_or_rule) do
    MQI.assertz(session, fact_or_rule)
  end

  @impl true
  def consult(session, file_path) do
    # Use SWI-Prolog's consult/1 predicate to load the file
    case MQI.query(session, "consult('#{file_path}')") do
      {:ok, _result} -> {:ok, session}
      error -> error
    end
  end

  @impl true
  def info() do
    %{
      name: "SWI-Prolog",
      version: "9.x",
      type: :external,
      features: [
        :constraint_logic_programming,
        :modules,
        :definite_clause_grammars,
        :tabling,
        :threads,
        :foreign_function_interface,
        :web_support
      ]
    }
  end

  @impl true
  def health_check() do
    case MQI.query("true") do
      {:ok, _} -> {:ok, :ready}
      {:error, reason} -> {:error, {:swi_prolog_not_available, reason}}
    end
  end
end