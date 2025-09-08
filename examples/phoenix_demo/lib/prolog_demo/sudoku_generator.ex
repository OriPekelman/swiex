defmodule PrologDemo.SudokuGenerator do
  @moduledoc """
  Generates random Sudoku puzzles in Elixir to showcase Elixir-Prolog integration.
  This demonstrates generating puzzles on the Elixir side and solving them with Prolog.
  """

  @doc """
  Generate a random 4x4 Sudoku puzzle with some cells filled.
  Returns a tuple {puzzle, solution}.
  """
  def generate_4x4_puzzle do
    # Start with a valid solution
    solution = [
      [1, 2, 3, 4],
      [3, 4, 1, 2],
      [2, 1, 4, 3],
      [4, 3, 2, 1]
    ]

    # Randomly shuffle rows and columns to create variations
    shuffled_solution = solution
    |> shuffle_solution()

    # Create puzzle by removing random cells
    puzzle = create_puzzle_from_solution(shuffled_solution, 0.4)  # Remove 40% of cells

    {puzzle, shuffled_solution}
  end

  @doc """
  Generate a random 9x9 Sudoku puzzle with medium difficulty.
  Returns a tuple {puzzle, solution}.
  """
  def generate_9x9_puzzle do
    # Start with a few different base solutions and pick one randomly
    base_solutions = [
      [
        [5, 3, 4, 6, 7, 8, 9, 1, 2],
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        [1, 9, 8, 3, 4, 2, 5, 6, 7],
        [8, 5, 9, 7, 6, 1, 4, 2, 3],
        [4, 2, 6, 8, 5, 3, 7, 9, 1],
        [7, 1, 3, 9, 2, 4, 8, 5, 6],
        [9, 6, 1, 5, 3, 7, 2, 8, 4],
        [2, 8, 7, 4, 1, 9, 6, 3, 5],
        [3, 4, 5, 2, 8, 6, 1, 7, 9]
      ],
      [
        [1, 2, 3, 4, 5, 6, 7, 8, 9],
        [4, 5, 6, 7, 8, 9, 1, 2, 3],
        [7, 8, 9, 1, 2, 3, 4, 5, 6],
        [2, 3, 1, 5, 6, 4, 8, 9, 7],
        [5, 6, 4, 8, 9, 7, 2, 3, 1],
        [8, 9, 7, 2, 3, 1, 5, 6, 4],
        [3, 1, 2, 6, 4, 5, 9, 7, 8],
        [6, 4, 5, 9, 7, 8, 3, 1, 2],
        [9, 7, 8, 3, 1, 2, 6, 4, 5]
      ],
      [
        [9, 8, 7, 6, 5, 4, 3, 2, 1],
        [1, 2, 3, 7, 8, 9, 6, 5, 4],
        [6, 5, 4, 3, 2, 1, 9, 8, 7],
        [8, 7, 9, 5, 6, 2, 1, 4, 3],
        [4, 3, 1, 9, 7, 8, 2, 6, 5],
        [2, 6, 5, 4, 1, 3, 7, 9, 8],
        [7, 9, 8, 2, 3, 5, 4, 1, 6],
        [3, 1, 6, 8, 4, 7, 5, 3, 9],
        [5, 4, 2, 1, 9, 6, 8, 7, 3]
      ]
    ]
    
    # Pick a random base solution
    solution = Enum.random(base_solutions)

    # Shuffle the solution by swapping rows within blocks and columns within blocks
    shuffled_solution = solution
    |> shuffle_9x9_solution()

    # Create puzzle by removing random cells with medium difficulty
    puzzle = create_puzzle_from_solution(shuffled_solution, 0.55)  # Remove 55% of cells

    {puzzle, shuffled_solution}
  end

  @doc """
  Validate a Sudoku solution in Elixir.
  Returns true if the solution is valid, false otherwise.
  """
  def validate_solution(solution) do
    size = length(solution)
    
    # Check all rows, columns, and boxes
    valid_rows?(solution) and
    valid_columns?(solution) and
    valid_boxes?(solution, size)
  end

  @doc """
  Check if a puzzle is partially filled correctly (no conflicts).
  Returns true if valid so far, false if there are conflicts.
  """
  def validate_puzzle(puzzle) do
    size = length(puzzle)
    
    # Check partial constraints
    valid_partial_rows?(puzzle) and
    valid_partial_columns?(puzzle) and
    valid_partial_boxes?(puzzle, size)
  end

  # Private functions

  defp shuffle_solution(solution) do
    # For 4x4, we can swap rows within the top 2x2 and bottom 2x2 blocks
    # This maintains the valid Sudoku property
    solution
    |> maybe_swap_rows(0, 1)  # Top block rows
    |> maybe_swap_rows(2, 3)  # Bottom block rows
    |> transpose()            # Convert to column operations
    |> maybe_swap_rows(0, 1)  # Left block columns (now rows)
    |> maybe_swap_rows(2, 3)  # Right block columns (now rows)
    |> transpose()            # Convert back
  end

  defp shuffle_9x9_solution(solution) do
    # For 9x9, swap rows and columns within each 3x3 block group
    solution
    # Shuffle rows within top 3x3 block group (rows 0-2)
    |> maybe_swap_rows(0, 1) |> maybe_swap_rows(1, 2) |> maybe_swap_rows(0, 2)
    # Shuffle rows within middle 3x3 block group (rows 3-5)
    |> maybe_swap_rows(3, 4) |> maybe_swap_rows(4, 5) |> maybe_swap_rows(3, 5)
    # Shuffle rows within bottom 3x3 block group (rows 6-8)
    |> maybe_swap_rows(6, 7) |> maybe_swap_rows(7, 8) |> maybe_swap_rows(6, 8)
    # Now do the same for columns
    |> transpose()
    # Shuffle columns within each block group
    |> maybe_swap_rows(0, 1) |> maybe_swap_rows(1, 2) |> maybe_swap_rows(0, 2)
    |> maybe_swap_rows(3, 4) |> maybe_swap_rows(4, 5) |> maybe_swap_rows(3, 5)
    |> maybe_swap_rows(6, 7) |> maybe_swap_rows(7, 8) |> maybe_swap_rows(6, 8)
    |> transpose()
  end

  defp maybe_swap_rows(matrix, row1, row2) do
    if :rand.uniform(2) == 1 do
      swap_rows(matrix, row1, row2)
    else
      matrix
    end
  end

  defp swap_rows(matrix, row1, row2) do
    matrix
    |> List.update_at(row1, fn _ -> Enum.at(matrix, row2) end)
    |> List.update_at(row2, fn _ -> Enum.at(matrix, row1) end)
  end

  defp transpose(matrix) do
    matrix
    |> Enum.zip()
    |> Enum.map(&Tuple.to_list/1)
  end

  defp create_puzzle_from_solution(solution, remove_ratio) do
    total_cells = length(solution) * length(hd(solution))
    cells_to_remove = round(total_cells * remove_ratio)
    
    # Generate random positions to remove
    positions_to_remove = generate_random_positions(length(solution), cells_to_remove)
    
    # Create puzzle by setting selected positions to 0
    remove_cells(solution, positions_to_remove)
  end

  defp generate_random_positions(size, count) do
    all_positions = for row <- 0..(size-1), col <- 0..(size-1), do: {row, col}
    
    all_positions
    |> Enum.shuffle()
    |> Enum.take(count)
  end

  defp remove_cells(solution, positions) do
    Enum.reduce(positions, solution, fn {row, col}, acc ->
      List.update_at(acc, row, fn row_data ->
        List.update_at(row_data, col, fn _ -> 0 end)
      end)
    end)
  end

  # Validation functions

  defp valid_rows?(matrix) do
    Enum.all?(matrix, &valid_sequence?/1)
  end

  defp valid_columns?(matrix) do
    matrix
    |> transpose()
    |> valid_rows?()
  end

  defp valid_boxes?(matrix, 4) do
    # For 4x4, check four 2x2 boxes
    boxes = [
      extract_box(matrix, 0, 0, 2),  # Top-left
      extract_box(matrix, 0, 2, 2),  # Top-right
      extract_box(matrix, 2, 0, 2),  # Bottom-left
      extract_box(matrix, 2, 2, 2)   # Bottom-right
    ]
    
    Enum.all?(boxes, &valid_sequence?/1)
  end

  defp valid_boxes?(matrix, 9) do
    # For 9x9, check nine 3x3 boxes
    boxes = for row_start <- [0, 3, 6], col_start <- [0, 3, 6] do
      extract_box(matrix, row_start, col_start, 3)
    end
    
    Enum.all?(boxes, &valid_sequence?/1)
  end

  defp extract_box(matrix, start_row, start_col, box_size) do
    for row <- start_row..(start_row + box_size - 1),
        col <- start_col..(start_col + box_size - 1) do
      matrix |> Enum.at(row) |> Enum.at(col)
    end
  end

  defp valid_sequence?(sequence) do
    non_zero = Enum.reject(sequence, &(&1 == 0))
    length(non_zero) == length(Enum.uniq(non_zero))
  end

  # Partial validation (for puzzles with zeros)

  defp valid_partial_rows?(matrix) do
    Enum.all?(matrix, &valid_partial_sequence?/1)
  end

  defp valid_partial_columns?(matrix) do
    matrix
    |> transpose()
    |> valid_partial_rows?()
  end

  defp valid_partial_boxes?(matrix, size) do
    case size do
      4 -> valid_partial_4x4_boxes?(matrix)
      9 -> valid_partial_9x9_boxes?(matrix)
      _ -> false
    end
  end

  defp valid_partial_4x4_boxes?(matrix) do
    boxes = [
      extract_box(matrix, 0, 0, 2),
      extract_box(matrix, 0, 2, 2),
      extract_box(matrix, 2, 0, 2),
      extract_box(matrix, 2, 2, 2)
    ]
    
    Enum.all?(boxes, &valid_partial_sequence?/1)
  end

  defp valid_partial_9x9_boxes?(matrix) do
    boxes = for row_start <- [0, 3, 6], col_start <- [0, 3, 6] do
      extract_box(matrix, row_start, col_start, 3)
    end
    
    Enum.all?(boxes, &valid_partial_sequence?/1)
  end

  defp valid_partial_sequence?(sequence) do
    non_zero = Enum.reject(sequence, &(&1 == 0))
    length(non_zero) == length(Enum.uniq(non_zero))
  end
end