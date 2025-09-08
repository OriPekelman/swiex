defmodule PrologDemo.ConstraintSessionManager do
  @moduledoc """
  Manages a persistent Prolog session specifically for constraint solving (N-Queens, Sudoku).
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

        # Load only constraint solving rules
        load_constraint_rules(session)

        {:ok, %{session: session, loaded: true, monitoring_state: monitoring_state}}
      {:error, reason} ->
        {:stop, {:error, "Failed to start MQI session: #{reason}"}}
    end
  end

  def query_constraint_solver(puzzle_type, params) do
    GenServer.call(__MODULE__, {:query_constraint_solver, puzzle_type, params})
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
        n = Map.get(params, "n", 4)
        # Use setof to get unique solutions only, limit to prevent overwhelming
        query = "setof(Solution, n_queens_solution(#{n}, Solution), Solutions)"

        # Monitor the query execution
        {result, new_monitoring_state} = Monitoring.monitor_query(
          monitoring_state,
          session,
          query,
          fn -> MQI.query(session, query) end
        )

        case result do
          {:ok, results} ->
            # setof returns a single result with Solutions as a list
            all_solutions = case results do
              [%{"Solutions" => sols}] when is_list(sols) -> sols
              _ -> []
            end

            # Return all solutions but let the UI decide how many to display
            {:reply, {:ok, %{
              n: n,
              solutions: all_solutions,
              count: length(all_solutions),
              display_limit: 10  # Suggest displaying first 10
            }}, %{state | monitoring_state: new_monitoring_state}}
          {:error, reason} ->
            {:reply, {:error, reason}, %{state | monitoring_state: new_monitoring_state}}
        end

      "sudoku" ->
        # First get the puzzle
        puzzle_query = "get_sample_sudoku(Puzzle)"
        puzzle_result = MQI.query(session, puzzle_query)

        puzzle = case puzzle_result do
          {:ok, [%{"Puzzle" => p} | _]} -> p
          _ -> nil
        end

        # Then solve it with monitoring
        query = "get_sample_sudoku(Puzzle), sudoku_solution(Puzzle, Solution)"

        start_time = System.monotonic_time(:millisecond)
        {result, new_monitoring_state} = Monitoring.monitor_query(
          monitoring_state,
          session,
          query,
          fn -> MQI.query(session, query) end
        )
        end_time = System.monotonic_time(:millisecond)

        case result do
          {:ok, [%{"Solution" => solution} | _]} ->
            {:reply, {:ok, %{
              puzzle: puzzle,
              solution: solution,
              time_ms: end_time - start_time,
              count: 1
            }}, %{state | monitoring_state: new_monitoring_state}}
          {:ok, _} ->
            {:reply, {:ok, %{puzzle: puzzle, solution: nil, count: 0}}, %{state | monitoring_state: new_monitoring_state}}
          {:error, reason} ->
            {:reply, {:error, reason}, %{state | monitoring_state: new_monitoring_state}}
        end

      _ ->
        {:reply, {:error, "Unknown puzzle type: #{puzzle_type}"}, state}
    end
  end

  def handle_call(:facts_loaded?, _from, %{loaded: loaded} = state) do
    {:reply, loaded, state}
  end

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
    load_n_queens_rules(session)
    load_sudoku_rules(session)
  end

  defp load_n_queens_rules(session) do
    # Simple N-Queens solver without CLP(FD)
    n_queens_code = """
    % Generate a permutation of numbers 1 to N
    permutation([], []).
    permutation([H|T], L) :-
        permutation(T, L1),
        select(H, L, L1).

    % Generate list from 1 to N
    range(1, 1, [1]) :- !.
    range(1, N, [1|Rest]) :-
        N > 1,
        N1 is N - 1,
        range(2, N, Rest).
    range(M, N, [M|Rest]) :-
        M < N,
        M1 is M + 1,
        range(M1, N, Rest).
    range(N, N, [N]).

    % Check if queens are safe
    queens_safe([]).
    queens_safe([_]).
    queens_safe([Q1|Rest]) :-
        safe_from_all(Q1, Rest, 1),
        queens_safe(Rest).

    % Check if Q1 is safe from all queens in the list
    safe_from_all(_, [], _).
    safe_from_all(Q1, [Q2|Rest], Dist) :-
        Q1 - Q2 =\\= Dist,
        Q2 - Q1 =\\= Dist,
        Dist1 is Dist + 1,
        safe_from_all(Q1, Rest, Dist1).

    % Main N-Queens solver
    n_queens(N, Solution) :-
        range(1, N, Positions),
        permutation(Positions, Solution),
        queens_safe(Solution).

    n_queens_solution(N, Solution) :- n_queens(N, Solution).
    """

    case MQI.consult_string(session, n_queens_code) do
      {:ok, _} -> IO.puts("✅ Loaded N-Queens solver")
      {:error, reason} -> IO.puts("❌ Failed to load N-Queens solver: #{reason}")
    end
  end

  defp load_sudoku_rules(session) do
    # Working Sudoku solver with a sample puzzle
    sudoku_code = """
    % Sample Sudoku puzzle (0 represents empty cells)
    sample_sudoku([
        [5,3,0,0,7,0,0,0,0],
        [6,0,0,1,9,5,0,0,0],
        [0,9,8,0,0,0,0,6,0],
        [8,0,0,0,6,0,0,0,3],
        [4,0,0,8,0,3,0,0,1],
        [7,0,0,0,2,0,0,0,6],
        [0,6,0,0,0,0,2,8,0],
        [0,0,0,4,1,9,0,0,5],
        [0,0,0,0,8,0,0,7,9]
    ]).

    % Simple Sudoku solver using backtracking
    sudoku_solve(Grid) :-
        sudoku_solve_cell(Grid, 0, 0).

    sudoku_solve_cell(Grid, 9, _) :- !.
    sudoku_solve_cell(Grid, Row, 9) :-
        NextRow is Row + 1,
        sudoku_solve_cell(Grid, NextRow, 0).
    sudoku_solve_cell(Grid, Row, Col) :-
        get_cell(Grid, Row, Col, Value),
        (Value > 0 ->
            NextCol is Col + 1,
            sudoku_solve_cell(Grid, Row, NextCol)
        ;
            between(1, 9, N),
            valid_move(Grid, Row, Col, N),
            set_cell(Grid, Row, Col, N, NewGrid),
            NextCol is Col + 1,
            sudoku_solve_cell(NewGrid, Row, NextCol)
        ).

    get_cell(Grid, Row, Col, Value) :-
        nth0(Row, Grid, RowList),
        nth0(Col, RowList, Value).

    set_cell(Grid, Row, Col, Value, NewGrid) :-
        nth0(Row, Grid, RowList),
        replace_nth(Col, RowList, Value, NewRowList),
        replace_nth(Row, Grid, NewRowList, NewGrid).

    replace_nth(0, [_|T], X, [X|T]).
    replace_nth(N, [H|T], X, [H|NewT]) :-
        N > 0,
        N1 is N - 1,
        replace_nth(N1, T, X, NewT).

    valid_move(Grid, Row, Col, N) :-
        valid_row(Grid, Row, N),
        valid_col(Grid, Col, N),
        valid_box(Grid, Row, Col, N).

    valid_row(Grid, Row, N) :-
        nth0(Row, Grid, RowList),
        \+ member(N, RowList).

    valid_col(Grid, Col, N) :-
        maplist(nth0(Col), Grid, ColList),
        \+ member(N, ColList).

    valid_box(Grid, Row, Col, N) :-
        BoxRow is (Row // 3) * 3,
        BoxCol is (Col // 3) * 3,
        get_box(Grid, BoxRow, BoxCol, Box),
        \+ member(N, Box).

    get_box(Grid, StartRow, StartCol, Box) :-
        findall(Value,
            (between(0, 2, R),
             between(0, 2, C),
             Row is StartRow + R,
             Col is StartCol + C,
             get_cell(Grid, Row, Col, Value)),
            Box).

    % Main interface
    sudoku_solution(Grid, Solution) :-
        sudoku_solve(Grid),
        Solution = Grid.

    % Get sample puzzle
    get_sample_sudoku(Puzzle) :-
        sample_sudoku(Puzzle).
    """

    case MQI.consult_string(session, sudoku_code) do
      {:ok, _} -> IO.puts("✅ Loaded Sudoku solver")
      {:error, reason} -> IO.puts("❌ Failed to load Sudoku solver: #{reason}")
    end
  end
end
