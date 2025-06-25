defmodule Swiex.MacroCompiler do
  @moduledoc """
  Compiles Elixir expressions with variable interpolation into Prolog queries.
  """

  @doc """
  Compile a block of Prolog code with Elixir variable interpolation.
  """
  def compile_prolog_block(block) do
    case block do
      {:__block__, _meta, expressions} ->
        expressions
        |> Enum.map(&compile_expression/1)
        |> Enum.join(",\n")
        |> add_period()
      
      expression ->
        compile_expression(expression)
        |> add_period()
    end
  end

  @doc """
  Compile a single Prolog expression.
  """
  def compile_expression(expression) do
    case expression do
      # Handle string literals
      {:__aliases__, _meta, _module} = alias_expr ->
        Macro.to_string(alias_expr)
      
      # Handle variable interpolation #{var}
      {:unquote, _meta, [var]} ->
        compile_elixir_var(var)
      
      # Handle function calls
      {:., _meta, [left, right]} ->
        "#{compile_expression(left)}.#{right}"
      
      # Handle function calls with arguments
      {fun, _meta, args} when is_atom(fun) ->
        case args do
          [] -> "#{fun}"
          _ -> 
            compiled_args = Enum.map(args, &compile_expression/1)
            "#{fun}(#{Enum.join(compiled_args, ", ")})"
        end
      
      # Handle lists
      list when is_list(list) ->
        case list do
          [] -> "[]"
          _ ->
            elements = Enum.map(list, &compile_expression/1)
            "[#{Enum.join(elements, ", ")}]"
        end
      
      # Handle atoms
      atom when is_atom(atom) ->
        case atom do
          true -> "true"
          false -> "false"
          nil -> "nil"
          _ -> "#{atom}"
        end
      
      # Handle numbers
      num when is_number(num) ->
        "#{num}"
      
      # Handle strings
      str when is_binary(str) ->
        "'#{escape_string(str)}'"
      
      # Handle other literals
      literal ->
        "#{literal}"
    end
  end

  @doc """
  Compile an Elixir variable for use in Prolog.
  """
  def compile_elixir_var(var) do
    case var do
      # Handle atoms (Prolog variables)
      atom when is_atom(atom) ->
        "#{atom}"
      
      # Handle strings
      str when is_binary(str) ->
        "'#{escape_string(str)}'"
      
      # Handle numbers
      num when is_number(num) ->
        "#{num}"
      
      # Handle lists
      list when is_list(list) ->
        case list do
          [] -> "[]"
          _ ->
            elements = Enum.map(list, &compile_elixir_var/1)
            "[#{Enum.join(elements, ", ")}]"
        end
      
      # Handle other expressions
      expr ->
        # For complex expressions, we need to evaluate them at runtime
        # This is a simplified approach - in practice, you might want
        # to handle this differently
        Macro.to_string(expr)
    end
  end

  @doc """
  Escape a string for Prolog.
  """
  def escape_string(str) do
    str
    |> String.replace("'", "\\'")
    |> String.replace("\n", "\\n")
    |> String.replace("\r", "\\r")
    |> String.replace("\t", "\\t")
  end

  @doc """
  Add a period to the end of a Prolog query if it doesn't have one.
  """
  def add_period(query) do
    query = String.trim(query)
    if String.ends_with?(query, ".") do
      query
    else
      query <> "."
    end
  end
end 