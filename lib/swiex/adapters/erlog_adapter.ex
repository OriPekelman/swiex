defmodule Swiex.Adapters.ErlogAdapter do
  @moduledoc """
  Erlog adapter for embedded Prolog functionality.
  
  This adapter provides access to Erlog, a Prolog interpreter implemented in Erlang
  that runs embedded within the Erlang/Elixir runtime. It offers good performance
  for basic logic programming tasks without requiring an external Prolog system.
  """
  
  @behaviour Swiex.PrologAdapter
  
  defmodule Session do
    @moduledoc "Holds Erlog session state"
    defstruct [:erlog_state, :facts]
    
    def new(erlog_state) do
      %__MODULE__{erlog_state: erlog_state, facts: []}
    end
  end

  @impl true
  def start_session() do
    case :erlog.new() do
      {:ok, erlog_state} ->
        session = Session.new(erlog_state)
        {:ok, session}
      {:error, reason} ->
        {:error, reason}
    end
  rescue
    error ->
      {:error, {:erlog_initialization_failed, error}}
  end

  @impl true
  def stop_session(%Session{}) do
    # Erlog doesn't require explicit cleanup
    :ok
  end

  @impl true  
  def query(%Session{erlog_state: erlog_state}, query_string) when is_binary(query_string) do
    try do
      # Parse the query string into Erlog terms
      case parse_query(query_string) do
        {:ok, erlog_term} ->
          execute_erlog_query(erlog_state, erlog_term)
        {:error, :unsupported} ->
          {:error, {:unsupported_query, "Erlog does not support this query: #{query_string}"}}
        {:error, reason} ->
          {:error, {:parse_error, reason}}
      end
    rescue
      error ->
        {:error, {:erlog_query_failed, error}}
    end
  end

  @impl true
  def query(query_string) when is_binary(query_string) do
    with {:ok, session} <- start_session(),
         result <- query(session, query_string) do
      stop_session(session)
      result
    end
  end

  @impl true
  def assertz(%Session{erlog_state: erlog_state, facts: facts} = session, fact_string) do
    try do
      case parse_fact(fact_string) do
        {:ok, erlog_fact} ->
          # Add fact to session's fact list for tracking
          updated_session = %{session | facts: [fact_string | facts]}
          
          # Assert the fact into Erlog  
          case :erlog.prove({:assert, erlog_fact}, erlog_state) do
            {{:succeed, _bindings}, _new_state} ->
              {:ok, updated_session}
            {{:fail, _}, _} ->
              {:error, :assertion_failed}
            error ->
              {:error, {:erlog_assert_error, error}}
          end
        {:error, :unsupported} ->
          {:error, {:unsupported_fact, "Erlog does not support this fact: #{fact_string}"}}
        {:error, reason} ->
          {:error, {:parse_error, reason}}
      end
    rescue
      error ->
        {:error, {:erlog_assert_failed, error}}
    end
  end

  @impl true
  def consult(%Session{} = _session, _file_path) do
    # Basic implementation - Erlog file loading is more limited
    {:error, :not_implemented}
  end

  @impl true
  def info() do
    %{
      name: "Erlog",
      version: "1.0",
      type: :embedded,
      features: [
        :basic_logic_programming,
        :embedded_runtime,
        :erlang_integration
      ]
    }
  end

  @impl true
  def health_check() do
    case start_session() do
      {:ok, session} ->
        result = query(session, "true")
        stop_session(session)
        case result do
          {:ok, _} -> {:ok, :ready}
          error -> {:error, {:erlog_health_check_failed, error}}
        end
      error ->
        {:error, {:erlog_not_available, error}}
    end
  end

  # Private helper functions

  defp parse_query(query_string) do
    # Convert simple Prolog queries to proper Erlog terms
    # Only support what the MQI interface supports to maintain consistency
    case String.trim(query_string) do
      "true" -> 
        {:ok, true}
      "fail" -> 
        {:ok, :fail}
        
      # For any other expressions, return unsupported rather than trying to parse
      # This maintains consistency with what MQI supports and follows user guidance
      # to avoid complex regex parsing and just fail for unsupported features
      _query ->
        {:error, :unsupported}
    end
  end

  defp parse_fact(fact_string) do
    # Very basic fact parsing - maintain consistency with MQI capabilities
    # Only support the simplest atom facts to avoid complex parsing
    fact = String.trim(fact_string)
    
    # Only support simple atom facts for now
    if String.match?(fact, ~r/^\w+$/) do
      {:ok, String.to_atom(fact)}
    else
      # For complex facts (with arguments), return unsupported to maintain
      # consistency with MQI interface and avoid regex parsing complexity
      {:error, :unsupported}
    end
  end

  defp execute_erlog_query(erlog_state, erlog_term) do
    case :erlog.prove(erlog_term, erlog_state) do
      {{:succeed, bindings}, _new_state} ->
        # Convert Erlog bindings to our standard format
        results = convert_bindings_to_results(bindings)
        {:ok, results}
      
      {:fail, _new_state} ->
        {:ok, []} # No solutions found
        
      {{:fail, _}, _} ->
        {:ok, []} # No solutions found - alternative format
        
      error ->
        {:error, {:erlog_execution_error, error}}
    end
  end

  defp convert_bindings_to_results(bindings) when is_list(bindings) do
    # Convert Erlog variable bindings to maps
    case bindings do
      [] -> 
        [%{}] # Query succeeded with no variables
      _ ->
        [Enum.into(bindings, %{}, fn {var, value} ->
          {to_string(var), convert_erlog_value(value)}
        end)]
    end
  end

  defp convert_bindings_to_results(_), do: [%{}]

  defp convert_erlog_value(value) do
    case value do
      atom when is_atom(atom) -> to_string(atom)
      num when is_number(num) -> num
      list when is_list(list) -> Enum.map(list, &convert_erlog_value/1)
      tuple when is_tuple(tuple) -> 
        # Convert Erlog compound terms
        case tuple do
          {functor} when is_atom(functor) -> to_string(functor)
          {functor, args} when is_atom(functor) -> 
            %{"functor" => to_string(functor), "args" => convert_erlog_value(args)}
          _ -> inspect(tuple)
        end
      other -> inspect(other)
    end
  end
end