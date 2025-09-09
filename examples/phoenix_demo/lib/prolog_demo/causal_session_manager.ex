defmodule PrologDemo.CausalSessionManager do
  @moduledoc """
  Manages a persistent Prolog session specifically for causal reasoning with CauseNet data.
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
        # Initialize monitoring
        monitoring_state = Monitoring.init(debug_enabled: false, rate_limit_ms: 1000)

        # Load only causal reasoning rules (data loaded on-demand)
        load_causal_rules(session)

        {:ok, %{session: session, loaded: false, monitoring_state: monitoring_state}}
      {:error, reason} ->
        {:stop, {:error, "Failed to start MQI session: #{reason}"}}
    end
  end

  def query_causal_paths(start_concept, end_concept) do
    GenServer.call(__MODULE__, {:query_causal_paths, start_concept, end_concept})
  end

  def query_advanced_causal_paths(start_concept, end_concept, max_depth \\ 3) do
    GenServer.call(__MODULE__, {:query_advanced_causal_paths, start_concept, end_concept, max_depth})
  end

  def query_direct_causes(concept) do
    GenServer.call(__MODULE__, {:query_direct_causes, concept})
  end

  def query_direct_effects(concept) do
    GenServer.call(__MODULE__, {:query_direct_effects, concept})
  end

  def facts_loaded? do
    GenServer.call(__MODULE__, :facts_loaded?)
  end

  def get_session do
    GenServer.call(__MODULE__, :get_session)
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

  def handle_call({:query_causal_paths, start_concept, end_concept}, _from, %{session: session, monitoring_state: monitoring_state} = state) do
    # Try a simpler query first - just direct causes
    query = "causes('#{start_concept}', '#{end_concept}')"

    {result, new_monitoring_state} = Monitoring.monitor_query(monitoring_state, session, query, fn ->
      MQI.query(session, query)
    end)

    case result do
      {:ok, results} ->
        if length(results) > 0 do
          # Direct relationship exists
          {:reply, {:ok, [[start_concept, end_concept]]}, %{state | monitoring_state: new_monitoring_state}}
        else
          # Try to find a 2-step path
          query2 = "causes('#{start_concept}', X), causes(X, '#{end_concept}')"

          {result2, final_monitoring_state} = Monitoring.monitor_query(new_monitoring_state, session, query2, fn ->
            MQI.query(session, query2)
          end)

          case result2 do
            {:ok, results2} when is_list(results2) and length(results2) > 0 ->
              # Take only first 10 results to avoid MQI parsing issues
              limited_results = Enum.take(results2, 10)
              paths = Enum.map(limited_results, fn result -> [start_concept, result["X"], end_concept] end)
              {:reply, {:ok, paths}, %{state | monitoring_state: final_monitoring_state}}
            _ ->
              {:reply, {:ok, []}, %{state | monitoring_state: final_monitoring_state}}
          end
        end
      {:error, reason} ->
        {:reply, {:error, reason}, %{state | monitoring_state: new_monitoring_state}}
    end
  end

  def handle_call({:query_advanced_causal_paths, start_concept, end_concept, max_depth}, _from, %{session: session} = state) do
    # Use a more sophisticated path-finding algorithm with depth limiting
    # and statistics to avoid timeouts

    # First, get statistics to understand the current state
    case MQI.query(session, "statistics(inferences, Inferences)") do
      {:ok, [%{"Inferences" => inferences}]} ->
        IO.puts("Starting advanced path search with #{inferences} inferences so far")
      {:error, _} ->
        IO.puts("Could not get initial statistics")
    end

    # Try different approaches based on depth with better error handling
    result = case max_depth do
      1 ->
        # Direct relationship only
        query = "causes('#{start_concept}', '#{end_concept}')"
        case MQI.query(session, query) do
          {:ok, [_|_] = _results} ->
            {:ok, [[start_concept, end_concept]]}
          _ ->
            {:ok, []}
        end

      2 ->
        # Two-step paths with timeout protection
        query = """
        (causes('#{start_concept}', '#{end_concept}') ->
          Path = ['#{start_concept}', '#{end_concept}'];
        (causes('#{start_concept}', Intermediate), causes(Intermediate, '#{end_concept}')) ->
          Path = ['#{start_concept}', Intermediate, '#{end_concept}'])
        """
        case MQI.query(session, query) do
          {:ok, results} ->
            paths = Enum.map(results, &(&1["Path"]))
            {:ok, paths}
          {:error, reason} ->
            {:error, reason}
        end

      _ ->
        # Multi-step paths with depth limiting - use simpler approach to avoid MQI parsing issues
        # Try 2-step paths first, then 3-step if needed
        query2 = "causes('#{start_concept}', X), causes(X, '#{end_concept}')"
        
        case MQI.query(session, query2) do
          {:ok, results2} when length(results2) > 0 ->
            # Found 2-step paths
            paths = Enum.take(results2, 10) # Limit to prevent MQI issues
            |> Enum.map(fn result -> [start_concept, result["X"], end_concept] end)
            {:ok, paths}
          _ ->
            # Try 3-step paths if no 2-step found
            query3 = "causes('#{start_concept}', X), causes(X, Y), causes(Y, '#{end_concept}')"
            case MQI.query(session, query3) do
              {:ok, results3} ->
                paths = Enum.take(results3, 5) # Even smaller limit for 3-step
                |> Enum.map(fn result -> [start_concept, result["X"], result["Y"], end_concept] end)
                {:ok, paths}
              {:error, _} ->
                {:ok, []}
            end
        end
    end

    # Get final statistics
    case MQI.query(session, "statistics(inferences, FinalInferences)") do
      {:ok, [%{"FinalInferences" => final_inferences}]} ->
        IO.puts("Advanced path search completed with #{final_inferences} total inferences")
      {:error, _} ->
        IO.puts("Could not get final statistics")
    end

    {:reply, result, state}
  end

  def handle_call({:query_direct_causes, concept}, _from, %{session: session} = state) do
    query = "causes(X, '#{concept}')"

    case MQI.query(session, query) do
      {:ok, results} ->
        causes = Enum.map(results, &(&1["X"]))
        {:reply, {:ok, causes}, state}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:query_direct_effects, concept}, _from, %{session: session} = state) do
    query = "causes('#{concept}', Y)"

    case MQI.query(session, query) do
      {:ok, results} ->
        effects = Enum.map(results, &(&1["Y"]))
        {:reply, {:ok, effects}, state}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:facts_loaded?, _from, %{loaded: loaded} = state) do
    {:reply, loaded, state}
  end

  def handle_call(:get_session, _from, %{session: session} = state) do
    {:reply, {:ok, session}, state}
  end

  def handle_call({:load_dataset, size}, _from, %{session: session} = state) do
    result = case size do
      :small ->
        load_causenet_data_subset(session, 100)
      :medium ->
        load_causenet_data_subset(session, 500)
      :large ->
        load_causenet_data_subset(session, 2000)
      :full ->
        load_causenet_data_full(session)
    end
    
    case result do
      {:ok, count} ->
        {:reply, {:ok, count}, %{state | loaded: true}}
      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:load_facts_with_progress, pid}, _from, %{session: session} = state) do
    # Send progress updates to the LiveView
    send(pid, {:facts_loading_progress, 10, "Starting causal reasoning setup..."})

    # Load CauseNet data with progress updates (default to small for backward compatibility)
    send(pid, {:facts_loading_progress, 30, "Loading CauseNet relationships..."})
    
    case load_causenet_data_subset(session, 100) do
      {:ok, fact_count} ->
        send(pid, {:facts_loading_progress, 60, "Loading causal reasoning rules..."})
        load_causal_rules(session)
        
        send(pid, {:facts_loading_progress, 90, "Finalizing causal knowledge base..."})
        
        # Verify everything is working
        send(pid, {:facts_loading_progress, 100, "Loaded #{fact_count} causal relationships!"})
        send(pid, {:facts_loaded, fact_count})
        {:reply, :ok, %{state | loaded: true}}
        
      {:error, reason} ->
        send(pid, {:facts_loaded, false})
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:get_statistics, _from, %{session: session, monitoring_state: monitoring_state} = state) do
    case Monitoring.get_statistics(session) do
      {:ok, stats} ->
        summary = Monitoring.get_summary(monitoring_state)
        combined_stats = Map.merge(stats, summary)
        {:reply, {:ok, combined_stats}, state}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:get_monitoring_summary, _from, %{monitoring_state: monitoring_state} = state) do
    summary = Monitoring.get_summary(monitoring_state)
    {:reply, {:ok, summary}, state}
  end

  def handle_call(request, _from, state) do
    IO.puts("Unhandled call in CausalSessionManager: #{inspect(request)}")
    {:reply, {:error, "Unhandled request"}, state}
  end

  def handle_info(msg, state) do
    IO.puts("Unhandled info in CausalSessionManager: #{inspect(msg)}")
    {:noreply, state}
  end

  def terminate(_reason, %{session: session}) do
    MQI.stop_session(session)
  end

  def load_dataset(size \\ :small) do
    GenServer.call(__MODULE__, {:load_dataset, size})
  end

  defp load_causenet_data_subset(session, limit) do
    IO.puts("📊 Loading CauseNet dataset subset (#{limit} relationships)...")
    
    relationships = PrologDemo.CauseNetDataLoader.load_manageable_subset(limit)
    causenet_facts = PrologDemo.CauseNetDataLoader.to_prolog_facts(relationships)

    case MQI.consult_string(session, causenet_facts) do
      {:ok, _} ->
        IO.puts("✅ Loaded #{length(relationships)} CauseNet relationships for causal reasoning")
        {:ok, length(relationships)}
      {:error, reason} ->
        IO.puts("❌ Failed to load CauseNet data: #{reason}")
        {:error, reason}
    end
  end

  defp load_causenet_data_full(session) do
    IO.puts("📊 Loading full CauseNet dataset (this may take a while)...")
    
    # Load real CauseNet data
    causenet_facts = PrologDemo.CauseNetService.get_causenet_prolog_facts()

    case MQI.consult_string(session, causenet_facts) do
      {:ok, _} ->
        relationships_count = String.split(causenet_facts, "\n") |> Enum.count()
        IO.puts("✅ Loaded #{relationships_count} CauseNet relationships for causal reasoning")
        {:ok, relationships_count}
      {:error, reason} ->
        IO.puts("❌ Failed to load CauseNet data: #{reason}")
        {:error, reason}
    end
  end

  defp load_causal_rules(session) do
    causal_rules = [
      "causal_chain(X, Y) :- causes(X, Y).",
      "causal_chain(X, Z) :- causes(X, Y), causal_chain(Y, Z).",
      "causal_path(X, Y, [X,Y]) :- causes(X, Y).",
      "causal_path(X, Z, [X|Path]) :- causes(X, Y), causal_path(Y, Z, Path).",
      "causal_chain(X, Y, MaxLength) :- causes(X, Y), MaxLength >= 1.",
      "causal_chain(X, Z, MaxLength) :- causes(X, Y), MaxLength > 1, MaxLength1 is MaxLength - 1, causal_chain(Y, Z, MaxLength1).",
      "causal_impact(X, Y, Impact) :- causes(X, Y), Impact = 1.",
      "causal_impact(X, Z, Impact) :- causes(X, Y), causal_impact(Y, Z, SubImpact), Impact is SubImpact + 1.",
      "intervention_point(Start, End, Point) :- causal_path(Start, End, Path), member(Point, Path), Point \\= Start, Point \\= End.",
      # Advanced path finding with depth limiting and cycle detection
      # The 4-argument version is the entry point, the 5-argument version does the work
      "find_paths(Start, End, MaxDepth, Path) :- find_paths_helper(Start, End, MaxDepth, [Start], RevPath), reverse(RevPath, Path).",
      "find_paths_helper(End, End, _, Visited, Visited).",
      "find_paths_helper(Start, End, MaxDepth, Visited, Path) :- MaxDepth > 0, causes(Start, Next), \\+ member(Next, Visited), MaxDepth1 is MaxDepth - 1, find_paths_helper(Next, End, MaxDepth1, [Next|Visited], Path).",
      # Two-step path finder (more efficient for common cases)
      "two_step_path(Start, End, [Start, Intermediate, End]) :- causes(Start, Intermediate), causes(Intermediate, End), Start \\= Intermediate, Intermediate \\= End.",
      # Direct path finder
      "direct_path(Start, End, [Start, End]) :- causes(Start, End)."
    ]

    Enum.each(causal_rules, fn rule ->
      MQI.assertz(session, rule)
    end)

    IO.puts("✅ Loaded #{length(causal_rules)} causal reasoning rules")
  end
end
