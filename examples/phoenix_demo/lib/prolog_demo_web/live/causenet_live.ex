defmodule PrologDemoWeb.CauseNetLive do
  use PrologDemoWeb, :live_view
  alias PrologDemo.CauseNetService

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <div class="container mx-auto px-4 py-8">
        <!-- Header -->
        <div class="text-center mb-12">
          <h1 class="text-4xl font-bold text-gray-900 mb-4">
            🧠 CauseNet + Prolog Demo
          </h1>
          <p class="text-xl text-gray-600 max-w-3xl mx-auto">
            Experience the power of logic programming with real-world causal relationships from CauseNet.
            See how Prolog's backtracking and constraint solving can solve complex problems in just a few lines.
          </p>
        </div>

        <!-- Navigation Tabs -->
        <div class="flex justify-center mb-8">
          <div class="bg-white rounded-lg shadow-md p-1">
            <nav class="flex space-x-1">
              <.link
                navigate={~p"/causenet/causal"}
                class={tab_class(@active_tab, "causal-reasoning")}
              >
                🔗 Causal Reasoning
              </.link>
              <.link
                navigate={~p"/causenet/constraints"}
                class={tab_class(@active_tab, "constraint-solving")}
              >
                🧩 Constraint Solving
              </.link>
              <.link
                navigate={~p"/causenet/sudoku"}
                class={tab_class(@active_tab, "sudoku-solver")}
              >
                🔢 Sudoku Solver
              </.link>
              <.link
                navigate={~p"/causenet/playground"}
                class={tab_class(@active_tab, "prolog-playground")}
              >
                🎯 Prolog Playground
              </.link>
            </nav>
          </div>
        </div>

        <!-- Tab Content -->
        <div class="max-w-7xl mx-auto">

          <!-- Facts Loading Progress -->
          <%= if @facts_loading do %>
            <div class="bg-white rounded-xl shadow-lg p-8 mb-8">
              <h2 class="text-2xl font-bold text-gray-900 mb-6 text-center">📊 Loading CauseNet Facts</h2>
              <div class="space-y-4">
                <div class="w-full bg-gray-200 rounded-full h-4">
                  <div
                    class="bg-blue-600 h-4 rounded-full transition-all duration-300 ease-out"
                    style={"width: #{@loading_progress}%"}
                  ></div>
                </div>
                <div class="text-center">
                  <p class="text-lg font-medium text-gray-700"><%= @loading_progress %>%</p>
                  <p class="text-sm text-gray-600"><%= @loading_message %></p>
                </div>
                <div class="text-center">
                  <.loading_spinner />
                </div>
              </div>
            </div>
          <% end %>

          <!-- Facts Not Loaded Warning -->
          <%= if not @facts_loaded and not @facts_loading do %>
            <div class="bg-yellow-50 border border-yellow-200 rounded-xl shadow-lg p-8 mb-8">
              <h2 class="text-2xl font-bold text-yellow-800 mb-4 text-center">⚠️ CauseNet Facts Not Loaded</h2>
              <p class="text-yellow-700 text-center mb-6">
                The CauseNet knowledge base needs to be loaded before you can explore causal relationships.
                This may take a few moments as we process thousands of real-world causal relationships.
              </p>
              <div class="text-center">
                <button
                  phx-click="load_facts"
                  class="bg-yellow-600 text-white py-3 px-8 rounded-lg font-medium hover:bg-yellow-700 focus:ring-2 focus:ring-yellow-500 focus:ring-offset-2 transition-colors duration-200"
                >
                  🚀 Load CauseNet Facts
                </button>
              </div>
            </div>
          <% end %>

          <!-- Causal Reasoning Tab -->
          <div class={tab_content_class(@active_tab, "causal-reasoning")}>
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
              <!-- Left: Query Interface -->
              <div class="bg-white rounded-xl shadow-lg p-8">
                <h2 class="text-2xl font-bold text-gray-900 mb-6">🔍 Explore Causal Relationships</h2>

                <div class="space-y-6">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">Start Concept</label>
                    <input
                      type="text"
                      value={@start_concept}
                      phx-blur="update_start_concept"
                      phx-value-value={@start_concept}
                      class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      placeholder="e.g., smoking, stress, obesity"
                    />
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">End Concept</label>
                    <input
                      type="text"
                      value={@end_concept}
                      phx-blur="update_end_concept"
                      phx-value-value={@end_concept}
                      class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      placeholder="e.g., death, illness, cancer"
                    />
                  </div>

                  <button
                    phx-click="find_causal_paths"
                    class="w-full bg-blue-600 text-white py-3 px-6 rounded-lg font-medium hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors duration-200"
                  >
                    🔍 Find Causal Paths
                  </button>
                </div>

                <div class="mt-8">
                  <h3 class="text-lg font-semibold text-gray-900 mb-4">Quick Examples</h3>
                  <div class="grid grid-cols-1 gap-3">
                    <button
                      phx-click="load_causal_example"
                      phx-value-start="smoking"
                      phx-value-end="death"
                      class="text-left p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors duration-200"
                    >
                      <div class="font-medium">🚬 Smoking → Death</div>
                      <div class="text-sm text-gray-600">Find all pathways from smoking to death</div>
                    </button>
                    <button
                      phx-click="load_causal_example"
                      phx-value-start="obesity"
                      phx-value-end="death"
                      class="text-left p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors duration-200"
                    >
                      <div class="font-medium">🍔 Obesity → Death</div>
                      <div class="text-sm text-gray-600">Explore obesity's health impact chain</div>
                    </button>
                  </div>
                </div>
              </div>

              <!-- Right: Results -->
              <div class="bg-white rounded-xl shadow-lg p-8">
                <h2 class="text-2xl font-bold text-gray-900 mb-6">📊 Causal Path Results</h2>
                <div class="space-y-4">
                  <%= if @causal_loading do %>
                    <div class="text-center py-8">
                      <.loading_spinner />
                      <p class="mt-2 text-blue-600 font-medium">🔄 Unification in progress. Backtracking. This may take some time...</p>
                    </div>
                  <% else %>
                    <%= if @causal_results do %>
                                                   <div class="mb-6">
                               <div class="text-lg font-semibold text-gray-900 mb-2">
                                 Causal Paths from "<%= @causal_results.start_concept %>" to "<%= @causal_results.end_concept %>"
                               </div>
                              <div class="text-sm text-gray-600">
                                Found <%= @causal_results.count %> pathway(s)
                              </div>
                             </div>

                      <%= if length(@causal_results.paths) > 0 do %>
                        <div class="space-y-4">
                          <%= for {path, index} <- Enum.with_index(@causal_results.paths) do %>
                            <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
                              <div class="font-medium text-blue-800 mb-2">Pathway <%= index + 1 %>:</div>
                              <div class="flex items-center space-x-2 text-sm">
                                <%= for {concept, i} <- Enum.with_index(path) do %>
                                  <span class="bg-white px-3 py-1 rounded-full border border-blue-200"><%= concept %></span>
                                  <%= if i < length(path) - 1 do %>
                                    <span class="text-blue-400">→</span>
                                  <% end %>
                                <% end %>
                              </div>
                            </div>
                          <% end %>
                        </div>
                      <% else %>
                        <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
                          <div class="text-yellow-800">No causal pathways found between these concepts.</div>
                        </div>
                      <% end %>
                    <% else %>
                      <div class="text-center text-gray-500 py-12">
                        <div class="text-6xl mb-4">🔍</div>
                        <p>Enter concepts above to explore causal relationships</p>
                      </div>
                    <% end %>
                  <% end %>
                </div>
              </div>
            </div>
          </div>

          <!-- Sudoku Solver Tab -->
          <div class={tab_content_class(@active_tab, "sudoku-solver")}>
            <div class="space-y-8">
              <!-- Sudoku Puzzle -->
              <div class="bg-white rounded-xl shadow-lg p-8">
                <h2 class="text-2xl font-bold text-gray-900 mb-6">🔢 Sudoku Solver</h2>
                <div class="space-y-6">
                  <div class="text-center">
                    <p class="text-lg text-gray-700 mb-2">
                      Classic Sudoku puzzle where empty cells need to be filled with digits 1-9
                    </p>
                    <p class="text-sm text-gray-600">
                      Each row, column, and 3×3 box must contain all digits from 1 to 9 exactly once.
                    </p>
                  </div>
                  
                  <div class="flex justify-center">
                    <button
                      phx-click="solve_sudoku"
                      class="bg-green-600 text-white py-3 px-8 rounded-lg font-medium hover:bg-green-700 focus:ring-2 focus:ring-green-500 focus:ring-offset-2 transition-colors duration-200"
                    >
                      🧩 Solve Sudoku
                    </button>
                  </div>
                  
                  <!-- Always show the puzzle grid -->
                  <div class="flex justify-center">
                    <div>
                      <div class="text-sm font-medium text-gray-700 mb-2 text-center">Puzzle</div>
                      <div style="display: inline-grid; grid-template-columns: repeat(9, 40px); gap: 0; border: 3px solid #1f2937;">
                        <% puzzle = if @sudoku_results, do: @sudoku_results[:puzzle], else: [
                          [5,3,0,0,7,0,0,0,0],
                          [6,0,0,1,9,5,0,0,0],
                          [0,9,8,0,0,0,0,6,0],
                          [8,0,0,0,6,0,0,0,3],
                          [4,0,0,8,0,3,0,0,1],
                          [7,0,0,0,2,0,0,0,6],
                          [0,6,0,0,0,0,2,8,0],
                          [0,0,0,4,1,9,0,0,5],
                          [0,0,0,0,8,0,0,7,9]
                        ] %>
                        <%= for {row, row_idx} <- Enum.with_index(puzzle) do %>
                          <%= for {cell, col_idx} <- Enum.with_index(row) do %>
                            <% border_right = if rem(col_idx + 1, 3) == 0 && col_idx < 8, do: "border-right: 2px solid #1f2937;", else: "border-right: 1px solid #d1d5db;" %>
                            <% border_bottom = if rem(row_idx + 1, 3) == 0 && row_idx < 8, do: "border-bottom: 2px solid #1f2937;", else: "border-bottom: 1px solid #d1d5db;" %>
                            <div style={"width: 40px; height: 40px; display: flex; align-items: center; justify-content: center; #{border_right} #{border_bottom} background-color: #{if cell == 0, do: "#f9fafb", else: "#e5e7eb"};"}>
                              <span style={"font-weight: #{if cell == 0, do: "normal", else: "bold"}; color: #{if cell == 0, do: "#9ca3af", else: "#111827"};"}>
                                <%= if cell == 0, do: "", else: cell %>
                              </span>
                            </div>
                          <% end %>
                        <% end %>
                      </div>
                    </div>
                  </div>
                  
                  <div>
                    <%= if @sudoku_loading do %>
                      <div class="text-center py-8">
                        <.loading_spinner />
                        <p class="mt-2">Solving Sudoku puzzle...</p>
                        <p class="text-sm text-gray-500 mt-2">This may take a moment as Prolog explores all possibilities</p>
                      </div>
                    <% else %>
                      <%= if @sudoku_results && @sudoku_results[:solution] do %>
                        <div class="mt-8">
                          <div class="text-center mb-4">
                            <div class="text-lg font-semibold text-gray-900">
                              ✅ Solution Found!
                            </div>
                            <div class="text-sm text-gray-600">Solved in <%= @sudoku_results[:time_ms] || "< 1" %>ms</div>
                          </div>

                          <!-- Solution Grid -->
                          <div class="flex justify-center">
                            <div>
                              <div class="text-sm font-medium text-gray-700 mb-2 text-center">Solution</div>
                              <div style="display: inline-grid; grid-template-columns: repeat(9, 40px); gap: 0; border: 3px solid #1f2937;">
                                <%= for {row, row_idx} <- Enum.with_index(@sudoku_results[:solution]) do %>
                                  <%= for {cell, col_idx} <- Enum.with_index(row) do %>
                                    <% original_cell = Enum.at(Enum.at(@sudoku_results[:puzzle] || List.duplicate(List.duplicate(0, 9), 9), row_idx), col_idx) %>
                                    <% border_right = if rem(col_idx + 1, 3) == 0 && col_idx < 8, do: "border-right: 2px solid #1f2937;", else: "border-right: 1px solid #d1d5db;" %>
                                    <% border_bottom = if rem(row_idx + 1, 3) == 0 && row_idx < 8, do: "border-bottom: 2px solid #1f2937;", else: "border-bottom: 1px solid #d1d5db;" %>
                                    <div style={"width: 40px; height: 40px; display: flex; align-items: center; justify-content: center; #{border_right} #{border_bottom} background-color: #{if original_cell != 0, do: "#e5e7eb", else: "#dcfce7"};"}>
                                      <span style={"font-weight: bold; color: #{if original_cell != 0, do: "#111827", else: "#166534"};"}>
                                        <%= cell %>
                                      </span>
                                    </div>
                                  <% end %>
                                <% end %>
                              </div>
                            </div>
                          </div>
                        </div>
                      <% end %>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Constraint Solving Tab -->
          <div class={tab_content_class(@active_tab, "constraint-solving")}>
            <div class="space-y-8">
              <!-- N-Queens Puzzle -->
              <div class="bg-white rounded-xl shadow-lg p-8">
                <h2 class="text-2xl font-bold text-gray-900 mb-6">👑 N-Queens Puzzle</h2>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                  <div>
                    <div class="mb-4">
                      <label class="block text-sm font-medium text-gray-700 mb-2">Number of Queens</label>
                      <input
                        type="number"
                        value={@queens_count}
                        phx-blur="update_queens_count"
                        phx-value-value={@queens_count}
                        min="4"
                        max="12"
                        class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      />
                    </div>
                    <button
                      phx-click="solve_n_queens"
                      class="w-full bg-purple-600 text-white py-3 px-6 rounded-lg font-medium hover:bg-purple-700 focus:ring-2 focus:ring-purple-500 focus:ring-offset-2 transition-colors duration-200"
                    >
                      🧩 Solve N-Queens
                    </button>
                  </div>
                  <div class="space-y-4">
                    <%= if @queens_loading do %>
                      <div class="text-center py-8">
                        <.loading_spinner />
                        <p class="mt-2">Solving N-Queens puzzle...</p>
                      </div>
                    <% else %>
                      <%= if @queens_results do %>
                        <div class="mb-4">
                          <div class="text-lg font-semibold text-gray-900 mb-2">
                            <%= @queens_results.n %>-Queens Solutions
                          </div>
                          <div class="text-sm text-gray-600">Found <%= @queens_results.count %> solution(s)</div>
                        </div>

                        <%= if length(@queens_results.solutions) > 0 do %>
                          <div class="space-y-4">
                            <% display_limit = Map.get(@queens_results, :display_limit, 10) %>
                            <% solutions_to_show = Enum.take(@queens_results.solutions, display_limit) %>

                            <%= for {solution, index} <- Enum.with_index(solutions_to_show) do %>
                              <div class="bg-purple-50 border border-purple-200 rounded-lg p-4">
                                <div class="font-medium text-purple-800 mb-3">Solution <%= index + 1 %>:</div>
                                <div class="inline-block">
                                  <div style={"display: grid; grid-template-columns: repeat(#{@queens_results.n}, 1fr); gap: 0; border: 2px solid #1f2937;"}>
                                    <%= for row <- 1..@queens_results.n do %>
                                      <%= for col <- 1..@queens_results.n do %>
                                        <% is_queen = Enum.at(solution, row - 1) == col %>
                                        <% is_dark = rem(row + col, 2) == 0 %>
                                        <div style={"width: 48px; height: 48px; display: flex; align-items: center; justify-content: center; font-size: 2rem; background-color: #{if is_dark, do: "#92400e", else: "#fef3c7"};"}>
                                          <%= if is_queen do %>
                                            <span style="color:rgb(31, 4, 51);">♛</span>
                                          <% end %>
                                        </div>
                                      <% end %>
                                    <% end %>
                                  </div>
                                </div>
                                <div class="text-xs text-gray-600 mt-2 font-mono">
                                  Position: <%= inspect(solution) %>
                                </div>
                              </div>
                            <% end %>

                            <%= if length(@queens_results.solutions) > display_limit do %>
                              <div class="text-sm text-gray-600 italic mt-4">
                                ... and <%= length(@queens_results.solutions) - display_limit %> more solutions
                              </div>
                            <% end %>
                          </div>
                        <% end %>
                      <% else %>
                        <div class="text-center text-gray-500 py-8">
                          <div class="text-4xl mb-2">👑</div>
                          <p>Click solve to see solutions</p>
                        </div>
                      <% end %>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Prolog Playground Tab -->
          <div class={tab_content_class(@active_tab, "prolog-playground")}>
            <div class="bg-white rounded-xl shadow-lg p-8">
              <h2 class="text-2xl font-bold text-gray-900 mb-6">🎯 Prolog Query Playground</h2>
              <p class="text-gray-600 mb-6">
                Use the full-featured Prolog playground with live query execution, examples, and syntax highlighting.
              </p>
              <div class="text-center">
                <a
                  href="/prolog"
                  class="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-colors duration-200"
                >
                  🚀 Open Prolog Playground
                </a>
              </div>

              <div class="mt-8 grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="bg-gray-50 rounded-lg p-4">
                  <h3 class="font-semibold text-gray-900 mb-2">✨ Features</h3>
                  <ul class="text-sm text-gray-600 space-y-1">
                    <li>• Live query execution</li>
                    <li>• Quick examples</li>
                    <li>• Setup code support</li>
                    <li>• Real-time results</li>
                  </ul>
                </div>
                <div class="bg-gray-50 rounded-lg p-4">
                  <h3 class="font-semibold text-gray-900 mb-2">🎯 Try These</h3>
                  <ul class="text-sm text-gray-600 space-y-1">
                    <li>• member(X, [1,2,3])</li>
                    <li>• factorial(5, Result)</li>
                    <li>• ancestor(john, X)</li>
                    <li>• append(X, Y, [1,2,3])</li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Prolog Code Examples -->
        <div class="mt-16 bg-white rounded-xl shadow-lg p-8">
          <h2 class="text-2xl font-bold text-gray-900 mb-6 text-center">📝 The Prolog Code Behind This Demo</h2>

          <div class="grid gap-8 md:grid-cols-2">
            <!-- Causal Reasoning Code -->
            <div class="bg-gray-50 rounded-lg p-4">
              <h3 class="font-bold text-lg mb-3 text-blue-800">🔗 Causal Path Finding</h3>
              <pre class="text-xs font-mono overflow-x-auto"><code class="language-prolog">% Base case: We've reached our destination
find_paths_helper(End, End, _, Visited, Visited).

% Recursive case: Find the next step in the path
find_paths_helper(Start, End, MaxDepth, Visited, Path) :-
    MaxDepth > 0,                    % Still have depth to explore
    causes(Start, Next),             % Find what Start causes
    \+ member(Next, Visited),        % Avoid cycles
    MaxDepth1 is MaxDepth - 1,       % Decrease depth
    find_paths_helper(Next, End, MaxDepth1, [Next|Visited], Path).

% Entry point: Initialize and reverse the path
find_paths(Start, End, MaxDepth, Path) :-
    find_paths_helper(Start, End, MaxDepth, [Start], RevPath),
    reverse(RevPath, Path).</code></pre>
            </div>

            <!-- N-Queens Code -->
            <div class="bg-gray-50 rounded-lg p-4">
              <h3 class="font-bold text-lg mb-3 text-purple-800">👑 N-Queens Solver</h3>
              <pre class="text-xs font-mono overflow-x-auto"><code class="language-prolog">% Main solver: Generate and test approach
n_queens(N, Solution) :-
    range(1, N, Positions),          % Generate positions 1..N
    permutation(Positions, Solution), % Try all permutations
    queens_safe(Solution).           % Test if queens are safe

% Check if all queens are safe from attacks
queens_safe([]).                    % Empty board is safe
queens_safe([Q1|Rest]) :-
    safe_from_all(Q1, Rest, 1),     % Q1 safe from others
    queens_safe(Rest).               % Rest must be safe too

% Check if Q1 is safe from all queens in list
safe_from_all(_, [], _).            % No more queens to check
safe_from_all(Q1, [Q2|Rest], Dist) :-
    Q1 - Q2 =\= Dist,               % Not on diagonal /
    Q2 - Q1 =\= Dist,               % Not on diagonal \
    Dist1 is Dist + 1,              % Next distance
    safe_from_all(Q1, Rest, Dist1). % Check remaining</code></pre>
            </div>

            <!-- Facts and Rules -->
            <div class="bg-gray-50 rounded-lg p-4">
              <h3 class="font-bold text-lg mb-3 text-green-800">📊 Knowledge Base</h3>
              <pre class="text-xs font-mono overflow-x-auto"><code class="language-prolog">% Facts: Direct causal relationships
causes(smoking, lung_cancer).
causes(smoking, heart_disease).
causes(obesity, diabetes).
causes(diabetes, heart_disease).

% Rules: Transitive causation
causal_chain(X, Y) :-
    causes(X, Y).                    % Direct cause
causal_chain(X, Z) :-
    causes(X, Y),                    % X causes Y
    causal_chain(Y, Z).              % Y causes Z

% Bidirectional queries work automatically!
% ?- causes(smoking, What).          % What does smoking cause?
% ?- causes(What, heart_disease).    % What causes heart disease?
% ?- causal_chain(smoking, death).   % Is there a path?</code></pre>
            </div>

            <!-- Sudoku Solver -->
            <div class="bg-gray-50 rounded-lg p-4">
              <h3 class="font-bold text-lg mb-3 text-orange-800">🔢 Sudoku Solver</h3>
              <pre class="text-xs font-mono overflow-x-auto"><code class="language-prolog">% Main solver using backtracking
sudoku_solve_cell(Grid, Row, Col) :-
    get_cell(Grid, Row, Col, Value),
    (Value > 0 ->                    % Cell already filled?
        NextCol is Col + 1,          % Move to next cell
        sudoku_solve_cell(Grid, Row, NextCol)
    ;
        between(1, 9, N),            % Try values 1-9
        valid_move(Grid, Row, Col, N), % Check if valid
        set_cell(Grid, Row, Col, N, NewGrid),
        NextCol is Col + 1,
        sudoku_solve_cell(NewGrid, Row, NextCol)
    ).

% Validation: Check row, column, and 3x3 box
valid_move(Grid, Row, Col, N) :-
    valid_row(Grid, Row, N),         % N not in row
    valid_col(Grid, Col, N),         % N not in column
    valid_box(Grid, Row, Col, N).    % N not in 3x3 box</code></pre>
            </div>
          </div>

          <div class="mt-6 text-center text-gray-600">
            <p class="text-sm">
              <strong>Key Prolog Features:</strong> Pattern matching • Unification • Backtracking • Declarative style • Built-in search
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    # Determine which demo we're showing based on the route
    demo_type = case socket.assigns.live_action do
      :causal -> "causal"
      :constraints -> "constraints"
      :sudoku -> "sudoku"
      :playground -> "playground"
      _ -> "causal" # default
    end

    # Check if facts are already loaded for this demo type
    facts_loaded = case demo_type do
      "causal" -> PrologDemo.CausalSessionManager.facts_loaded?()
      "constraints" -> PrologDemo.ConstraintSessionManager.facts_loaded?()
      "sudoku" -> PrologDemo.ConstraintSessionManager.facts_loaded?()  # Sudoku uses the same constraint solver
      "playground" -> PrologDemo.PlaygroundSessionManager.facts_loaded?()
    end

    {:ok,
     socket
     |> assign(:demo_type, demo_type)
     |> assign(:active_tab, get_tab_for_demo(demo_type))
     |> assign(:start_concept, "")
     |> assign(:end_concept, "")
     |> assign(:causal_results, nil)
     |> assign(:causal_loading, false)
     |> assign(:sudoku_results, nil)
     |> assign(:sudoku_loading, false)
     |> assign(:queens_count, 8)
     |> assign(:queens_results, nil)
     |> assign(:queens_loading, false)
     |> assign(:playground_setup, "")
     |> assign(:playground_query, "")
     |> assign(:playground_results, nil)
     |> assign(:playground_loading, false)
     |> assign(:available_concepts, CauseNetService.get_common_concepts())
     |> assign(:facts_loading, false)
     |> assign(:facts_loaded, facts_loaded)
     |> assign(:loading_progress, 0)
     |> assign(:loading_message, "")
     |> assign(:search_depth, 3)
     |> maybe_load_facts()}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def handle_event("load_facts", _params, socket) do
    if not socket.assigns.facts_loaded do
      send(self(), :load_facts)
      {:noreply, assign(socket, :facts_loading, true)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_start_concept", %{"value" => value}, socket) do
    {:noreply, assign(socket, :start_concept, value)}
  end

  @impl true
  def handle_event("update_end_concept", %{"value" => value}, socket) do
    {:noreply, assign(socket, :end_concept, value)}
  end

  @impl true
  def handle_event("update_search_depth", %{"value" => value}, socket) do
    depth = String.to_integer(value)
    {:noreply, assign(socket, :search_depth, depth)}
  end

  @impl true
  def handle_event("find_causal_paths", _params, socket) do
    if socket.assigns.start_concept != "" and socket.assigns.end_concept != "" do
      send(self(), {:find_causal_paths, socket.assigns.start_concept, socket.assigns.end_concept, socket.assigns.search_depth})
      {:noreply, assign(socket, :causal_loading, true)}
    else
      {:noreply, put_flash(socket, :error, "Please enter both start and end concepts")}
    end
  end

  @impl true
  def handle_event("load_causal_example", %{"start" => start, "end" => end_concept}, socket) do
    send(self(), {:find_causal_paths, start, end_concept})
    {:noreply,
     socket
     |> assign(:start_concept, start)
     |> assign(:end_concept, end_concept)
     |> assign(:causal_loading, true)}
  end

  @impl true
  def handle_event("solve_sudoku", _params, socket) do
    send(self(), {:solve_sudoku})
    {:noreply, assign(socket, :sudoku_loading, true)}
  end

  @impl true
  def handle_event("update_queens_count", %{"value" => value}, socket) do
    {:noreply, assign(socket, :queens_count, String.to_integer(value))}
  end

  @impl true
  def handle_event("solve_n_queens", _params, socket) do
    n = socket.assigns.queens_count
    if n >= 4 and n <= 12 do
      send(self(), {:solve_n_queens, n})
      {:noreply, assign(socket, :queens_loading, true)}
    else
      {:noreply, put_flash(socket, :error, "Please enter a number between 4 and 12")}
    end
  end

  @impl true
  def handle_event("update_playground_setup", %{"value" => value}, socket) do
    {:noreply, assign(socket, :playground_setup, value)}
  end

  @impl true
  def handle_event("update_playground_query", %{"value" => value}, socket) do
    {:noreply, assign(socket, :playground_query, value)}
  end

  @impl true
  def handle_event("execute_prolog_query", _params, socket) do
    if socket.assigns.playground_query != "" do
      send(self(), {:execute_prolog_query, socket.assigns.playground_query, socket.assigns.playground_setup})
      {:noreply, assign(socket, :playground_loading, true)}
    else
      {:noreply, put_flash(socket, :error, "Please enter a Prolog query")}
    end
  end

  @impl true
  def handle_info({:find_causal_paths, start, end_concept, depth}, socket) do
    case PrologDemo.CausalSessionManager.query_advanced_causal_paths(start, end_concept, depth) do
      {:ok, paths} ->
        {:noreply,
         socket
         |> assign(:causal_results, %{start_concept: start, end_concept: end_concept, paths: paths, count: length(paths), depth: depth})
         |> assign(:causal_loading, false)}
      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:causal_loading, false)
         |> put_flash(:error, "Error finding causal paths: #{reason}")}
    end
  end

  @impl true
  def handle_info({:find_causal_paths, start, end_concept}, socket) do
    # Fallback for old format (without depth)
    handle_info({:find_causal_paths, start, end_concept, 3}, socket)
  end

  @impl true
  def handle_info({:solve_sudoku}, socket) do
    case PrologDemo.ConstraintSessionManager.query_constraint_solver("sudoku", %{}) do
      {:ok, solutions} ->
        {:noreply,
         socket
         |> assign(:sudoku_results, solutions)
         |> assign(:sudoku_loading, false)}
      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:sudoku_loading, false)
         |> put_flash(:error, "Error solving Sudoku: #{reason}")}
    end
  end

  @impl true
  def handle_info({:solve_n_queens, n}, socket) do
    case PrologDemo.ConstraintSessionManager.query_constraint_solver("n_queens", %{"n" => n}) do
      {:ok, solutions} ->
        {:noreply,
         socket
         |> assign(:queens_results, solutions)
         |> assign(:queens_loading, false)}
      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:queens_loading, false)
         |> put_flash(:error, "Error solving N-Queens: #{reason}")}
    end
  end

  @impl true
  def handle_info({:execute_prolog_query, query, setup}, socket) do
    case PrologDemo.PlaygroundSessionManager.execute_query(query, setup) do
      {:ok, results} ->
        {:noreply,
         socket
         |> assign(:playground_results, %{query: query, results: results})
         |> assign(:playground_loading, false)}
      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:playground_loading, false)
         |> put_flash(:error, "Error executing Prolog query: #{reason}")}
    end
  end

  @impl true
  def handle_info(:load_facts, socket) do
    # Start loading facts with progress updates for the appropriate demo type
    session_manager = case socket.assigns.demo_type do
      "causal" -> PrologDemo.CausalSessionManager
      "constraints" -> PrologDemo.ConstraintSessionManager
      "playground" -> PrologDemo.PlaygroundSessionManager
    end

    Task.start(fn ->
      session_manager.load_facts_with_progress(self())
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:facts_loading_progress, progress, message}, socket) do
    {:noreply,
     socket
     |> assign(:loading_progress, progress)
     |> assign(:loading_message, message)}
  end

  @impl true
  def handle_info({:facts_loaded, success}, socket) do
    {:noreply,
     socket
     |> assign(:facts_loading, false)
     |> assign(:facts_loaded, success)
     |> assign(:loading_progress, 100)
     |> assign(:loading_message, if(success, do: "Facts loaded successfully!", else: "Failed to load facts"))
     |> put_flash(if(success, do: :info, else: :error),
                  if(success, do: "CauseNet facts loaded successfully!", else: "Failed to load CauseNet facts"))}
  end

  # Helper functions
  defp tab_class(active_tab, tab_name) do
    if active_tab == tab_name do
      "px-6 py-3 rounded-md text-sm font-medium bg-blue-100 text-blue-700"
    else
      "px-6 py-3 rounded-md text-sm font-medium text-gray-600 hover:text-gray-900"
    end
  end

  defp tab_content_class(active_tab, tab_name) do
    if active_tab == tab_name do
      ""
    else
      "hidden"
    end
  end

  def loading_spinner(assigns) do
    ~H"""
    <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
    """
  end

  defp get_tab_for_demo(demo_type) do
    case demo_type do
      "causal" -> "causal-reasoning"
      "constraints" -> "constraint-solving"
      "sudoku" -> "sudoku-solver"
      "playground" -> "prolog-playground"
      _ -> "causal-reasoning"
    end
  end

  defp maybe_load_facts(socket) do
    if not socket.assigns.facts_loaded do
      send(self(), :load_facts)
      assign(socket, :facts_loading, true)
    else
      socket
    end
  end

end
