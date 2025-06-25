#!/usr/bin/env elixir

# Basic usage example for Swiex
# Run with: elixir examples/basic_usage.exs

# Add the lib directory to the code path if not running under Mix
unless Code.ensure_loaded?(Swiex) do
  Code.append_path(Path.join([File.cwd!(), "_build", "dev", "lib", "swiex", "ebin"]))
end

# Explicitly start the application supervision tree if not already started
# unless Process.whereis(Swiex.MQI) do
#   IO.puts("[script] Starting Swiex supervision tree...")
#   Swiex.Application.start(:normal, [])
# end

IO.puts("Swiex application started successfully!")

defmodule BasicExample do
  use Swiex

  def simple_query do
    IO.puts("About to execute simple query...")
    case Swiex.MQI.query("member(X, [1,2,3])") do
      {:ok, results} ->
        IO.puts("Success! Results: #{inspect(results)}")
      {:error, reason} ->
        IO.puts("Error: #{reason}")
    end
  end

  def factorial_example do
    IO.puts("=== Factorial Example ===")
    IO.puts("About to define factorial predicate...")

    # Define factorial predicate using assertz
    case Swiex.MQI.assertz("factorial(0, 1).") do
      {:ok, _} ->
        case Swiex.MQI.assertz("factorial(N, Result) :- N > 0, N1 is N - 1, factorial(N1, F1), Result is N * F1.") do
          {:ok, _} ->
            IO.puts("Factorial predicate defined successfully!")

            IO.puts("About to calculate factorial of 5...")
            case Swiex.MQI.query("factorial(5, Result)") do
              {:ok, results} ->
                IO.puts("Factorial results: #{inspect(results)}")
              {:error, reason} ->
                IO.puts("Error: #{reason}")
            end
          {:error, reason} ->
            IO.puts("Failed to define factorial rule: #{reason}")
        end
      {:error, reason} ->
        IO.puts("Failed to define factorial base case: #{reason}")
    end
  end

  def variable_interpolation do
    IO.puts("\n=== Variable Interpolation ===")

    x = 10
    y = 5

    query = "#{x} > #{y}, Result is #{x} + #{y}."
    IO.puts("About to execute: #{query}")
    case Swiex.query(query) do
      {:ok, results} ->
        result = Swiex.get_var({:ok, results}, :Result)
        case result do
          {:ok, [value]} ->
            IO.puts("#{x} + #{y} = #{value}")
          _ ->
            IO.puts("No result found")
        end

      {:error, reason} ->
        IO.puts("Error: #{reason}")
    end
  end

  def list_operations do
    IO.puts("\n=== List Operations ===")

    my_list = [1, 2, 3, 4, 5]

    query = "member(X, #{inspect(my_list)}), X > 3."
    IO.puts("About to execute: #{query}")
    case Swiex.query(query) do
      {:ok, results} ->
        IO.puts("Members greater than 3:")
        Enum.each(results, fn result ->
          IO.puts("  X = #{result["X"]}")
        end)

      {:error, reason} ->
        IO.puts("Error: #{reason}")
    end
  end

  def async_query_example do
    IO.puts("\n=== Async Query Example ===")

    # Define a slow predicate
    Swiex.define("""
      slow_factorial(0, 1).
      slow_factorial(N, Result) :-
        N > 0,
        N1 is N - 1,
        slow_factorial(N1, F1),
        Result is N * F1.
    """)

    # Start async query
    case Swiex.query_async("slow_factorial(6, Result).") do
      {:ok, query_id} ->
        IO.puts("Async query started with ID: #{query_id}")

        # Get results
        case Swiex.get_async_result(query_id, 5000) do
          {:ok, results} ->
            result = Swiex.get_var({:ok, results}, :Result)
            case result do
              {:ok, [value]} ->
                IO.puts("Async factorial of 6 = #{value}")
              _ ->
                IO.puts("No async result found")
            end

          {:error, reason} ->
            IO.puts("Async query error: #{reason}")
        end

      {:error, reason} ->
        IO.puts("Failed to start async query: #{reason}")
    end
  end

  def consult_string_example do
    IO.puts("=== Consult String Example ===")
    IO.puts("About to load Prolog code from string...")

    prolog_code = """
    % Define a simple predicate
    greet(Name, Message) :-
      Message = ['Hello', Name, '!'].

    % Define a list processing predicate
    double_list([], []).
    double_list([H|T], [H2|T2]) :-
      H2 is H * 2,
      double_list(T, T2).
    """

    case Swiex.MQI.consult_string(prolog_code) do
      {:ok, _} ->
        IO.puts("Code loaded successfully!")

        # Test the loaded predicates
        IO.puts("Testing greet predicate...")
        case Swiex.MQI.query("greet('World', Message)") do
          {:ok, results} ->
            IO.puts("Greet results: #{inspect(results)}")
          {:error, reason} ->
            IO.puts("Greet error: #{reason}")
        end

        IO.puts("Testing double_list predicate...")
        case Swiex.MQI.query("double_list([1,2,3], Result)") do
          {:ok, results} ->
            IO.puts("Double list results: #{inspect(results)}")
          {:error, reason} ->
            IO.puts("Double list error: #{reason}")
        end

      {:error, reason} ->
        IO.puts("Failed to load code: #{reason}")
    end
  end

  def persistent_session_example do
    IO.puts("=== Persistent Session Example ===")
    IO.puts("Starting persistent MQI session...")

    case Swiex.MQI.start_session() do
      {:ok, session} ->
        IO.puts("Session started successfully!")

        # Define factorial predicate in the session
        IO.puts("Defining factorial predicate...")
        case Swiex.MQI.assertz(session, "factorial(0, 1).") do
          {:ok, _} ->
            case Swiex.MQI.assertz(session, "factorial(N, Result) :- N > 0, N1 is N - 1, factorial(N1, F1), Result is N * F1.") do
              {:ok, _} ->
                IO.puts("Factorial predicate defined!")

                # Now query the defined predicate
                IO.puts("Calculating factorial of 5...")
                case Swiex.MQI.query(session, "factorial(5, Result)") do
                  {:ok, results} ->
                    case results do
                      [%{"Result" => result}] ->
                        IO.puts("Factorial of 5 = #{result}")
                      _ ->
                        IO.puts("Factorial results: #{inspect(results)}")
                    end
                  {:error, reason} ->
                    IO.puts("Query error: #{reason}")
                end

                # Try another query
                IO.puts("Calculating factorial of 3...")
                case Swiex.MQI.query(session, "factorial(3, Result)") do
                  {:ok, results} ->
                    case results do
                      [%{"Result" => result}] ->
                        IO.puts("Factorial of 3 = #{result}")
                      _ ->
                        IO.puts("Factorial(3) results: #{inspect(results)}")
                    end
                  {:error, reason} ->
                    IO.puts("Query error: #{reason}")
                end

              {:error, reason} ->
                IO.puts("Failed to define factorial rule: #{reason}")
            end
          {:error, reason} ->
            IO.puts("Failed to define factorial base case: #{reason}")
        end

        # Clean up
        Swiex.MQI.stop_session(session)
        IO.puts("Session stopped.")

      {:error, reason} ->
        IO.puts("Failed to start session: #{reason}")
    end
  end
end

# Run examples
IO.puts("Starting to run examples...")
BasicExample.simple_query()
BasicExample.factorial_example()
BasicExample.variable_interpolation()
BasicExample.list_operations()
BasicExample.async_query_example()
BasicExample.consult_string_example()
BasicExample.persistent_session_example()
IO.puts("All examples completed!")
