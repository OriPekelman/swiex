defmodule Swiex.MQI do
  @moduledoc """
  SWI-Prolog MQI (Machine Query Interface) client for Elixir.

  This module implements the official SWI-Prolog MQI protocol as described in
  https://www.swi-prolog.org/pldoc/man?section=mqi-embedded-mode
  """

  @default_host {127, 0, 0, 1}
  @default_timeout 30000  # Increased to 30 seconds for complex queries

  defstruct [
    :socket,
    :host,
    :port,
    :password,
    :timeout,
    :connected
  ]

  defmodule Session do
    @moduledoc """
    Holds the state for a persistent MQI session.
    """
    defstruct [:socket, :host, :port, :password, :timeout, :port_ref, :async_queries]

    def new(attrs) do
      struct(__MODULE__, Keyword.put(attrs, :async_queries, %{}))
    end
  end

  @doc """
  Executes a Prolog query against the MQI server.

  ## Options

  * `:host` - Server host (default: "127.0.0.1")
  * `:timeout` - Connection timeout in milliseconds (default: 5000)

  ## Examples

      iex> Swiex.MQI.query("member(X, [1,2,3])")
      {:ok, [%{"X" => 1}, %{"X" => 2}, %{"X" => 3}]}
  """
  def query(prolog_query, opts \\ [])
  def query(%Session{} = session, prolog_query) do
    do_query(session.socket, prolog_query)
  end
  def query(prolog_query, opts) do
    # Validate and sanitize the query first
    case Swiex.Security.validate_query(prolog_query) do
      :ok ->
        do_query_with_validation(prolog_query, opts)
      {:error, reason} ->
        {:error, {:security_error, reason}}
    end
  end

  defp do_query_with_validation(prolog_query, opts) do
    # Check if we have a stored session from consult_string
    case Process.get(:swiex_session) do
      %Session{} = session ->
        # Use the stored session
        do_query(session.socket, prolog_query)
      nil ->
        # No stored session, use behavior with proper cleanup
        host = Keyword.get(opts, :host, @default_host)
        timeout = Keyword.get(opts, :timeout, @default_timeout)

        case start_mqi_server_with_ref() do
          {:ok, port, password, port_ref} ->
            case :gen_tcp.connect(host, port, [:binary, {:packet, 0}, {:active, false}], timeout) do
              {:ok, socket} ->
                try do
                  with :ok <- send_password(socket, password),
                       {:ok, _auth_response} <- recv_response(socket),
                       :ok <- send_query(socket, prolog_query),
                       {:ok, response} <- recv_response(socket) do
                    parse_response(response)
                  else
                    error -> {:error, error}
                  end
                after
                  # Always clean up resources
                  :gen_tcp.close(socket)
                  Port.close(port_ref)
                end
              {:error, reason} ->
                Port.close(port_ref)  # ✅ Clean up on connection failure
                {:error, reason}
            end
          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @doc """
  Executes a Prolog query asynchronously.
  Returns a query ID that can be used to retrieve results or cancel the query.
  """
  @spec query_async(Session.t(), String.t(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def query_async(%Session{} = session, prolog_query, opts \\ []) do
    # Generate a unique query ID
    query_id = generate_query_id()
    timeout = Keyword.get(opts, :timeout, -1)

    # Use a longer timeout for the initial async request
    socket_timeout = if timeout > 0, do: timeout + 5000, else: @default_timeout

    # Send async query using run_async instead of run
    with :ok <- send_async_query(session.socket, query_id, prolog_query, timeout),
         {:ok, response} <- recv_response(session.socket, socket_timeout) do
      case parse_response(response) do
        {:ok, _} ->
          {:ok, query_id}
        error ->
          error
      end
    else
      {:error, :query_timeout} ->
        # If initial timeout, try to cancel the query
        _ = cancel_async(session, query_id)
        {:error, :async_init_timeout}
      error ->
        {:error, error}
    end
  end

  @doc """
  Get results from an asynchronous query.
  The timeout specifies how long to wait for results (in ms).
  Use -1 for blocking until complete, 0 for non-blocking check.
  """
  @spec get_async_result(Session.t(), String.t(), integer()) :: {:ok, [map()]} | {:pending, nil} | {:error, term()}
  def get_async_result(%Session{} = session, query_id, timeout \\ -1) do
    # Send async_result request
    with :ok <- send_async_result_request(session.socket, query_id, timeout),
         {:ok, response} <- recv_response(session.socket, max(timeout, 5000)) do
      case parse_response(response) do
        {:ok, [%{"functor" => "no_more_results"}]} ->
          {:ok, nil}
        {:ok, [%{"functor" => "result_not_available"}]} ->
          {:pending, nil}
        {:ok, results} ->
          {:ok, results}
        {:error, reason} ->
          {:error, reason}
      end
    else
      {:error, :timeout} -> {:pending, nil}
      error -> {:error, error}
    end
  end

  @doc """
  Cancel an asynchronous query.
  """
  @spec cancel_async(Session.t(), String.t()) :: :ok | {:error, term()}
  def cancel_async(%Session{} = session, query_id) do
    # Send cancel_async request
    with :ok <- send_cancel_async_request(session.socket, query_id),
         {:ok, response} <- recv_response(session.socket) do
      case parse_response(response) do
        {:ok, _} -> :ok
        error -> error
      end
    else
      error -> {:error, error}
    end
  end

  @doc """
  Check if an async query is still running.
  """
  @spec async_query_status(Session.t(), String.t()) :: :running | :completed | :failed | :not_found
  def async_query_status(%Session{} = session, query_id) do
    # Use get_async_result with timeout 0 to check status
    case get_async_result(session, query_id, 0) do
      {:pending, _} -> :running
      {:ok, nil} -> :completed
      {:ok, _} -> :running  # Still has results
      {:error, _} -> :failed
    end
  end

  @doc """
  Checks if the MQI server is available and responding.
  """
  def ping(opts \\ []) do
    query("true", opts)
  end

  @doc """
  Asserts a Prolog clause using assertz/1.

  ## Examples

      iex> Swiex.MQI.assertz("factorial(0, 1).")
      {:ok, []}

      iex> Swiex.MQI.assertz("factorial(N, Result) :- N > 0, N1 is N - 1, factorial(N1, F1), Result is N * F1.")
      {:ok, []}
  """
  def assertz(clause, opts \\ [])
  def assertz(%Session{} = session, clause) do
    clean_clause = clause |> String.trim() |> String.trim_trailing(".")
    do_query(session.socket, "assertz((#{clean_clause}))")
  end
  def assertz(clause, opts) do
    # Validate the clause before asserting
    case Swiex.Security.validate_query(clause) do
      :ok ->
        clean_clause = clause |> String.trim() |> String.trim_trailing(".")
        query("assertz((#{clean_clause}))", opts)
      {:error, reason} ->
        {:error, {:security_error, reason}}
    end
  end

  @doc """
  Consults Prolog code from a string by asserting each clause.

  ## Examples

      iex> Swiex.MQI.consult_string("""
      ...> factorial(0, 1).
      ...> factorial(N, Result) :-
      ...>   N > 0,
      ...>   N1 is N - 1,
      ...>   factorial(N1, F1),
      ...>   Result is N * F1.
      ...> """)
      {:ok, []}
  """
  def consult_string(code, opts \\ [])
  def consult_string(code, opts) when is_binary(code) do
    # For stateless usage, we need to load the code into a session
    # and then execute it in the same session
    with {:ok, session} <- start_session(opts) do
      result = consult_string(session, code)
      if result == {:ok, []} do
        # Store the session in process dictionary for subsequent queries
        Process.put(:swiex_session, session)
        {:ok, []}
      else
        stop_session(session)
        result
      end
    end
  end
  def consult_string(%Session{} = session, code) do
    # Remove all comment blocks first
    code_without_comments = remove_comments(code)
    # Split into lines and filter empty lines
    lines = code_without_comments
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(fn line -> line != "" end)
    # Group lines into clauses (each clause ends with a period)
    clauses = group_lines_into_clauses(lines, [], [])
    # Assert each clause individually
    Enum.reduce_while(clauses, {:ok, []}, fn clause, {:ok, _} ->
      case assertz(session, clause) do
        {:ok, _} -> {:cont, {:ok, []}}
        {:error, reason} -> {:halt, {:error, "Failed to assert clause '#{clause}': #{reason}"}}
      end
    end)
  end

  # Remove /* ... */ comment blocks
  defp remove_comments(code) do
    code
    |> String.replace(~r/\/\*.*?\*\//s, "")  # Remove /* ... */ comments
    |> String.replace(~r/%.*$/, "", global: true)  # Remove % comments
    |> String.replace(~r/\n\s*\n/, "\n")  # Remove empty lines
  end

  # Helper function to group lines into complete clauses
  defp group_lines_into_clauses([], current_clause, all_clauses) do
    if current_clause != [] do
      [Enum.join(Enum.reverse(current_clause), "\n") | all_clauses]
    else
      all_clauses
    end |> Enum.reverse()
  end

  defp group_lines_into_clauses([line | rest], current_clause, all_clauses) do
    if String.ends_with?(line, ".") do
      # This line completes a clause
      complete_clause = Enum.join(Enum.reverse([line | current_clause]), "\n")
      group_lines_into_clauses(rest, [], [complete_clause | all_clauses])
    else
      # This line is part of a multi-line clause
      group_lines_into_clauses(rest, [line | current_clause], all_clauses)
    end
  end

  @doc """
  Starts a persistent MQI session. Returns {:ok, session}.
  """
  def start_session(opts \\ []) do
    host = Keyword.get(opts, :host, @default_host)
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    case start_mqi_server(:session) do
      {:ok, port, password, port_ref} ->
        case :gen_tcp.connect(host, port, [:binary, {:packet, 0}, {:active, false}], timeout) do
          {:ok, socket} ->
            case send_password(socket, password) do
              :ok ->
                case recv_response(socket) do
                  {:ok, _auth_response} ->
                    {:ok, Session.new(socket: socket, host: host, port: port, password: password, timeout: timeout, port_ref: port_ref)}
                  {:error, reason} ->
                    :gen_tcp.close(socket)
                    Port.close(port_ref)  # ✅ Clean up on auth failure
                    {:error, reason}
                end
              {:error, reason} ->
                :gen_tcp.close(socket)
                Port.close(port_ref)  # ✅ Clean up on password send failure
                {:error, reason}
            end
          {:error, reason} ->
            Port.close(port_ref)  # ✅ Clean up on connection failure
            {:error, reason}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Stops a persistent MQI session.
  """
  def stop_session(%Session{socket: socket, port_ref: port_ref}) do
    :gen_tcp.close(socket)
    if port_ref, do: Port.close(port_ref)
    :ok
  end

  # Internal: for persistent session queries
  defp do_query(socket, prolog_query) do
    with :ok <- send_query(socket, prolog_query),
         {:ok, response} <- recv_response(socket) do
      parse_response(response)
    else
      error -> {:error, error}
    end
  end

  # Overload start_mqi_server for session to return port_ref
  defp start_mqi_server(:session) do
    case Port.open({:spawn, "swipl mqi --write_connection_values=true"},
         [:binary, :exit_status, {:line, 1024}]) do
      port when is_port(port) ->
        case read_connection_values(port) do
          {:ok, port_num, password} ->
            {:ok, port_num, password, port}
          {:error, reason} ->
            Port.close(port)  # ✅ Clean up the port on failure
            {:error, reason}
        end
      _ ->
        {:error, "Failed to start MQI server"}
    end
  end

  # Private functions

  # New function that returns port reference for cleanup
  defp start_mqi_server_with_ref do
    case Port.open({:spawn, "swipl mqi --write_connection_values=true"},
         [:binary, :exit_status, {:line, 1024}]) do
      port when is_port(port) ->
        case read_connection_values(port) do
          {:ok, port_num, password} ->
            {:ok, port_num, password, port}
          {:error, reason} ->
            Port.close(port)
            {:error, reason}
        end
      _ ->
        {:error, "Failed to start MQI server"}
    end
  end

  defp start_mqi_server do
    case Port.open({:spawn, "swipl mqi --write_connection_values=true"},
         [:binary, :exit_status, {:line, 1024}]) do
      port when is_port(port) ->
        case read_connection_values(port) do
          {:ok, port_num, password} ->
            {:ok, port_num, password}
          {:error, reason} ->
            {:error, reason}
        end
      _ ->
        {:error, "Failed to start MQI server"}
    end
  end

  defp read_connection_values(port) do
    IO.puts("[MQI] Reading connection values from Prolog...")
    case receive_port_data(port, [], 2) do
      [port_str, password] ->
        IO.puts("[MQI] Got port: #{port_str}, password: #{password}")
        case Integer.parse(port_str) do
          {port_num, _} ->
            # Give SWI-Prolog a moment to fully start its MQI TCP server
            Process.sleep(100)
            {:ok, port_num, password}
          :error -> {:error, "Invalid port number: #{port_str}"}
        end
      data ->
        IO.puts("[MQI] Unexpected data from port: #{inspect(data)}")
        {:error, "Failed to read connection values"}
    end
  end

  defp receive_port_data(_port, acc, 0), do: Enum.reverse(acc)
  defp receive_port_data(port, acc, count) do
    IO.puts("[MQI] Waiting for line #{3 - count}...")
    receive do
      {^port, {:data, {:eol, line}}} ->
        IO.puts("[MQI] Received line: #{line}")
        receive_port_data(port, [line | acc], count - 1)
      {^port, {:data, data}} ->
        IO.puts("[MQI] Received data: #{inspect(data)}")
        receive_port_data(port, acc, count)
      {^port, {:exit_status, status}} when status != 0 ->
        {:error, "MQI server exited with status #{status}"}
      other ->
        IO.puts("[MQI] Received other: #{inspect(other)}")
        receive_port_data(port, acc, count)
    after
      5000 ->
        IO.puts("[MQI] Timeout waiting for MQI server output")
        {:error, "Timeout waiting for MQI server output"}
    end
  end

  defp send_password(socket, password) do
    message = password <> ".\n"
    length_str = "#{byte_size(message)}.\n"
    packet = length_str <> message
    :gen_tcp.send(socket, packet)
  end

  defp send_query(socket, query) do
    # Format: run(Goal, Timeout) - ensure query does NOT end with a period
    clean_query = String.trim_trailing(String.trim(query), ".")

    # If the query contains commas (compound query), wrap it in parentheses
    formatted_query = if String.contains?(clean_query, ",") do
      "(#{clean_query})"
    else
      clean_query
    end

    message = "run(#{formatted_query}, -1).\n"
    length_str = "#{byte_size(message)}.\n"
    packet = length_str <> message
    IO.puts("[MQI] Sending query: #{inspect(packet)}")
    :gen_tcp.send(socket, packet)
  end

  defp send_async_query(socket, query_id, query, timeout) do
    # Format: run_async(Goal, Timeout, QueryID)
    clean_query = String.trim_trailing(String.trim(query), ".")

    formatted_query = if String.contains?(clean_query, ",") do
      "(#{clean_query})"
    else
      clean_query
    end

    message = "run_async(#{formatted_query}, #{timeout}, '#{query_id}').\n"
    length_str = "#{byte_size(message)}.\n"
    packet = length_str <> message
    IO.puts("[MQI] Sending async query: #{inspect(packet)}")
    :gen_tcp.send(socket, packet)
  end

  defp send_async_result_request(socket, query_id, timeout) do
    message = "async_result('#{query_id}', #{timeout}).\n"
    length_str = "#{byte_size(message)}.\n"
    packet = length_str <> message
    IO.puts("[MQI] Requesting async result: #{inspect(packet)}")
    :gen_tcp.send(socket, packet)
  end

  defp send_cancel_async_request(socket, query_id) do
    message = "cancel_async('#{query_id}').\n"
    length_str = "#{byte_size(message)}.\n"
    packet = length_str <> message
    IO.puts("[MQI] Cancelling async query: #{inspect(packet)}")
    :gen_tcp.send(socket, packet)
  end

  defp generate_query_id do
    "query_#{:erlang.unique_integer([:positive, :monotonic])}_#{System.system_time(:microsecond)}"
  end

  defp recv_response(socket, timeout \\ @default_timeout) do
    case :gen_tcp.recv(socket, 0, timeout) do
      {:ok, response} ->
        IO.puts("[MQI] Raw response: #{inspect(response)}")
        {:ok, response}
      {:error, :timeout} ->
        IO.puts("[MQI] Recv timeout after #{timeout}ms")
        {:error, :query_timeout}
      {:error, reason} ->
        IO.puts("[MQI] Recv error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp parse_response(response) do
    # Parse the <length>.\n<json>.\n format
    case parse_mqi_message(response) do
      {:ok, json_str} when json_str == "false" or json_str == "\"false\"" ->
        # Prolog query failed - no solutions found
        {:ok, []}
      {:ok, json_str} when json_str == "true" or json_str == "\"true\"" ->
        # Prolog query succeeded but no variables to bind
        {:ok, true}
      {:ok, json_str} ->
        IO.puts("[MQI] Parsed JSON: #{json_str}")
        case Jason.decode(json_str) do
          {:ok, %{"functor" => "true", "args" => [data]}} ->
            {:ok, parse_solutions(data)}
          {:ok, %{"functor" => "exception", "args" => [%{"functor" => "syntax_error", "args" => [error_msg]}]}} ->
            {:error, "Syntax error: #{error_msg}"}
          {:ok, %{"functor" => "exception", "args" => [error_data]}} ->
            {:error, "Exception: #{inspect(error_data)}"}
          {:ok, %{"functor" => "false"}} ->
            # Prolog query failed - no solutions found
            {:ok, []}
          {:ok, %{"functor" => "error", "args" => [error_msg]}} ->
            # Prolog query error
            {:error, "Query error: #{error_msg}"}
          {:ok, response_data} ->
            IO.puts("[MQI] Unexpected response format: #{inspect(response_data)}")
            {:error, "Unexpected response format: #{inspect(response_data)}"}
          {:error, reason} ->
            {:error, "JSON decode error: #{inspect(reason)}"}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_mqi_message(data) do
    case String.split(data, ".\n", parts: 2) do
      [length_str, rest] ->
        case Integer.parse(length_str) do
          {length, _} ->
            # The JSON string is the next 'length' bytes
            if byte_size(rest) >= length do
              <<json::binary-size(length), _rest::binary>> = rest
              json = String.trim_trailing(json, ".\n")
              json = String.trim(json)
              {:ok, json}
            else
              {:error, "Incomplete message"}
            end
          :error ->
            {:error, "Invalid message length"}
        end
      _ ->
        {:error, "Invalid message format"}
    end
  end

  # Helper to normalize Prolog JSON terms to Elixir types
  defp normalize_prolog_term(%{"functor" => ",", "args" => args}) do
    # Prolog tuple: convert to Elixir tuple
    args
    |> Enum.map(&normalize_prolog_term/1)
    |> List.to_tuple()
  end
  defp normalize_prolog_term(%{"functor" => "dict", "args" => [entries]}) do
    # Prolog dict: convert to Elixir map
    entries
    |> Enum.map(fn %{"functor" => ",", "args" => [k, v]} ->
      {normalize_prolog_term(k), normalize_prolog_term(v)}
    end)
    |> Enum.into(%{})
  end
  defp normalize_prolog_term(%{"functor" => "=", "args" => [var, value]}) do
    {var, normalize_prolog_term(value)}
  end
  defp normalize_prolog_term(%{"functor" => "true"}), do: true
  defp normalize_prolog_term(%{"functor" => "false"}), do: false
  defp normalize_prolog_term(%{"functor" => "nil"}), do: nil
  defp normalize_prolog_term(%{"functor" => functor, "args" => args}) do
    # Fallback: convert args recursively
    %{functor => Enum.map(args, &normalize_prolog_term/1)}
  end
  defp normalize_prolog_term("true"), do: true
  defp normalize_prolog_term("false"), do: false
  defp normalize_prolog_term("nil"), do: nil
  defp normalize_prolog_term(list) when is_list(list), do: Enum.map(list, &normalize_prolog_term/1)
  defp normalize_prolog_term(other), do: other

  # Patch parse_solutions to use normalization
  defp parse_solutions(data) when is_list(data) do
    Enum.map(data, fn solution ->
      # Each solution is a list of bindings: [%{"functor" => "=", "args" => [Var, Value]}, ...]
      if is_list(solution) do
        Enum.reduce(solution, %{}, fn
          %{"functor" => "=", "args" => [var, value]}, acc when is_binary(var) ->
            Map.put(acc, var, normalize_prolog_term(value))
          _, acc -> acc
        end)
      else
        %{}
      end
    end)
  end
  defp parse_solutions(_), do: []
end
