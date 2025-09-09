defmodule Swiex.PrologAdapter do
  @moduledoc """
  Behaviour for Prolog implementation adapters.
  
  This module defines a common interface for different Prolog implementations,
  allowing the Swiex library to work with SWI-Prolog, Erlog, Scryer-Prolog, or
  other Prolog systems through a unified API.
  """

  @type session :: any()
  @type query :: String.t()
  @type result :: map() | term()
  @type error :: String.t() | atom()

  @doc """
  Start a new Prolog session.
  
  Returns `{:ok, session}` or `{:error, reason}`.
  """
  @callback start_session() :: {:ok, session} | {:error, error}

  @doc """
  Stop an existing Prolog session.
  
  Returns `:ok` or `{:error, reason}`.
  """
  @callback stop_session(session) :: :ok | {:error, error}

  @doc """
  Execute a Prolog query within a session.
  
  Returns `{:ok, results}` where `results` is a list of result maps,
  or `{:error, reason}`.
  """
  @callback query(session, query) :: {:ok, [result]} | {:error, error}

  @doc """
  Execute a Prolog query without maintaining session state.
  
  Returns `{:ok, results}` where `results` is a list of result maps,
  or `{:error, reason}`.
  """
  @callback query(query) :: {:ok, [result]} | {:error, error}

  @doc """
  Assert a new fact or rule into the knowledge base.
  
  Returns `{:ok, result}` or `{:error, reason}`.
  """
  @callback assertz(session, String.t()) :: {:ok, result} | {:error, error}

  @doc """
  Load a Prolog file or module into the session.
  
  Returns `{:ok, session}` or `{:error, reason}`.
  """
  @callback consult(session, String.t()) :: {:ok, session} | {:error, error}

  @doc """
  Get information about the adapter implementation.
  
  Returns a map with metadata about the Prolog implementation.
  """
  @callback info() :: %{
    name: String.t(),
    version: String.t(),
    type: :external | :embedded,
    features: [atom()]
  }

  @doc """
  Check if the Prolog implementation is available and working.
  
  Returns `{:ok, :ready}` if available, `{:error, reason}` otherwise.
  """
  @callback health_check() :: {:ok, :ready} | {:error, error}
end