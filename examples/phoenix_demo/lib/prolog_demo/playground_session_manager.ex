defmodule PrologDemo.PlaygroundSessionManager do
  @moduledoc """
  Manages a persistent Prolog session for the playground where users can run custom queries.
  """

  use GenServer
  alias Swiex.MQI
  alias Swiex.Monitoring

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_state) do
    case MQI.start_session() do
      {:ok, session} ->
        # Initialize monitoring state
        monitoring_state = Monitoring.init(debug_enabled: false, rate_limit_ms: 1000)

        # Load basic Prolog libraries and utilities
        load_basic_rules(session)

        {:ok, %{session: session, loaded: true, monitoring_state: monitoring_state}}
      {:error, reason} ->
        {:stop, {:error, "Failed to start MQI session: #{reason}"}}
    end
  end

  def execute_query(query, setup \\ "") do
    GenServer.call(__MODULE__, {:execute_query, query, setup})
  end

  def load_custom_rules(rules) do
    GenServer.call(__MODULE__, {:load_custom_rules, rules})
  end

  def facts_loaded? do
    GenServer.call(__MODULE__, :facts_loaded?)
  end

  def load_facts_with_progress(pid) do
    GenServer.call(__MODULE__, {:load_facts_with_progress, pid})
  end

  def get_statistics do
    GenServer.call(__MODULE__, :get_statistics)
  end

  def get_monitoring_summary do
    GenServer.call(__MODULE__, :get_monitoring_summary)
  end

  def handle_call({:execute_query, query, setup}, _from, %{session: session, monitoring_state: monitoring_state} = state) do
    # Load any setup code if provided
    if setup && setup != "" do
      MQI.consult_string(session, setup)
    end

    # Monitor the query execution
    {result, new_monitoring_state} = Monitoring.monitor_query(
      monitoring_state,
      session,
      query,
      fn -> MQI.query(session, query) end
    )

    case result do
      {:ok, results} ->
        {:reply, {:ok, results}, %{state | monitoring_state: new_monitoring_state}}
      {:error, reason} ->
        {:reply, {:error, reason}, %{state | monitoring_state: new_monitoring_state}}
    end
  end

  def handle_call({:load_custom_rules, rules}, _from, %{session: session} = state) do
    case MQI.consult_string(session, rules) do
      {:ok, _} ->
        {:reply, :ok, state}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:facts_loaded?, _from, %{loaded: loaded} = state) do
    {:reply, loaded, state}
  end

  def handle_call({:load_facts_with_progress, pid}, _from, %{session: session} = state) do
    # Send progress updates to the LiveView
    send(pid, {:facts_loading_progress, 10, "Starting playground setup..."})

    send(pid, {:facts_loading_progress, 50, "Loading basic Prolog utilities..."})
    load_basic_rules(session)

    send(pid, {:facts_loading_progress, 90, "Finalizing playground environment..."})

    # Test that everything is working
    case MQI.query(session, "member(X, [1,2,3])") do
      {:ok, _results} ->
        send(pid, {:facts_loading_progress, 100, "Playground ready for custom queries!"})
        send(pid, {:facts_loaded, true})
        {:reply, :ok, %{state | loaded: true}}
      {:error, reason} ->
        send(pid, {:facts_loaded, false})
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:get_statistics, _from, %{session: session} = state) do
    case Monitoring.get_statistics(session) do
      {:ok, stats} ->
        {:reply, {:ok, stats}, state}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:get_monitoring_summary, _from, %{monitoring_state: monitoring_state} = state) do
    summary = Monitoring.get_summary(monitoring_state)
    {:reply, {:ok, summary}, state}
  end

  def handle_call(request, _from, state) do
    IO.puts("Unhandled call in PlaygroundSessionManager: #{inspect(request)}")
    {:reply, {:error, "Unhandled request"}, state}
  end

  def handle_info(msg, state) do
    IO.puts("Unhandled info in PlaygroundSessionManager: #{inspect(msg)}")
    {:noreply, state}
  end

  def terminate(_reason, %{session: session}) do
    MQI.stop_session(session)
  end

  defp load_basic_rules(session) do
    # Load some basic Prolog utilities and examples
    basic_rules = [
      # Basic list utilities
      "append([], L, L).",
      "append([H|T], L, [H|R]) :- append(T, L, R).",
      "member(X, [X|_]).",
      "member(X, [_|T]) :- member(X, T).",
      "length([], 0).",
      "length([_|T], N) :- length(T, M), N is M + 1.",
      # Basic arithmetic examples
      "factorial(0, 1).",
      "factorial(N, F) :- N > 0, M is N - 1, factorial(M, G), F is N * G.",
      # Basic tree examples
      "tree(nil).",
      "tree(node(_, L, R)) :- tree(L), tree(R).",
      # Basic graph examples
      "edge(a, b).",
      "edge(b, c).",
      "edge(c, d).",
      "path(X, Y) :- edge(X, Y).",
      "path(X, Y) :- edge(X, Z), path(Z, Y)."
    ]

    Enum.each(basic_rules, fn rule ->
      MQI.assertz(session, rule)
    end)

    IO.puts("✅ Loaded #{length(basic_rules)} basic Prolog rules for playground")
  end
end
