defmodule PrologDemoWeb.CauseNetController do
  use PrologDemoWeb, :controller
  alias PrologDemo.{CausalSessionManager, ConstraintSessionManager, PlaygroundSessionManager}

  def index(conn, _params) do
    render(conn, :index)
  end

  def get_domains(conn, _params) do
    domains = [
      %{id: "health", name: "Health & Medicine", icon: "🏥"},
      %{id: "climate", name: "Climate & Environment", icon: "🌍"},
      %{id: "economics", name: "Economics & Finance", icon: "💰"},
      %{id: "social", name: "Social & Behavioral", icon: "👥"}
    ]
    json(conn, %{domains: domains})
  end

  def query_causal_relationships(conn, %{"start" => start_concept, "end" => end_concept} = params) do
    search_type = Map.get(params, "type", "direct_path")

    result = case search_type do
      "direct_path" ->
        case CausalSessionManager.query_advanced_causal_paths(start_concept, end_concept, 1) do
          {:ok, paths} when length(paths) > 0 ->
            {:ok, %{
              paths: paths,
              type: "direct",
              message: "Direct causal relationship found"
            }}
          _ ->
            # Try multi-step path
            case CausalSessionManager.query_advanced_causal_paths(start_concept, end_concept, 3) do
              {:ok, paths} when length(paths) > 0 ->
                {:ok, %{
                  paths: paths,
                  type: "multi_step",
                  message: "Multi-step causal path found"
                }}
              _ ->
                {:error, "No causal path found between #{start_concept} and #{end_concept}"}
            end
        end

      "all_paths" ->
        case CausalSessionManager.query_advanced_causal_paths(start_concept, end_concept, 3) do
          {:ok, paths} ->
            {:ok, %{
              paths: paths,
              type: "all",
              message: "Found #{length(paths)} causal path(s)"
            }}
          error ->
            error
        end

      _ ->
        {:error, "Unknown search type: #{search_type}"}
    end

    case result do
      {:ok, data} ->
        json(conn, %{success: true, data: data})
      {:error, reason} ->
        json(conn, %{success: false, error: reason})
    end
  end

  def query_direct_causes(conn, %{"concept" => concept}) do
    case CausalSessionManager.query_direct_causes(concept) do
      {:ok, causes} ->
        json(conn, %{
          success: true,
          data: %{
            concept: concept,
            causes: causes,
            count: length(causes)
          }
        })
      {:error, reason} ->
        json(conn, %{success: false, error: reason})
    end
  end

  def query_direct_effects(conn, %{"concept" => concept}) do
    case CausalSessionManager.query_direct_effects(concept) do
      {:ok, effects} ->
        json(conn, %{
          success: true,
          data: %{
            concept: concept,
            effects: effects,
            count: length(effects)
          }
        })
      {:error, reason} ->
        json(conn, %{success: false, error: reason})
    end
  end

  def query_advanced_causal_paths(conn, %{"start" => start_concept, "end" => end_concept} = params) do
    max_depth = String.to_integer(Map.get(params, "max_depth", "3"))

    case CausalSessionManager.query_advanced_causal_paths(start_concept, end_concept, max_depth) do
      {:ok, paths} ->
        json(conn, %{
          success: true,
          data: %{
            start: start_concept,
            end: end_concept,
            paths: paths,
            count: length(paths),
            max_depth: max_depth
          }
        })
      {:error, reason} ->
        json(conn, %{success: false, error: reason})
    end
  end

  def solve_constraint_puzzle(conn, %{"puzzle_type" => puzzle_type} = params) do
    result = case puzzle_type do
      "n_queens" ->
        n = String.to_integer(Map.get(params, "n", "8"))
        ConstraintSessionManager.query_constraint_solver("n_queens", %{"n" => n})

      "sudoku" ->
        ConstraintSessionManager.query_constraint_solver("sudoku", params)

      _ ->
        {:error, "Unknown puzzle type: #{puzzle_type}"}
    end

    case result do
      {:ok, solution} ->
        json(conn, %{success: true, data: solution})
      {:error, reason} ->
        json(conn, %{success: false, error: reason})
    end
  end

  def execute_playground_query(conn, %{"query" => query} = params) do
    setup = Map.get(params, "setup", "")

    case PlaygroundSessionManager.execute_query(query, setup) do
      {:ok, results} ->
        json(conn, %{
          success: true,
          data: %{
            query: query,
            results: results,
            count: length(results)
          }
        })
      {:error, reason} ->
        json(conn, %{success: false, error: reason})
    end
  end

  # Handle constraint solving through the session manager
  def constraint_solver(conn, %{"solver" => solver, "puzzle" => puzzle}) do
    case solver do
      "sudoku" ->
        case ConstraintSessionManager.query_constraint_solver("sudoku", %{"puzzle" => puzzle}) do
          {:ok, solution} ->
            json(conn, %{success: true, data: solution})
          {:error, reason} ->
            json(conn, %{success: false, error: reason})
        end
      "n_queens" ->
        n = length(puzzle)
        case ConstraintSessionManager.query_constraint_solver("n_queens", %{"n" => n}) do
          {:ok, solution} ->
            json(conn, %{success: true, data: solution})
          {:error, reason} ->
            json(conn, %{success: false, error: reason})
        end
      _ ->
        json(conn, %{success: false, error: "Unknown solver type: #{solver}"})
    end
  end

  def solve_constraint(conn, params) do
    case solve_constraint_puzzle(conn, params) do
      {:ok, result} ->
        json(conn, %{success: true, data: result})
      {:error, reason} ->
        json(conn, %{success: false, error: reason})
    end
  end

  # Helper function for the playground
  def execute_query(conn, %{"query" => query} = params) do
    setup = Map.get(params, "setup", "")

    case PlaygroundSessionManager.execute_query(query, setup) do
      {:ok, results} ->
        json(conn, %{
          success: true,
          data: %{
            query: query,
            results: results,
            count: length(results)
          }
        })
      {:error, reason} ->
        json(conn, %{success: false, error: reason})
    end
  end

  # Removed unused functions - these are now handled by session managers:
  # - solve_n_queens/2
  # - solve_sudoku/2
  # - solve_graph_coloring/2
  # - load_comprehensive_causenet_data/1
  # - load_enhanced_causal_rules/1
  # These functions were duplicates of functionality in the session managers
end
