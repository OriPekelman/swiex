defmodule Swiex.Prolog do
  @moduledoc """
  Unified interface for multiple Prolog implementations.
  
  This module provides a consistent API that can work with different Prolog 
  implementations (SWI-Prolog via MQI, Erlog, Scryer-Prolog, etc.) through
  a configurable adapter pattern.
  
  ## Configuration
  
  Configure the default adapter in your application config:
  
      config :swiex, :prolog_adapter, Swiex.Adapters.SwiAdapter  # Default: SWI-Prolog
      # or
      config :swiex, :prolog_adapter, Swiex.Adapters.ErlogAdapter  # Embedded Erlog
      # or  
      config :swiex, :prolog_adapter, Swiex.Adapters.ScryerAdapter  # Modern Scryer Prolog
  
  ## Usage
  
      # Using default adapter
      {:ok, results} = Swiex.Prolog.query("member(X, [1,2,3])")
      
      # Using specific adapter
      {:ok, results} = Swiex.Prolog.query("member(X, [1,2,3])", adapter: Swiex.Adapters.ErlogAdapter)
      
      # With session management  
      {:ok, session} = Swiex.Prolog.start_session()
      {:ok, _} = Swiex.Prolog.assertz(session, "likes(john, pizza)")
      {:ok, results} = Swiex.Prolog.query(session, "likes(john, X)")
      :ok = Swiex.Prolog.stop_session(session)
  """

  alias Swiex.Adapters.{SwiAdapter, ErlogAdapter, ScryerAdapter}

  @default_adapter SwiAdapter

  @type adapter :: module()
  @type session :: any()
  @type query :: String.t()
  @type result :: map() | term()
  @type error :: String.t() | atom() | tuple()

  @doc """
  Get the configured default Prolog adapter.
  """
  def default_adapter do
    Application.get_env(:swiex, :prolog_adapter, @default_adapter)
  end

  @doc """
  Start a new Prolog session using the specified or default adapter.
  """
  @spec start_session(keyword()) :: {:ok, {session, adapter}} | {:error, error}
  def start_session(opts \\ []) do
    adapter = Keyword.get(opts, :adapter, default_adapter())
    
    case adapter.start_session() do
      {:ok, session} -> {:ok, {session, adapter}}
      error -> error
    end
  end

  @doc """
  Stop a Prolog session.
  """
  @spec stop_session({session, adapter}) :: :ok | {:error, error}
  def stop_session({session, adapter}) do
    adapter.stop_session(session)
  end

  @doc """
  Execute a query within a session.
  """
  @spec query({session, adapter}, query) :: {:ok, [result]} | {:error, error}
  def query({session, adapter}, query_string) do
    adapter.query(session, query_string)
  end

  @doc """
  Execute a query without session management.
  """
  @spec query(query, keyword()) :: {:ok, [result]} | {:error, error}
  def query(query_string, opts \\ [])
  def query(query_string, opts) do
    adapter = Keyword.get(opts, :adapter, default_adapter())
    adapter.query(query_string)
  end

  @doc """
  Assert a fact or rule into a session's knowledge base.
  """
  @spec assertz({session, adapter}, String.t()) :: {:ok, {session, adapter}} | {:error, error}
  def assertz({session, adapter}, fact_or_rule) do
    case adapter.assertz(session, fact_or_rule) do
      {:ok, updated_session} -> {:ok, {updated_session, adapter}}
      error -> error
    end
  end

  @doc """
  Load a Prolog file into a session.
  """
  @spec consult({session, adapter}, String.t()) :: {:ok, {session, adapter}} | {:error, error}
  def consult({session, adapter}, file_path) do
    case adapter.consult(session, file_path) do
      {:ok, updated_session} -> {:ok, {updated_session, adapter}}
      error -> error
    end
  end

  @doc """
  Get information about an adapter.
  """
  @spec info(adapter) :: map()
  def info(adapter \\ nil) do
    adapter = adapter || default_adapter()
    adapter.info()
  end

  @doc """
  Check the health of an adapter.
  """
  @spec health_check(adapter) :: {:ok, :ready} | {:error, error}
  def health_check(adapter \\ nil) do
    adapter = adapter || default_adapter()
    adapter.health_check()
  end

  @doc """
  List all available adapters and their status.
  """
  @spec list_adapters() :: [%{adapter: adapter, info: map(), health: :ok | :error}]
  def list_adapters do
    adapters = [SwiAdapter, ErlogAdapter, ScryerAdapter]
    
    Enum.map(adapters, fn adapter ->
      info = adapter.info()
      health = case adapter.health_check() do
        {:ok, :ready} -> :ok
        {:error, _} -> :error
      end
      
      %{adapter: adapter, info: info, health: health}
    end)
  end

  @doc """
  Switch to a different Prolog adapter for the application.
  
  This changes the default adapter for new sessions.
  """
  @spec set_default_adapter(adapter) :: :ok
  def set_default_adapter(adapter) do
    Application.put_env(:swiex, :prolog_adapter, adapter)
  end

  @doc """
  Execute the same query across multiple adapters for comparison.
  """
  @spec query_all(query, [adapter]) :: %{adapter => {:ok, [result]} | {:error, error}}
  def query_all(query_string, adapters \\ [SwiAdapter, ErlogAdapter, ScryerAdapter]) do
    Enum.into(adapters, %{}, fn adapter ->
      result = 
        case adapter.health_check() do
          {:ok, :ready} -> adapter.query(query_string)
          {:error, reason} -> {:error, {:adapter_not_available, reason}}
        end
      {adapter, result}
    end)
  end
end