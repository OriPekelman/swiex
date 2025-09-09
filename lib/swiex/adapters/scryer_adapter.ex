defmodule Swiex.Adapters.ScryerAdapter do
  @moduledoc """
  Scryer Prolog adapter for interfacing with the Scryer Prolog system.
  
  This adapter provides access to Scryer Prolog, a modern ISO-compliant Prolog
  implementation written in Rust. It offers excellent performance and supports
  a comprehensive subset of standard Prolog features including constraint logic
  programming, definite clause grammars, and advanced indexing.
  
  Scryer Prolog is accessed via subprocess calls to the `scryer-prolog` executable.
  """
  
  @behaviour Swiex.PrologAdapter
  
  defmodule Session do
    @moduledoc "Holds Scryer Prolog session state"
    
    @type t :: %__MODULE__{
      port: port(),
      facts: [String.t()],
      session_id: String.t(),
      initialized: boolean()
    }
    
    defstruct [:port, :facts, :session_id, :initialized]
    
    def new(port, session_id) do
      %__MODULE__{
        port: port, 
        facts: [], 
        session_id: session_id,
        initialized: false
      }
    end
  end

  @impl true
  def start_session() do
    # Generate a unique session identifier
    session_id = :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
    
    # Start Scryer Prolog in interactive mode
    case start_scryer_process() do
      {:ok, port} ->
        session = Session.new(port, session_id)
        
        # Initialize the session by waiting for the initial prompt
        case initialize_session(session) do
          {:ok, initialized_session} -> {:ok, initialized_session}
          {:error, reason} -> 
            Port.close(port)
            {:error, reason}
        end
      {:error, reason} ->
        {:error, reason}
    end
  rescue
    error ->
      {:error, {:scryer_initialization_failed, error}}
  end

  @impl true
  def stop_session(%Session{port: port}) do
    if Port.info(port) do
      Port.close(port)
    end
    :ok
  end

  @impl true
  def query(%Session{port: port, initialized: initialized}, query_string) when is_binary(query_string) do
    if not initialized do
      {:error, {:session_not_initialized, "Session must be initialized before querying"}}
    else
      try do
        # Send query to Scryer Prolog process
        query_with_halt = "#{String.trim_trailing(query_string, ".")}."
        Port.command(port, "#{query_with_halt}\n")
        
        # Collect response
        case collect_response(port, 5000) do
          {:ok, output} ->
            parse_scryer_output(output)
          {:error, reason} ->
            {:error, {:scryer_query_failed, reason}}
        end
      rescue
        error ->
          {:error, {:scryer_query_failed, error}}
      end
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
  def assertz(%Session{port: port, facts: facts} = session, fact_string) do
    try do
      # Clean and format the fact
      clean_fact = fact_string |> String.trim() |> String.trim_trailing(".")
      assertion = "assertz((#{clean_fact}))."
      
      # Send assertion to Scryer
      Port.command(port, "#{assertion}\n")
      
      case collect_response(port, 5000) do
        {:ok, output} ->
          if String.contains?(output, "true") do
            updated_session = %{session | facts: [fact_string | facts]}
            {:ok, updated_session}
          else
            {:error, :assertion_failed}
          end
        {:error, reason} ->
          {:error, {:scryer_assert_error, reason}}
      end
    rescue
      error ->
        {:error, {:scryer_assert_failed, error}}
    end
  end

  @impl true
  def consult(%Session{port: port} = session, file_path) do
    try do
      # Use Scryer's consult predicate
      consult_query = "consult('#{file_path}')."
      Port.command(port, "#{consult_query}\n")
      
      case collect_response(port, 10000) do
        {:ok, output} ->
          if String.contains?(output, "true") do
            {:ok, session}
          else
            {:error, {:consult_failed, output}}
          end
        {:error, reason} ->
          {:error, {:scryer_consult_error, reason}}
      end
    rescue
      error ->
        {:error, {:scryer_consult_failed, error}}
    end
  end

  @impl true
  def info() do
    %{
      name: "Scryer Prolog",
      version: get_scryer_version(),
      type: :external,
      features: [
        :iso_compliant,
        :constraint_logic_programming,
        :definite_clause_grammars,
        :advanced_indexing,
        :rust_implementation,
        :modern_prolog
      ]
    }
  end

  @impl true
  def health_check() do
    case System.find_executable("scryer-prolog") do
      nil ->
        {:error, {:scryer_not_found, "scryer-prolog executable not found in PATH"}}
      _path ->
        case start_session() do
          {:ok, session} ->
            result = query(session, "true")
            stop_session(session)
            case result do
              {:ok, _} -> {:ok, :ready}
              error -> {:error, {:scryer_health_check_failed, error}}
            end
          error ->
            {:error, {:scryer_not_available, error}}
        end
    end
  end

  # Private helper functions

  defp initialize_session(%Session{port: port} = session) do
    # Scryer Prolog doesn't show a prompt initially - it's ready to receive queries
    # Send a simple test query to verify it's working
    try do
      Port.command(port, "true.\n")
      
      case collect_response(port, 5000) do
        {:ok, output} ->
          if String.contains?(output, "true") do
            {:ok, %{session | initialized: true}}
          else
            {:error, {:initialization_failed, "Expected 'true' response, got: #{inspect(output)}"}}
          end
        {:error, reason} ->
          {:error, {:initialization_timeout, reason}}
      end
    rescue
      error ->
        {:error, {:initialization_failed, error}}
    end
  end

  defp start_scryer_process() do
    case System.find_executable("scryer-prolog") do
      nil ->
        {:error, :scryer_not_found}
      scryer_path ->
        try do
          # Start Scryer in interactive mode
          port = Port.open({:spawn, "#{scryer_path}"}, [
            :binary,
            :exit_status,
            {:line, 1024}
          ])
          {:ok, port}
        rescue
          error ->
            {:error, {:port_start_failed, error}}
        end
    end
  end

  defp collect_response(port, timeout) do
    collect_response(port, "", timeout, :os.system_time(:millisecond))
  end

  defp collect_response(port, acc, timeout, start_time) do
    current_time = :os.system_time(:millisecond)
    if current_time - start_time > timeout do
      {:error, :timeout}
    else
      receive do
        {^port, {:data, {_flag, data}}} ->
          new_acc = acc <> data
          # Scryer outputs results followed by newlines - look for complete responses
          if String.contains?(new_acc, "true") or 
             String.contains?(new_acc, "false") or 
             String.contains?(new_acc, "error") or
             String.ends_with?(String.trim(new_acc), ".") do
            {:ok, new_acc}
          else
            collect_response(port, new_acc, timeout, start_time)
          end
        {^port, {:exit_status, _status}} ->
          {:error, :process_exited}
      after
        500 ->  # Shorter timeout for Scryer which should respond quickly
          if acc != "" do
            {:ok, acc}
          else
            collect_response(port, acc, timeout, start_time)
          end
      end
    end
  end

  defp parse_scryer_output(output) do
    cond do
      String.contains?(output, "true") ->
        {:ok, [%{}]} # Query succeeded
      String.contains?(output, "false") ->
        {:ok, []} # Query failed/no solutions
      String.contains?(output, "error") ->
        {:error, {:scryer_error, output}}
      true ->
        # Try to extract variable bindings if present
        extract_bindings_from_output(output)
    end
  end

  defp extract_bindings_from_output(output) do
    # Simple binding extraction for demonstration
    # In a full implementation, this would parse Scryer's output format
    lines = String.split(output, "\n")
    
    # Look for variable bindings in the format "X = value"
    bindings = 
      lines
      |> Enum.flat_map(&extract_binding_from_line/1)
      |> Enum.into(%{})
    
    if map_size(bindings) > 0 do
      {:ok, [bindings]}
    else
      {:ok, [%{}]}
    end
  end

  defp extract_binding_from_line(line) do
    # Simple regex to match "Variable = Value" patterns
    case Regex.run(~r/([A-Z][a-zA-Z0-9_]*)\s*=\s*(.+)/, String.trim(line)) do
      [_, var, value] ->
        [{var, String.trim(value)}]
      _ ->
        []
    end
  end

  defp get_scryer_version() do
    case System.cmd("scryer-prolog", ["--version"], stderr_to_stdout: true) do
      {output, 0} -> 
        # Extract version from output
        case Regex.run(~r/scryer-prolog\s+(.+)/, output) do
          [_, version] -> String.trim(version)
          _ -> "unknown"
        end
      _ -> 
        "unknown"
    end
  rescue
    _ -> "unknown"
  end
end