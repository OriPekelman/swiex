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
                navigate={~p"/causenet/bidirectional"}
                class={tab_class(@active_tab, "bidirectional-demo")}
              >
                🔄 Bi-directional Demo
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
              <.link
                navigate={~p"/causenet/adapters"}
                class={tab_class(@active_tab, "adapter-comparison")}
              >
                ⚖️ Adapter Comparison
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
                <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
                  <button
                    phx-click="load_facts"
                    phx-value-size="small"
                    class="bg-green-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-green-700 focus:ring-2 focus:ring-green-500 focus:ring-offset-2 transition-colors duration-200"
                  >
                    🌱 Small<br/><span class="text-xs">(100 facts)</span>
                  </button>
                  <button
                    phx-click="load_facts"
                    phx-value-size="medium"
                    class="bg-blue-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors duration-200"
                  >
                    🌳 Medium<br/><span class="text-xs">(500 facts)</span>
                  </button>
                  <button
                    phx-click="load_facts"
                    phx-value-size="large"
                    class="bg-orange-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-orange-700 focus:ring-2 focus:ring-orange-500 focus:ring-offset-2 transition-colors duration-200"
                  >
                    🏔️ Large<br/><span class="text-xs">(2K facts)</span>
                  </button>
                  <button
                    phx-click="load_facts"
                    phx-value-size="full"
                    class="bg-red-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-red-700 focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-colors duration-200"
                  >
                    🌍 Full<br/><span class="text-xs">(All facts)</span>
                  </button>
                </div>
                <p class="text-sm text-yellow-600">
                  Choose dataset size based on your needs. Start with Small for quick testing.
                </p>
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
                      🔄 Generate New Puzzle
                    </button>
                  </div>

                  <!-- Show puzzle and solution side-by-side -->
                  <div class="flex justify-center space-x-8">
                    <!-- Puzzle Grid -->
                    <div>
                      <div class="text-sm font-medium text-gray-700 mb-2 text-center">Puzzle</div>
                      <% puzzle = if @sudoku_results, do: @sudoku_results[:puzzle], else: [
                        [0,0,0,0,0,0,0,0,0],
                        [0,0,0,0,0,0,0,0,0], 
                        [0,0,0,0,0,0,0,0,0],
                        [0,0,0,0,0,0,0,0,0],
                        [0,0,0,0,0,0,0,0,0],
                        [0,0,0,0,0,0,0,0,0],
                        [0,0,0,0,0,0,0,0,0],
                        [0,0,0,0,0,0,0,0,0],
                        [0,0,0,0,0,0,0,0,0]
                      ] %>
                      <% puzzle_size = length(puzzle) %>
                      <% puzzle_box_size = if puzzle_size == 4, do: 2, else: 3 %>
                      <div style={"display: inline-grid; grid-template-columns: repeat(#{puzzle_size}, 40px); gap: 0; border: 3px solid #1f2937;"}>
                        <%= for {row, row_idx} <- Enum.with_index(puzzle) do %>
                          <%= for {cell, col_idx} <- Enum.with_index(row) do %>
                            <% border_right = if rem(col_idx + 1, puzzle_box_size) == 0 && col_idx < puzzle_size - 1, do: "border-right: 2px solid #1f2937;", else: "border-right: 1px solid #d1d5db;" %>
                            <% border_bottom = if rem(row_idx + 1, puzzle_box_size) == 0 && row_idx < puzzle_size - 1, do: "border-bottom: 2px solid #1f2937;", else: "border-bottom: 1px solid #d1d5db;" %>
                            <div style={"width: 40px; height: 40px; display: flex; align-items: center; justify-content: center; #{border_right} #{border_bottom} background-color: #{if cell == 0, do: "#f9fafb", else: "#e5e7eb"};"}>
                              <span style={"font-weight: #{if cell == 0, do: "normal", else: "bold"}; color: #{if cell == 0, do: "#9ca3af", else: "#111827"};"}>
                                <%= if cell == 0, do: "", else: cell %>
                              </span>
                            </div>
                          <% end %>
                        <% end %>
                      </div>
                    </div>

                    <!-- Solution Grid (if available) -->
                    <%= if @sudoku_results && @sudoku_results[:solution] do %>
                      <div>
                        <div class="text-sm font-medium text-gray-700 mb-2 text-center">Solution</div>
                        <% grid_size = length(@sudoku_results[:solution]) %>
                        <% box_size = if grid_size == 4, do: 2, else: 3 %>
                        <div style={"display: inline-grid; grid-template-columns: repeat(#{grid_size}, 40px); gap: 0; border: 3px solid #1f2937;"}>
                          <%= for {row, row_idx} <- Enum.with_index(@sudoku_results[:solution]) do %>
                            <%= for {cell, col_idx} <- Enum.with_index(row) do %>
                              <% original_cell = Enum.at(Enum.at(@sudoku_results[:puzzle] || List.duplicate(List.duplicate(0, grid_size), grid_size), row_idx), col_idx) %>
                              <% border_right = if rem(col_idx + 1, box_size) == 0 && col_idx < grid_size - 1, do: "border-right: 2px solid #1f2937;", else: "border-right: 1px solid #d1d5db;" %>
                              <% border_bottom = if rem(row_idx + 1, box_size) == 0 && row_idx < grid_size - 1, do: "border-bottom: 2px solid #1f2937;", else: "border-bottom: 1px solid #d1d5db;" %>
                              <div style={"width: 40px; height: 40px; display: flex; align-items: center; justify-content: center; #{border_right} #{border_bottom} background-color: #{if original_cell != 0, do: "#e5e7eb", else: "#dcfce7"};"}>
                                <span style={"font-weight: bold; color: #{if original_cell != 0, do: "#111827", else: "#166534"};"}>
                                  <%= cell %>
                                </span>
                              </div>
                            <% end %>
                          <% end %>
                        </div>
                      </div>
                    <% end %>
                  </div>

                  <div>
                    <%= if @sudoku_loading do %>
                      <div class="text-center py-8">
                        <.loading_spinner />
                        <p class="mt-2">Solving Sudoku puzzle with Prolog CLP(FD)...</p>
                        <p class="text-sm text-gray-500 mt-2">Constraint Logic Programming in action</p>
                      </div>
                    <% else %>
                      <%= if @sudoku_results && @sudoku_results[:solution] do %>
                        <div class="mt-8">
                          <div class="text-center mb-4">
                            <div class="text-lg font-semibold text-gray-900">
                              🎯 Prolog CLP(FD) Solution Found!
                            </div>
                            <div class="text-sm text-gray-600">Solved in <%= @sudoku_results[:time_ms] || "< 1" %>ms</div>
                            
                            <!-- Validation Results -->
                            <div class="mt-4 p-4 bg-green-50 border border-green-200 rounded-lg">
                              <div class="text-sm font-medium text-green-800 mb-2">
                                🎯 <strong>Prolog CLP(FD) Solver:</strong> Constraint Logic Programming with Finite Domains
                              </div>
                              
                              <%= if @sudoku_results[:elixir_validation] do %>
                                <div class="text-xs text-green-700 mb-1">
                                  ✅ <strong>Row validation:</strong> All rows contain unique digits 1-9
                                </div>
                                <div class="text-xs text-green-700 mb-1">
                                  ✅ <strong>Column validation:</strong> All columns contain unique digits 1-9  
                                </div>
                                <div class="text-xs text-green-700 mb-1">
                                  ✅ <strong>Box validation:</strong> All 3×3 boxes contain unique digits 1-9
                                </div>
                                <div class="text-xs text-green-700">
                                  ✅ <strong>Mathematical verification:</strong> Solution is completely valid
                                </div>
                              <% else %>
                                <div class="text-xs text-red-700">
                                  ❌ <strong>Validation failed:</strong> Solution contains errors
                                </div>
                              <% end %>
                            </div>

                            <%= if @sudoku_results[:integration_demo] do %>
                              <div class="mt-2 p-3 bg-blue-50 border border-blue-200 rounded-lg">
                                <div class="text-xs text-blue-800 font-medium mb-1">
                                  🚀 <strong>Elixir ⟷ Prolog Integration Demo:</strong>
                                </div>
                                <div class="text-xs text-blue-700">
                                  📝 Elixir generates random 9×9 puzzle → Prolog CLP(FD) solver finds unique solution → Elixir validates result
                                </div>
                              </div>
                            <% end %>
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
                          <%= if @queens_results[:solver_type] == "clp_fd" do %>
                            <div class="mt-2 p-2 bg-purple-50 border border-purple-200 rounded-lg">
                              <div class="text-xs text-purple-800 font-medium">
                                🎯 <strong>CLP(FD) Solver:</strong> Constraint Logic Programming with Finite Domains
                              </div>
                              <div class="text-xs text-purple-700 mt-1">
                                ⚡ Efficient constraint propagation eliminates invalid placements early
                              </div>
                              <%= if @queens_results[:note] do %>
                                <div class="text-xs text-purple-700 mt-1">
                                  📝 <%= @queens_results[:note] %>
                                </div>
                              <% end %>
                            </div>
                          <% end %>
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

          <!-- Adapter Comparison Tab -->
          <div class={tab_content_class(@active_tab, "adapter-comparison")}>
            <div class="space-y-8">
              <!-- Header -->
              <div class="bg-white rounded-xl shadow-lg p-8">
                <h2 class="text-2xl font-bold text-gray-900 mb-6">⚖️ Prolog Adapter Comparison</h2>
                <p class="text-lg text-gray-700 mb-4">
                  <strong>Multiple Prolog Engines:</strong> Compare SWI-Prolog, Erlog, and Scryer Prolog performance and capabilities side by side!
                </p>
                <p class="text-gray-600">
                  This demo shows how Swiex can work with different Prolog implementations through a unified adapter interface.
                  Run the same queries against multiple engines to see differences in performance, syntax support, and results.
                </p>
              </div>

              <!-- Adapter Status Cards -->
              <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
                <%= for adapter_info <- @adapter_list do %>
                  <div class="bg-white rounded-xl shadow-lg p-6">
                    <div class="flex items-center justify-between mb-4">
                      <div class="flex items-center space-x-3">
                        <div class={adapter_status_icon_class(adapter_info.health)}>
                          <%= if adapter_info.health == :ok do %>
                            ✅
                          <% else %>
                            ❌
                          <% end %>
                        </div>
                        <div>
                          <h3 class="text-xl font-bold text-gray-900"><%= adapter_info.info.name %></h3>
                          <p class="text-sm text-gray-500 capitalize"><%= adapter_info.info.type %> Implementation</p>
                        </div>
                      </div>
                      <span class={adapter_health_badge_class(adapter_info.health)}>
                        <%= if adapter_info.health == :ok, do: "Available", else: "Unavailable" %>
                      </span>
                    </div>
                    
                    <div class="space-y-3">
                      <div>
                        <p class="text-sm font-medium text-gray-700 mb-1">Features:</p>
                        <div class="flex flex-wrap gap-1">
                          <%= for feature <- adapter_info.info.features do %>
                            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                              <%= format_feature_name(feature) %>
                            </span>
                          <% end %>
                        </div>
                      </div>
                      
                      <div>
                        <p class="text-sm font-medium text-gray-700">Version: <span class="font-normal"><%= adapter_info.info.version %></span></p>
                      </div>
                      
                      <%= if adapter_info.health == :ok do %>
                        <div class="pt-2">
                          <button 
                            phx-click="test_adapter"
                            phx-value-adapter={adapter_info.adapter}
                            class="w-full bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors duration-200"
                          >
                            🧪 Test This Adapter
                          </button>
                        </div>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>

              <!-- Query Comparison Section -->
              <div class="bg-white rounded-xl shadow-lg p-8">
                <h3 class="text-xl font-bold text-gray-900 mb-6">🔬 Side-by-Side Query Comparison</h3>
                
                <div class="mb-6">
                  <label class="block text-sm font-medium text-gray-700 mb-2">
                    Enter a Prolog query to test across all available adapters:
                  </label>
                  <div class="flex space-x-3">
                    <input
                      type="text"
                      value={@comparison_query}
                      phx-keyup="update_comparison_query"
                      placeholder="true"
                      class="flex-1 border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    />
                    <button
                      phx-click="run_comparison"
                      class="bg-green-600 text-white px-6 py-2 rounded-lg hover:bg-green-700 focus:ring-2 focus:ring-green-500 focus:ring-offset-2 transition-colors duration-200"
                    >
                      🚀 Run Comparison
                    </button>
                  </div>
                </div>

                <%= if @comparison_results && map_size(@comparison_results) > 0 do %>
                  <div class="space-y-6">
                    <h4 class="text-lg font-semibold text-gray-900">Results for: <code class="bg-gray-100 px-2 py-1 rounded text-sm"><%= @comparison_query %></code></h4>
                    
                    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                      <%= for {adapter_name, result} <- @comparison_results do %>
                        <div class="border border-gray-200 rounded-lg p-4">
                          <div class="flex items-center justify-between mb-3">
                            <h5 class="font-medium text-gray-900"><%= get_adapter_name(adapter_name) %></h5>
                            <span class={result_status_badge_class(result)}>
                              <%= get_result_status_text(result) %>
                            </span>
                          </div>
                          
                          <div class="bg-gray-50 rounded p-3">
                            <%= case result do %>
                              <% {:ok, results} -> %>
                                <div class="space-y-2">
                                  <p class="text-xs text-gray-600 font-medium">✅ Success - <%= length(results) %> result(s):</p>
                                  <%= if results == [] do %>
                                    <p class="text-sm text-gray-600 italic">No results (query failed/false)</p>
                                  <% else %>
                                    <pre class="text-xs text-gray-800 whitespace-pre-wrap"><%= inspect(results, pretty: true, width: 40) %></pre>
                                  <% end %>
                                </div>
                              <% {:error, reason} -> %>
                                <div class="space-y-2">
                                  <p class="text-xs text-red-600 font-medium">❌ Error:</p>
                                  <pre class="text-xs text-red-700 whitespace-pre-wrap"><%= inspect(reason, pretty: true, width: 40) %></pre>
                                </div>
                            <% end %>
                          </div>
                        </div>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>

              <!-- Example Queries -->
              <div class="bg-white rounded-xl shadow-lg p-8">
                <h3 class="text-xl font-bold text-gray-900 mb-6">💡 Example Queries to Try</h3>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <h4 class="font-semibold text-gray-900 mb-3">Basic Logic</h4>
                    <div class="space-y-2">
                      <%= for query <- ["true", "fail", "1 + 1 =:= 2"] do %>
                        <button
                          phx-click="set_comparison_query"
                          phx-value-query={query}
                          class="block w-full text-left px-3 py-2 bg-gray-50 hover:bg-gray-100 rounded text-sm font-mono"
                        >
                          <%= query %>
                        </button>
                      <% end %>
                    </div>
                  </div>
                  
                  <div>
                    <h4 class="font-semibold text-gray-900 mb-3">Simple Facts</h4>
                    <div class="space-y-2">
                      <%= for query <- ["atom(hello)", "number(42)", "is_list([1,2,3])"] do %>
                        <button
                          phx-click="set_comparison_query"
                          phx-value-query={query}
                          class="block w-full text-left px-3 py-2 bg-gray-50 hover:bg-gray-100 rounded text-sm font-mono"
                        >
                          <%= query %>
                        </button>
                      <% end %>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Bi-directional Demo Tab -->
          <div class={tab_content_class(@active_tab, "bidirectional-demo")}>
            <div class="space-y-8">
              <!-- Header -->
              <div class="bg-white rounded-xl shadow-lg p-8">
                <h2 class="text-2xl font-bold text-gray-900 mb-6">🔄 Bi-directional Programming with Prolog</h2>
                <p class="text-lg text-gray-700 mb-4">
                  <strong>The Magic of Prolog:</strong> One rule definition works in ALL directions!
                </p>
                <p class="text-gray-600">
                  Unlike functions in traditional programming languages that only work in one direction (input → output), 
                  Prolog relations work bidirectionally. The same rule can answer completely different types of questions.
                </p>
              </div>

              <!-- Interactive Demo -->
              <div class="bg-white rounded-xl shadow-lg p-8">
                <h3 class="text-xl font-bold text-gray-900 mb-6">🧪 Interactive Demo: CauseNet Causal Relations</h3>
                
                <!-- Rule Definition -->
                <div class="mb-8">
                  <h4 class="font-semibold text-gray-900 mb-3">📝 Live Knowledge Base Rules:</h4>
                  <div class="bg-gray-900 text-green-400 p-4 rounded-lg font-mono text-sm">
                    <div class="mb-2 text-gray-400">% <%= @fact_count %> real causal relationships from scientific literature</div>
                    <div>causes(smoking, lung_cancer).</div>
                    <div>causes(obesity, diabetes).</div>
                    <div>causes(stress, heart_disease).</div>
                    <div class="mb-2 text-gray-400">% ... and <%= @fact_count - 3 %> more facts</div>
                    <div class="mt-3 text-yellow-400">% ONE rule for causal chains - works in ALL directions</div>
                    <div class="text-white font-bold">causal_chain(X, Y) :- causes(X, Y).</div>
                    <div class="text-white font-bold">causal_chain(X, Z) :- causes(X, Y), causal_chain(Y, Z).</div>
                  </div>
                </div>

                <!-- Different Query Directions -->
                <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
                  <!-- Forward Direction -->
                  <div class="border-2 border-blue-200 rounded-lg p-6 bg-blue-50">
                    <h4 class="font-bold text-blue-800 mb-4">➡️ Forward: What does X cause?</h4>
                    <div class="mb-4">
                      <input
                        type="text"
                        value={@bidirectional_input1 || "smoking"}
                        phx-blur="update_bidirectional_input1"
                        phx-value-value={@bidirectional_input1}
                        class="w-full px-3 py-2 border border-blue-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                        placeholder="Enter cause (e.g., smoking, obesity)"
                      />
                    </div>
                    <button
                      phx-click="query_causes_what"
                      class="w-full bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 transition-colors"
                    >
                      Find Effects
                    </button>
                    <div class="mt-4 p-3 bg-white rounded border">
                      <div class="font-mono text-sm text-gray-700">?- causes(<%= @bidirectional_input1 || "smoking" %>, What).</div>
                      <%= if @bidirectional_results1 do %>
                        <div class="mt-2 text-green-700 font-medium max-h-32 overflow-y-auto">
                          <%= if length(@bidirectional_results1) > 0 do %>
                            <div class="text-xs mb-1"><%= length(@bidirectional_results1) %> effects found:</div>
                            <%= for effect <- Enum.take(@bidirectional_results1, 10) do %>
                              <div class="text-xs">• <%= effect %></div>
                            <% end %>
                            <%= if length(@bidirectional_results1) > 10 do %>
                              <div class="text-xs text-gray-500">... and <%= length(@bidirectional_results1) - 10 %> more</div>
                            <% end %>
                          <% else %>
                            No effects found
                          <% end %>
                        </div>
                      <% end %>
                    </div>
                  </div>

                  <!-- Backward Direction -->
                  <div class="border-2 border-purple-200 rounded-lg p-6 bg-purple-50">
                    <h4 class="font-bold text-purple-800 mb-4">⬅️ Backward: What causes X?</h4>
                    <div class="mb-4">
                      <input
                        type="text"
                        value={@bidirectional_input2 || "heart disease"}
                        phx-blur="update_bidirectional_input2"
                        phx-value-value={@bidirectional_input2}
                        class="w-full px-3 py-2 border border-purple-300 rounded-lg focus:ring-2 focus:ring-purple-500"
                        placeholder="Enter effect (e.g., heart disease, cancer)"
                      />
                    </div>
                    <button
                      phx-click="query_what_causes"
                      class="w-full bg-purple-600 text-white py-2 px-4 rounded-lg hover:bg-purple-700 transition-colors"
                    >
                      Find Causes
                    </button>
                    <div class="mt-4 p-3 bg-white rounded border">
                      <div class="font-mono text-sm text-gray-700">?- causes(What, '<%= @bidirectional_input2 || "heart disease" %>').</div>
                      <%= if @bidirectional_results2 do %>
                        <div class="mt-2 text-green-700 font-medium max-h-32 overflow-y-auto">
                          <%= if length(@bidirectional_results2) > 0 do %>
                            <div class="text-xs mb-1"><%= length(@bidirectional_results2) %> causes found:</div>
                            <%= for cause <- Enum.take(@bidirectional_results2, 10) do %>
                              <div class="text-xs">• <%= cause %></div>
                            <% end %>
                            <%= if length(@bidirectional_results2) > 10 do %>
                              <div class="text-xs text-gray-500">... and <%= length(@bidirectional_results2) - 10 %> more</div>
                            <% end %>
                          <% else %>
                            No causes found
                          <% end %>
                        </div>
                      <% end %>
                    </div>
                  </div>

                  <!-- Causal Chain Direction -->
                  <div class="border-2 border-green-200 rounded-lg p-6 bg-green-50">
                    <h4 class="font-bold text-green-800 mb-4">🔗 Chain: X → ? → Y</h4>
                    <div class="mb-2">
                      <input
                        type="text"
                        value={@bidirectional_input3a || "smoking"}
                        phx-blur="update_bidirectional_input3a"
                        phx-value-value={@bidirectional_input3a}
                        class="w-full px-3 py-2 border border-green-300 rounded-lg focus:ring-2 focus:ring-green-500 mb-2"
                        placeholder="Starting cause"
                      />
                      <input
                        type="text"
                        value={@bidirectional_input3b || "death"}
                        phx-blur="update_bidirectional_input3b"
                        phx-value-value={@bidirectional_input3b}
                        class="w-full px-3 py-2 border border-green-300 rounded-lg focus:ring-2 focus:ring-green-500"
                        placeholder="Final effect"
                      />
                    </div>
                    <button
                      phx-click="query_causal_chain"
                      class="w-full bg-green-600 text-white py-2 px-4 rounded-lg hover:bg-green-700 transition-colors"
                    >
                      Find Causal Chain
                    </button>
                    <div class="mt-4 p-3 bg-white rounded border">
                      <div class="font-mono text-sm text-gray-700">?- causal_chain(<%= @bidirectional_input3a || "smoking" %>, '<%= @bidirectional_input3b || "death" %>').</div>
                      <%= if @bidirectional_results3 != nil do %>
                        <div class={"mt-2 font-medium #{if @bidirectional_results3, do: "text-green-700", else: "text-red-700"}"}>
                          <%= if @bidirectional_results3 do %>
                            ✅ Causal chain EXISTS!
                            <div class="text-xs mt-1">Try the Causal Reasoning tab for detailed pathways</div>
                          <% else %>
                            ❌ No causal chain found
                          <% end %>
                        </div>
                      <% end %>
                    </div>
                  </div>
                </div>

                <!-- Loading State -->
                <%= if @bidirectional_loading do %>
                  <div class="mt-6 text-center">
                    <.loading_spinner />
                    <p class="mt-2 text-gray-600">Querying Prolog knowledge base...</p>
                  </div>
                <% end %>

                <!-- Explanation -->
                <div class="mt-8 bg-yellow-50 border border-yellow-200 rounded-lg p-6">
                  <h4 class="font-bold text-yellow-800 mb-3">💡 Why This Matters for Real-World Data</h4>
                  <div class="text-yellow-800 space-y-2">
                    <p><strong>Same Causal Rules, Multiple Research Questions:</strong> Our CauseNet rules can answer:</p>
                    <ul class="list-disc list-inside ml-4 space-y-1">
                      <li><strong>Risk Factors:</strong> "What does smoking cause?" → lung cancer, heart disease, COPD...</li>
                      <li><strong>Root Causes:</strong> "What causes heart disease?" → smoking, obesity, stress, genetics...</li>
                      <li><strong>Causal Pathways:</strong> "Does smoking lead to death?" → Yes, through multiple pathways</li>
                      <li><strong>Population Health:</strong> Generate ALL risk factor combinations automatically</li>
                    </ul>
                    <p class="mt-3"><strong>In traditional epidemiology software:</strong> Each question requires separate database queries, joins, and analysis pipelines!</p>
                    <p class="mt-2"><strong>With Prolog:</strong> One knowledge base, infinite research questions ✨</p>
                  </div>
                </div>
              </div>

              <!-- Real-World Applications -->
              <div class="bg-white rounded-xl shadow-lg p-8">
                <h3 class="text-xl font-bold text-gray-900 mb-6">🌟 Real-World Applications</h3>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div class="border border-gray-200 rounded-lg p-4">
                    <h4 class="font-bold text-blue-800 mb-3">🔍 Database Queries</h4>
                    <pre class="text-xs bg-gray-100 p-2 rounded font-mono"><code>% One rule for employee-manager relationships
                    manages(john, [alice, bob, charlie]).
                    manages(alice, [david, eve]).

                    % Same rule answers:
                    % Who does John manage? (forward)
                    % Who manages Alice? (backward)  
                    % Does John manage Eve indirectly? (verification)</code></pre>
                  </div>
                  <div class="border border-gray-200 rounded-lg p-4">
                    <h4 class="font-bold text-purple-800 mb-3">🧮 Mathematical Relations</h4>
                    <pre class="text-xs bg-gray-100 p-2 rounded font-mono"><code>% One rule for arithmetic
                    plus(X, Y, Z) :- Z is X + Y.

                    % Same rule can:
                    % Calculate: plus(3, 4, Z) → Z = 7
                    % Subtract: plus(3, Y, 7) → Y = 4  
                    % Verify: plus(3, 4, 7) → true</code></pre>
                  </div>
                  <div class="border border-gray-200 rounded-lg p-4">
                    <h4 class="font-bold text-green-800 mb-3">🕸️ Graph Traversal</h4>
                    <pre class="text-xs bg-gray-100 p-2 rounded font-mono"><code>% One rule for connectivity
                    connected(A, B) :- edge(A, B).
                    connected(A, C) :- edge(A, B), connected(B, C).

                    % Finds paths in any direction automatically!</code></pre>
                  </div>
                  <div class="border border-gray-200 rounded-lg p-4">
                    <h4 class="font-bold text-orange-800 mb-3">📋 Constraint Satisfaction</h4>
                    <pre class="text-xs bg-gray-100 p-2 rounded font-mono"><code>% Same CLP(FD) constraints work for:
% - Generating valid solutions
% - Validating existing solutions  
% - Finding partial solutions
% - Optimizing under constraints</code></pre>
                  </div>
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
              <pre class="text-xs font-mono overflow-x-auto"><code class="language-prolog">% Advanced path finder with depth control - actual code running in demo
find_paths(Start, End, MaxDepth, Path) :- 
    find_paths_helper(Start, End, MaxDepth, [Start], RevPath), 
    reverse(RevPath, Path).

% Base case: We've reached our destination
find_paths_helper(End, End, _, Visited, Visited).

% Recursive case: Find the next step in the path  
find_paths_helper(Start, End, MaxDepth, Visited, Path) :- 
    MaxDepth > 0,                    % Still have depth to explore
    causes(Start, Next),             % Find what Start causes
    \+ member(Next, Visited),        % Avoid cycles (cut loops)
    MaxDepth1 is MaxDepth - 1,       % Decrease remaining depth
    find_paths_helper(Next, End, MaxDepth1, [Next|Visited], Path).

% Basic causal relationships - bidirectional rules
causal_chain(X, Y) :- causes(X, Y).                    % Direct causation
causal_chain(X, Z) :- causes(X, Y), causal_chain(Y, Z). % Transitive causation

% Path tracking with length constraints  
causal_path(X, Y, [X,Y]) :- causes(X, Y).              % Direct path
causal_path(X, Z, [X|Path]) :-                         % Multi-step path
    causes(X, Y), 
    causal_path(Y, Z, Path).

% Optimized path finders for common cases
causal_chain(X, Y, MaxLength) :- causes(X, Y), MaxLength >= 1.
two_step_path(Start, End, [Start, Intermediate, End]) :- 
    causes(Start, Intermediate), 
    causes(Intermediate, End), 
    Start \= Intermediate, Intermediate \= End.
direct_path(Start, End, [Start, End]) :- causes(Start, End).</code></pre>
            </div>

            <!-- N-Queens Code -->
            <div class="bg-gray-50 rounded-lg p-4">
              <h3 class="font-bold text-lg mb-3 text-purple-800">👑 N-Queens CLP(FD) Solver</h3>
              <pre class="text-xs font-mono overflow-x-auto"><code class="language-prolog">% Main CLP(FD) N-Queens solver - actual code running in demo
n_queens_solve(NumQueens, Positions) :- 
    length(Positions, NumQueens),    % Create list of N variables
    Positions ins 1..NumQueens,      % Each queen in column 1..N
    safe_queens(Positions),          % Apply safety constraints  
    label(Positions).                % Find concrete solution

% Safety constraints using CLP(FD)
safe_queens([]).
safe_queens([Q|Qs]) :- 
    safe_queens(Qs), 
    no_attack(Q, Qs, 1).

% No attacks constraint with CLP(FD) operators
no_attack(_, [], _).
no_attack(Q, [Q1|Qs], Dist) :- 
    Q #\= Q1,                        % Different columns
    abs(Q - Q1) #\= Dist,           % No diagonal attacks
    Dist1 #= Dist + 1,              % Increment distance
    no_attack(Q, Qs, Dist1).

% Find multiple solutions with limit for display
find_n_queens_solutions(NumQueens, Solutions) :- 
    findall(Positions, n_queens_solve(NumQueens, Positions), AllSolutions), 
    (length(AllSolutions, Len), Len > 10 -> 
        length(Solutions, 10), append(Solutions, _, AllSolutions) 
    ; Solutions = AllSolutions).

% Entry points for different use cases
n_queens(NumQueens, Solution) :- n_queens_solve(NumQueens, Solution).
n_queens_solution(NumQueens, Solution) :- n_queens_solve(NumQueens, Solution).</code></pre>
            </div>

            <!-- Live Knowledge Base -->
            <div class="bg-gray-50 rounded-lg p-4">
              <h3 class="font-bold text-lg mb-3 text-green-800">📊 Live Prolog Knowledge Base</h3>
              <%= if @facts_loaded do %>
                <div class="text-sm text-green-700 mb-2">
                  ✅ <strong><%= @fact_count %></strong> real CauseNet facts loaded into Prolog session
                </div>
                <pre class="text-xs font-mono overflow-x-auto bg-white p-2 rounded border"><code class="language-prolog">% Live Prolog session with real data:
causes(X, Y) :- /* <%= @fact_count %> facts from CauseNet dataset */

% Active rules in Prolog session:
causal_chain(X, Y) :- causes(X, Y).  % Direct causation
causal_chain(X, Z) :-                % Indirect causation
    causes(X, Y),                    % X causes Y
    causal_chain(Y, Z).              % Y causes Z

% Live queries (executing against real data):
% ?- causes(smoking, What).          % What does smoking cause?
% ?- causes(What, heart_disease).    % What causes heart disease?  
% ?- causal_chain(smoking, death).   % Find causal path to death</code></pre>
              <% else %>
                <div class="text-sm text-yellow-700 mb-2">
                  ⏳ Loading CauseNet facts into Prolog session...
                </div>
                <pre class="text-xs font-mono overflow-x-auto bg-white p-2 rounded border"><code class="language-prolog">% Prolog session starting...
% Loading full CauseNet dataset...
% Please wait while facts are loaded into memory</code></pre>
              <% end %>
            </div>

            <!-- Sudoku Solver -->
            <div class="bg-gray-50 rounded-lg p-4">
              <h3 class="font-bold text-lg mb-3 text-orange-800">🔢 Sudoku CLP(FD) Solver</h3>
              <pre class="text-xs font-mono overflow-x-auto"><code class="language-prolog">% Main CLP(FD) solver - actual code running in demo
solve_sudoku_puzzle(Puzzle, Solution) :- 
    Solution = Puzzle, 
    sudoku(Solution), 
    ground(Solution).

% SWI-Prolog CLP(FD) Sudoku solver with constraint propagation
sudoku(Rows) :- 
    length(Rows, 9),                 % 9x9 grid
    maplist(same_length(Rows), Rows), % All rows same length
    append(Rows, Vars),              % Flatten to variable list
    Vars ins 1..9,                   % All cells in domain 1-9
    maplist(all_distinct, Rows),     % All rows distinct
    transpose(Rows, Cols),           % Get columns
    maplist(all_distinct, Cols),     % All columns distinct  
    distinct_squares(Rows),          % 3x3 boxes distinct
    labeling([], Vars).              % Find concrete solution

% Validate 3x3 squares using constraint propagation
distinct_squares([]).
distinct_squares([R1, R2, R3 | Rows]) :- 
    distinct_square(R1, R2, R3), 
    distinct_squares(Rows).

% Check one 3x3 square
distinct_square([], [], []).
distinct_square([N11,N12,N13|T1], [N21,N22,N23|T2], [N31,N32,N33|T3]) :-
    all_distinct([N11,N12,N13,N21,N22,N23,N31,N32,N33]),
    distinct_square(T1, T2, T3).</code></pre>
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
      :bidirectional -> "bidirectional"
      :adapters -> "adapters"
      _ -> "causal" # default
    end

    # Check if facts are already loaded for this demo type
    facts_loaded = case demo_type do
      "causal" -> PrologDemo.CausalSessionManager.facts_loaded?()
      "constraints" -> PrologDemo.ConstraintSessionManager.facts_loaded?()
      "sudoku" -> PrologDemo.ConstraintSessionManager.facts_loaded?()  # Sudoku uses the same constraint solver
      "playground" -> PrologDemo.PlaygroundSessionManager.facts_loaded?()
      "bidirectional" -> PrologDemo.PlaygroundSessionManager.facts_loaded?()  # Bidirectional demo uses playground session manager
      "adapters" -> true  # Adapter comparison doesn't need CauseNet facts loaded
    end

    socket = socket
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
     |> assign(:fact_count, if(facts_loaded, do: get_fact_count(demo_type), else: 0))
     |> assign(:loading_progress, 0)
     |> assign(:loading_message, "")
     |> assign(:search_depth, 3)
     |> assign(:bidirectional_input1, "smoking")
     |> assign(:bidirectional_input2, "heart_disease") 
     |> assign(:bidirectional_input3a, "smoking")
     |> assign(:bidirectional_input3b, "death")
     |> assign(:bidirectional_results1, nil)
     |> assign(:bidirectional_results2, nil)
     |> assign(:bidirectional_results3, nil)
     |> assign(:bidirectional_loading, false)
     |> assign(:adapter_list, Swiex.Prolog.list_adapters())
     |> assign(:comparison_query, "true")
     |> assign(:comparison_results, %{})

    # 🚀 AUTO-GENERATE Sudoku puzzle on page load for Sudoku tab
    final_socket = if demo_type == "sudoku" and facts_loaded do
      # Generate puzzle immediately on load
      send(self(), {:solve_sudoku})
      assign(socket, :sudoku_loading, true)
    else
      socket
    end

    {:ok, final_socket}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def handle_event("load_facts", %{"size" => size}, socket) do
    if not socket.assigns.facts_loaded do
      dataset_size = String.to_atom(size)
      send(self(), {:load_facts, dataset_size})
      {:noreply, assign(socket, :facts_loading, true)}
    else
      {:noreply, socket}
    end
  end

  # Fallback for old load_facts calls without size
  def handle_event("load_facts", _params, socket) do
    if not socket.assigns.facts_loaded do
      send(self(), {:load_facts, :small})
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

  # Bidirectional demo event handlers
  @impl true
  def handle_event("update_bidirectional_input1", %{"value" => value}, socket) do
    {:noreply, assign(socket, :bidirectional_input1, value)}
  end

  @impl true
  def handle_event("update_bidirectional_input2", %{"value" => value}, socket) do
    {:noreply, assign(socket, :bidirectional_input2, value)}
  end

  @impl true
  def handle_event("update_bidirectional_input3a", %{"value" => value}, socket) do
    {:noreply, assign(socket, :bidirectional_input3a, value)}
  end

  @impl true
  def handle_event("update_bidirectional_input3b", %{"value" => value}, socket) do
    {:noreply, assign(socket, :bidirectional_input3b, value)}
  end

  @impl true
  def handle_event("query_causes_what", _params, socket) do
    cause = socket.assigns.bidirectional_input1
    send(self(), {:query_bidirectional, "causes_what", cause, nil})
    {:noreply, assign(socket, :bidirectional_loading, true)}
  end

  @impl true
  def handle_event("query_what_causes", _params, socket) do
    effect = socket.assigns.bidirectional_input2
    send(self(), {:query_bidirectional, "what_causes", effect, nil})
    {:noreply, assign(socket, :bidirectional_loading, true)}
  end

  @impl true
  def handle_event("query_causal_chain", _params, socket) do
    cause = socket.assigns.bidirectional_input3a
    effect = socket.assigns.bidirectional_input3b
    send(self(), {:query_bidirectional, "causal_chain", cause, effect})
    {:noreply, assign(socket, :bidirectional_loading, true)}
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
    # Use a longer timeout for Sudoku solving
    case GenServer.call(PrologDemo.ConstraintSessionManager,
                        {:query_constraint_solver, "sudoku", %{}},
                        60_000) do  # 60 second timeout
      {:ok, solutions} ->
        {:noreply,
         socket
         |> assign(:sudoku_results, solutions)
         |> assign(:sudoku_loading, false)}
      {:error, reason} ->
        error_msg = case reason do
          :timeout -> "Sudoku solving timed out. The puzzle may be too complex."
          :query_timeout -> "Query timed out. Please try again."
          msg when is_binary(msg) -> "Error solving Sudoku: #{msg}"
          _ -> "Error solving Sudoku: #{inspect(reason)}"
        end
        {:noreply,
         socket
         |> assign(:sudoku_loading, false)
         |> put_flash(:error, error_msg)}
    end
  end

  @impl true
  def handle_info({:solve_n_queens, n}, socket) do
    # Use a longer timeout for N-Queens solving
    case GenServer.call(PrologDemo.ConstraintSessionManager,
                        {:query_constraint_solver, "n_queens", %{"n" => n}},
                        60_000) do  # 60 second timeout
      {:ok, solutions} ->
        {:noreply,
         socket
         |> assign(:queens_results, solutions)
         |> assign(:queens_loading, false)}
      {:error, reason} ->
        error_msg = case reason do
          :timeout -> "N-Queens solving timed out. Try a smaller board size."
          :query_timeout -> "Query timed out. Please try again."
          msg when is_binary(msg) -> "Error solving N-Queens: #{msg}"
          _ -> "Error solving N-Queens: #{inspect(reason)}"
        end
        {:noreply,
         socket
         |> assign(:queens_loading, false)
         |> put_flash(:error, error_msg)}
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
  def handle_info({:query_bidirectional, query_type, param1, param2}, socket) do
    # Use the CauseNet session manager with real causal data
    case query_type do
      "causes_what" ->
        # Query: What does X cause? (Forward direction)
        case PrologDemo.CausalSessionManager.query_direct_effects(param1) do
          {:ok, effects} when is_list(effects) ->
            {:noreply,
             socket
             |> assign(:bidirectional_results1, Enum.sort(effects))
             |> assign(:bidirectional_loading, false)}
          {:error, _reason} ->
            {:noreply,
             socket
             |> assign(:bidirectional_results1, [])
             |> assign(:bidirectional_loading, false)}
        end

      "what_causes" ->
        # Query: What causes X? (Backward direction)
        case PrologDemo.CausalSessionManager.query_direct_causes(param1) do
          {:ok, causes} when is_list(causes) ->
            {:noreply,
             socket
             |> assign(:bidirectional_results2, Enum.sort(causes))
             |> assign(:bidirectional_loading, false)}
          {:error, _reason} ->
            {:noreply,
             socket
             |> assign(:bidirectional_results2, [])
             |> assign(:bidirectional_loading, false)}
        end

      "causal_chain" ->
        # Query: Does causal chain exist between X and Y?
        case PrologDemo.CausalSessionManager.query_causal_paths(param1, param2) do
          {:ok, paths} when is_list(paths) and length(paths) > 0 ->
            {:noreply,
             socket
             |> assign(:bidirectional_results3, true)
             |> assign(:bidirectional_loading, false)}
          {:ok, []} ->
            {:noreply,
             socket
             |> assign(:bidirectional_results3, false)
             |> assign(:bidirectional_loading, false)}
          {:error, _reason} ->
            {:noreply,
             socket
             |> assign(:bidirectional_results3, false)
             |> assign(:bidirectional_loading, false)}
        end
    end
  end

  @impl true
  def handle_info({:load_facts, size}, socket) do
    # Load facts with specified size for the appropriate demo type
    session_manager = case socket.assigns.demo_type do
      "causal" -> PrologDemo.CausalSessionManager
      "constraints" -> PrologDemo.ConstraintSessionManager
      "playground" -> PrologDemo.PlaygroundSessionManager
      "bidirectional" -> PrologDemo.PlaygroundSessionManager
    end

    # Capture the LiveView PID before starting the task
    live_view_pid = self()
    
    Task.start(fn ->
      case session_manager do
        PrologDemo.CausalSessionManager ->
          # Use the new load_dataset function for causal sessions
          case PrologDemo.CausalSessionManager.load_dataset(size) do
            {:ok, fact_count} ->
              send(live_view_pid, {:facts_loaded, fact_count})
            {:error, reason} ->
              send(live_view_pid, {:facts_loading_error, reason})
          end
        _ ->
          # Use the old method for other session types
          session_manager.load_facts_with_progress(live_view_pid)
      end
    end)

    {:noreply, socket}
  end

  # Fallback for old :load_facts message format
  def handle_info(:load_facts, socket) do
    send(self(), {:load_facts, :small})
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
  def handle_info({:facts_loaded, success}, socket) when is_boolean(success) do
    {:noreply,
     socket
     |> assign(:facts_loading, false)
     |> assign(:facts_loaded, success)
     |> assign(:loading_progress, 100)
     |> assign(:loading_message, if(success, do: "Facts loaded successfully!", else: "Failed to load facts"))
     |> put_flash(if(success, do: :info, else: :error),
                  if(success, do: "CauseNet facts loaded successfully!", else: "Failed to load CauseNet facts"))}
  end

  def handle_info({:facts_loaded, fact_count}, socket) when is_integer(fact_count) do
    {:noreply,
     socket
     |> assign(:facts_loading, false)
     |> assign(:facts_loaded, true)
     |> assign(:fact_count, fact_count)
     |> assign(:loading_progress, 100)
     |> assign(:loading_message, "#{fact_count} facts loaded successfully!")
     |> put_flash(:info, "#{fact_count} CauseNet facts loaded successfully!")}
  end

  def handle_info({:facts_loading_error, reason}, socket) do
    {:noreply,
     socket
     |> assign(:facts_loading, false)
     |> assign(:facts_loaded, false)
     |> assign(:loading_progress, 0)
     |> assign(:loading_message, "Failed to load facts: #{reason}")
     |> put_flash(:error, "Failed to load CauseNet facts: #{reason}")}
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

  # Adapter comparison event handlers

  @impl true
  def handle_event("update_comparison_query", %{"value" => value}, socket) do
    {:noreply, assign(socket, :comparison_query, value)}
  end

  @impl true
  def handle_event("set_comparison_query", %{"query" => query}, socket) do
    {:noreply, assign(socket, :comparison_query, query)}
  end

  @impl true
  def handle_event("run_comparison", _params, socket) do
    query = socket.assigns.comparison_query
    
    if String.trim(query) != "" do
      # Run the query across all adapters
      results = Swiex.Prolog.query_all(query)
      {:noreply, assign(socket, :comparison_results, results)}
    else
      {:noreply, put_flash(socket, :error, "Please enter a query")}
    end
  end

  @impl true
  def handle_event("test_adapter", %{"adapter" => adapter_module}, socket) do
    try do
      adapter = String.to_existing_atom(adapter_module)
      case Swiex.Prolog.query("true", adapter: adapter) do
        {:ok, _results} ->
          {:noreply, put_flash(socket, :info, "#{adapter_module} is working correctly!")}
        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "#{adapter_module} test failed: #{inspect(reason)}")}
      end
    rescue
      _error ->
        {:noreply, put_flash(socket, :error, "Invalid adapter: #{adapter_module}")}
    end
  end

  defp get_tab_for_demo(demo_type) do
    case demo_type do
      "causal" -> "causal-reasoning"
      "constraints" -> "constraint-solving"
      "sudoku" -> "sudoku-solver"
      "playground" -> "prolog-playground"
      "bidirectional" -> "bidirectional-demo"
      "adapters" -> "adapter-comparison"
      _ -> "causal-reasoning"
    end
  end


  defp get_fact_count(demo_type) do
    case demo_type do
      "causal" ->
        # Return estimate - actual facts are loaded once in session startup
        # Don't reload the entire dataset here just for a count!
        case PrologDemo.CausalSessionManager.get_monitoring_summary() do
          {:ok, summary} -> Map.get(summary, "total_facts", 50000)
          _ -> 50000  # Reasonable estimate for CauseNet dataset
        end
      _ ->
        # For other demos, return a reasonable estimate
        10000
    end
  end

  # Helper functions for adapter comparison

  def adapter_status_icon_class(:ok), do: "text-2xl"
  def adapter_status_icon_class(_), do: "text-2xl opacity-50"

  def adapter_health_badge_class(:ok), do: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800"
  def adapter_health_badge_class(_), do: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800"

  def format_feature_name(feature) do
    feature
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  def get_adapter_name(adapter_module) do
    case adapter_module do
      Swiex.Adapters.SwiAdapter -> "SWI-Prolog"
      Swiex.Adapters.ErlogAdapter -> "Erlog"
      Swiex.Adapters.ScryerAdapter -> "Scryer Prolog"
      _ -> 
        adapter_module
        |> Module.split()
        |> List.last()
        |> String.replace("Adapter", "")
    end
  end

  def result_status_badge_class({:ok, _}), do: "inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800"
  def result_status_badge_class({:error, _}), do: "inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800"

  def get_result_status_text({:ok, results}) when is_list(results) do
    if length(results) > 0 do
      "✅ Success (#{length(results)})"
    else
      "✅ Success (0)"
    end
  end
  def get_result_status_text({:error, _reason}), do: "❌ Error"

end
