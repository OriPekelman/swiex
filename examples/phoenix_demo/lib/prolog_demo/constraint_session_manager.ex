defmodule PrologDemo.ConstraintSessionManager do
  @moduledoc """
  Manages a persistent Prolog session specifically for constraint solving (N-Queens, Sudoku).
  """

  use GenServer
  require Logger
  alias Swiex.MQI
  alias Swiex.Monitoring

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_state) do
    IO.puts("🟡 ConstraintSessionManager starting up...")
    
    case MQI.start_session() do
      {:ok, session} ->
        IO.puts("✅ ConstraintSessionManager MQI session started successfully")
        # Initialize monitoring state
        monitoring_state = Monitoring.init(debug_enabled: false, rate_limit_ms: 1000)

        # Load only constraint solving rules
        load_constraint_rules(session)

        IO.puts("✅ ConstraintSessionManager initialization completed")
        {:ok, %{session: session, loaded: true, monitoring_state: monitoring_state}}
      {:error, reason} ->
        IO.puts("❌ ConstraintSessionManager failed to start MQI session: #{reason}")
        {:stop, {:error, "Failed to start MQI session: #{reason}"}}
    end
  end

  def query_constraint_solver(puzzle_type, params) do
    # Use longer timeout for Sudoku as it's more complex
    timeout = if puzzle_type == "sudoku", do: 30_000, else: 5_000
    GenServer.call(__MODULE__, {:query_constraint_solver, puzzle_type, params}, timeout)
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

  def handle_call({:query_constraint_solver, puzzle_type, params}, _from, %{session: session, monitoring_state: monitoring_state} = state) do
    case puzzle_type do
      "n_queens" ->
        n = Map.get(params, "n", 8)  # Default to 8x8 board

        start_time = System.monotonic_time(:millisecond)

        IO.puts("🔥 Solving #{n}-Queens using CLP(FD)!")

        # Use the CLP(FD) solver to find all solutions (limited to first 20)
        query = "find_n_queens_solutions(#{n}, Solutions)"

        result = MQI.query(session, query)
        end_time = System.monotonic_time(:millisecond)

        new_monitoring_state = %{monitoring_state |
          query_count: monitoring_state.query_count + 1,
          total_time_ms: monitoring_state.total_time_ms + (end_time - start_time)
        }

        case result do
          {:ok, [%{"Solutions" => solutions}]} when is_list(solutions) ->
            IO.puts("✅ CLP(FD) found #{length(solutions)} solutions for #{n}-Queens")
            {:reply, {:ok, %{
              n: n,
              solutions: solutions,  # Display all solutions
              count: length(solutions),
              display_limit: length(solutions),
              solver_type: "clp_fd",
              note: "🚀 Solved using Constraint Logic Programming!"
            }}, %{state | monitoring_state: new_monitoring_state}}

          {:error, reason} ->
            IO.puts("❌ CLP(FD) N-Queens solver failed: #{inspect(reason)}")
            # Try a single solution as fallback
            case MQI.query(session, "n_queens_solve(#{n}, Solution)") do
              {:ok, [%{"Solution" => solution}]} ->
                IO.puts("✅ Got single CLP solution as fallback")
                {:reply, {:ok, %{
                  n: n,
                  solutions: [solution],
                  count: 1,
                  display_limit: 1,
                  solver_type: "clp_fd_single",
                  note: "Single solution from CLP(FD)"
                }}, %{state | monitoring_state: new_monitoring_state}}
              
              {:error, single_error} ->
                IO.puts("❌ Single solution also failed: #{inspect(single_error)}")
                {:reply, {:error, "N-Queens CLP solver failed: #{inspect(reason)}, Single: #{inspect(single_error)}"}, 
                 %{state | monitoring_state: new_monitoring_state}}
            end

          other ->
            IO.puts("⚠️ Unexpected N-Queens result: #{inspect(other)}")
            {:reply, {:error, "Unexpected result: #{inspect(other)}"}, %{state | monitoring_state: new_monitoring_state}}
        end

      "sudoku" ->
        start_time = System.monotonic_time(:millisecond)

        # 🚀 ELIXIR INTEGRATION: Generate random 9x9 puzzle on Elixir side!
        {elixir_puzzle, elixir_solution} = PrologDemo.SudokuGenerator.generate_9x9_puzzle()
        
        # Validate the Elixir-generated solution
        is_valid = PrologDemo.SudokuGenerator.validate_solution(elixir_solution)
        
        IO.puts("🔥 Generated new 9x9 Sudoku puzzle in Elixir!")
        IO.puts("📊 Elixir validation: #{if is_valid, do: "✅ Valid", else: "❌ Invalid"}")

        # 🎯 PROLOG INTEGRATION: Solve the Elixir-generated puzzle using CLP(FD)!
        puzzle_str = format_puzzle_for_prolog(elixir_puzzle)
        solve_query = "solve_sudoku_puzzle(#{puzzle_str}, PrologSolution)"
        
        IO.puts("🔥 Solving with Prolog CLP(FD): #{solve_query}")
        
        # Test if the MQI session is still active and restart if needed
        {active_session, updated_state} = case MQI.query(session, "true") do
          {:ok, _} -> 
            IO.puts("✅ MQI session is active")
            {session, state}
          {:error, reason} -> 
            IO.puts("❌ MQI session test failed: #{inspect(reason)}")
            # Try to restart the session
            case MQI.start_session() do
              {:ok, new_session} ->
                IO.puts("✅ Restarted MQI session")
                # Reload all constraint rules
                load_constraint_rules(new_session)
                # Return updated session and state
                {new_session, %{state | session: new_session}}
              {:error, restart_error} ->
                IO.puts("❌ Failed to restart MQI session: #{inspect(restart_error)}")
                {session, state}
            end
        end

        case MQI.query(active_session, solve_query) do
          {:ok, results} when is_list(results) and length(results) > 0 ->
            # Take the first solution when Prolog returns multiple solutions
            first_result = hd(results)
            IO.puts("🔧 Prolog found #{length(results)} solutions, using the first one")
            
            end_time = System.monotonic_time(:millisecond)
            new_monitoring_state = %{monitoring_state |
              query_count: monitoring_state.query_count + 1,
              total_time_ms: monitoring_state.total_time_ms + (end_time - start_time)
            }

            # Extract the PrologSolution matrix and substitute variables with actual values
            prolog_solution = case Map.get(first_result, "PrologSolution") do
              matrix when is_list(matrix) ->
                # Substitute alphabetic variables with their actual numeric values
                substitute_variables_in_matrix(matrix, first_result)
              other ->
                IO.puts("⚠️ Unexpected PrologSolution format: #{inspect(other)}")
                other
            end
            
            # Validate Prolog solution using Elixir
            prolog_validation = PrologDemo.SudokuGenerator.validate_solution(prolog_solution)
            
            # Compare Elixir and Prolog solutions
            solutions_match = elixir_solution == prolog_solution
            
            IO.puts("✅ Prolog solved the puzzle! Validation: #{prolog_validation}, Match with Elixir: #{solutions_match}")

            {:reply, {:ok, %{
              puzzle: elixir_puzzle,
              solution: prolog_solution,  # Use processed Prolog solution with numeric values
              elixir_solution: elixir_solution,
              solutions_match: solutions_match,
              elixir_validation: prolog_validation,  # Validate the Prolog solution
              time_ms: end_time - start_time,
              count: 1,
              generated_by: "elixir",
              solved_by: "prolog_clp",
              integration_demo: true,
              note: "🚀 Elixir-generated puzzle solved by Prolog CLP(FD)!"
            }}, %{updated_state | monitoring_state: new_monitoring_state}}

          {:ok, []} ->
            # Empty result - Prolog didn't find a solution
            IO.puts("⚠️ Prolog solver returned no solutions - puzzle may be unsolvable or rules incorrect")
            end_time = System.monotonic_time(:millisecond)
            new_monitoring_state = %{monitoring_state |
              query_count: monitoring_state.query_count + 1,
              total_time_ms: monitoring_state.total_time_ms + (end_time - start_time)
            }

            # Return the Elixir solution as fallback with explanation
            {:reply, {:ok, %{
              puzzle: elixir_puzzle,
              solution: elixir_solution,  # Use Elixir solution as fallback
              elixir_solution: elixir_solution,
              solutions_match: false,
              elixir_validation: true,
              time_ms: end_time - start_time,
              count: 1,
              generated_by: "elixir",
              solved_by: "elixir_fallback",
              integration_demo: false,
              note: "⚠️ Prolog solver found no solution - using Elixir solution as fallback"
            }}, %{updated_state | monitoring_state: new_monitoring_state}}

          {:error, reason} ->
            IO.puts("❌ Prolog CLP(FD) solver failed: #{inspect(reason)}")
            end_time = System.monotonic_time(:millisecond)
            new_monitoring_state = %{monitoring_state |
              query_count: monitoring_state.query_count + 1,
              total_time_ms: monitoring_state.total_time_ms + (end_time - start_time)
            }

            {:reply, {:error, "Prolog CLP(FD) solver failed: #{inspect(reason)}"}, %{updated_state | monitoring_state: new_monitoring_state}}

          other ->
            IO.puts("⚠️ Unexpected Prolog result: #{inspect(other)}")
            end_time = System.monotonic_time(:millisecond)
            new_monitoring_state = %{monitoring_state |
              query_count: monitoring_state.query_count + 1,
              total_time_ms: monitoring_state.total_time_ms + (end_time - start_time)
            }

            {:reply, {:error, "Unexpected Prolog result: #{inspect(other)}"}, %{updated_state | monitoring_state: new_monitoring_state}}
        end

      _ ->
        {:reply, {:error, "Unknown puzzle type: #{puzzle_type}"}, state}
    end
  end

  def handle_call(:facts_loaded?, _from, %{loaded: loaded} = state) do
    {:reply, loaded, state}
  end

  # Note: Async queries are not currently used as MQI doesn't support them at protocol level
  # These functions are kept for future reference if MQI adds async support


  def handle_call({:load_facts_with_progress, pid}, _from, %{session: session} = state) do
    # Send progress updates to the LiveView
    send(pid, {:facts_loading_progress, 10, "Starting constraint solver setup..."})

    send(pid, {:facts_loading_progress, 50, "Loading N-Queens solver..."})
    load_n_queens_rules(session)

    send(pid, {:facts_loading_progress, 80, "Loading Sudoku solver..."})
    load_sudoku_rules(session)

    send(pid, {:facts_loading_progress, 90, "Finalizing constraint solvers..."})

    # Test that everything is working
    case MQI.query(session, "n_queens_solution(4, _)") do
      {:ok, _results} ->
        send(pid, {:facts_loading_progress, 100, "Loaded constraint solvers successfully!"})
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
    IO.puts("Unhandled call in ConstraintSessionManager: #{inspect(request)}")
    {:reply, {:error, "Unhandled request"}, state}
  end

  def handle_info(msg, state) do
    IO.puts("Unhandled info in ConstraintSessionManager: #{inspect(msg)}")
    {:noreply, state}
  end

  def terminate(_reason, %{session: session}) do
    MQI.stop_session(session)
  end

  defp load_constraint_rules(session) do
    IO.puts("🚀 Starting constraint rules loading...")
    load_n_queens_rules(session)
    load_sudoku_rules(session)
    IO.puts("🏁 Finished constraint rules loading")
  end

  defp load_n_queens_rules(session) do
    IO.puts("📋 Loading N-Queens CLP solver...")
    
    # First, try to load the CLP(FD) module
    case MQI.query(session, "use_module(library(clpfd))") do
      {:ok, _} -> 
        IO.puts("✅ CLP(FD) module loaded successfully")
      {:error, reason} -> 
        IO.puts("⚠️ CLP(FD) module load warning: #{reason}")
    end
    
    # Load proper N-Queens CLP(FD) solver
    n_queens_rules = [
      "n_queens_solve(NumQueens, Positions) :- length(Positions, NumQueens), Positions ins 1..NumQueens, safe_queens(Positions), label(Positions).",
      "safe_queens([]).",
      "safe_queens([Q|Qs]) :- safe_queens(Qs), no_attack(Q, Qs, 1).",
      "no_attack(_, [], _).",
      "no_attack(Q, [Q1|Qs], Dist) :- Q #\\= Q1, abs(Q - Q1) #\\= Dist, Dist1 #= Dist + 1, no_attack(Q, Qs, Dist1).",
      "find_n_queens_solutions(NumQueens, Solutions) :- findall(Positions, n_queens_solve(NumQueens, Positions), Solutions).",
      "n_queens(NumQueens, Solution) :- n_queens_solve(NumQueens, Solution).",
      "n_queens_solution(NumQueens, Solution) :- n_queens_solve(NumQueens, Solution)."
    ]

    success_count = Enum.reduce(n_queens_rules, 0, fn rule, acc ->
      case MQI.assertz(session, rule) do
        {:ok, _} -> acc + 1
        {:error, reason} -> 
          IO.puts("⚠️ Failed to load rule '#{rule}': #{reason}")
          acc
      end
    end)

    if success_count == length(n_queens_rules) do
      IO.puts("✅ Loaded N-Queens solver with #{success_count} rules")
    else
      IO.puts("⚠️ Loaded #{success_count}/#{length(n_queens_rules)} N-Queens rules")
    end
  end

  defp load_sudoku_rules(session) do
    IO.puts("🧩 Loading Sudoku CLP solver...")
    
    # Load proper CLP(FD) Sudoku solver using SWI-Prolog's built-in predicates
    sudoku_rules = [
      # Main solver predicate using CLP(FD) constraints  
      "solve_sudoku_puzzle(Puzzle, Solution) :- Solution = Puzzle, sudoku(Solution), ground(Solution).",
      
      # SWI-Prolog CLP(FD) Sudoku solver using built-in transpose
      "sudoku(Rows) :- length(Rows, 9), maplist(same_length(Rows), Rows), append(Rows, Vars), Vars ins 1..9, maplist(all_distinct, Rows), transpose(Rows, Cols), maplist(all_distinct, Cols), distinct_squares(Rows), labeling([], Vars).",
      
      # Validate 3x3 squares
      "distinct_squares([]).",
      "distinct_squares([R1, R2, R3 | Rows]) :- distinct_square(R1, R2, R3), distinct_squares(Rows).",
      
      # Check one 3x3 square for distinctness
      "distinct_square([], [], []).",
      "distinct_square([N11, N12, N13 | Tail1], [N21, N22, N23 | Tail2], [N31, N32, N33 | Tail3]) :- all_distinct([N11, N12, N13, N21, N22, N23, N31, N32, N33]), distinct_square(Tail1, Tail2, Tail3)."
    ]

    success_count = Enum.reduce(sudoku_rules, 0, fn rule, acc ->
      case MQI.assertz(session, rule) do
        {:ok, _} -> acc + 1
        {:error, reason} -> 
          IO.puts("⚠️ Failed to load Sudoku rule: #{reason}")
          acc
      end
    end)

    if success_count == length(sudoku_rules) do
      IO.puts("✅ Loaded working Sudoku CLP solver with #{success_count} rules")
    else
      IO.puts("⚠️ Loaded #{success_count}/#{length(sudoku_rules)} Sudoku rules")
    end
  end

  # Helper function to format Elixir puzzle for Prolog
  # Empty squares (0) are represented as unbound variables for CLP(FD)
  defp format_puzzle_for_prolog(puzzle) do
    # Create a unique variable for each empty cell
    {rows_str, _counter} = puzzle
    |> Enum.reduce({"", 1}, fn row, {acc_rows, var_counter} ->
      {row_str, new_counter} = row
      |> Enum.reduce({"", var_counter}, fn cell, {acc_cells, counter} ->
        cell_str = if cell == 0 do
          # Use a unique variable name for each empty cell
          {"V#{counter}", counter + 1}
        else
          {to_string(cell), counter}
        end
        
        case cell_str do
          {str, new_cnt} ->
            separator = if acc_cells == "", do: "", else: ", "
            {acc_cells <> separator <> str, new_cnt}
        end
      end)
      
      row_formatted = "[#{row_str}]"
      separator = if acc_rows == "", do: "", else: ", "
      {acc_rows <> separator <> row_formatted, new_counter}
    end)
    
    "[#{rows_str}]"
  end

  # Helper function to substitute alphabetic variables with their numeric values in the solution matrix
  defp substitute_variables_in_matrix(matrix, results) when is_list(matrix) and is_map(results) do
    # Build a map of variable bindings from the MQI results
    variable_map = results
    |> Enum.filter(fn {key, _value} -> key not in ["PrologSolution"] end)
    |> Enum.into(%{})
    
    IO.puts("🔧 Variable bindings found: #{inspect(variable_map)}")
    
    # Recursively substitute variables in the matrix
    substitute_in_data(matrix, variable_map)
  end
  
  # Recursively substitute variables in nested data structures
  defp substitute_in_data(data, variable_map) when is_list(data) do
    Enum.map(data, fn element ->
      substitute_in_data(element, variable_map)
    end)
  end
  
  defp substitute_in_data(data, variable_map) when is_binary(data) do
    # If this is a variable name, substitute it with the actual value
    case Map.get(variable_map, data) do
      nil -> data  # Not a variable, return as-is
      value -> substitute_in_data(value, variable_map)  # Recursively substitute
    end
  end
  
  defp substitute_in_data(data, _variable_map) do
    # Numbers and other data types return as-is
    data
  end

end
