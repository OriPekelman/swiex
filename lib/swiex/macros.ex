defmodule Swiex.Macros do
  @moduledoc """
  Macros for inlining Prolog code in Elixir.

  This module provides the `prolog` macro that allows you to write Prolog code
  directly in your Elixir modules with variable interpolation and sharing.
  """

  @doc """
  Execute Prolog code with variable interpolation.

  ## Examples

      iex> list = [:a, :b, :c]
      iex> Swiex.query("member(X, " <> inspect(list) <> ").")

      iex> n = 5
      iex> Swiex.query("factorial(" <> Integer.to_string(n) <> ", Result).")
      ...> |> Swiex.get_var(:Result)

      iex> x = 10
      iex> y = 5
      iex> Swiex.query("""
      ...>   " <> Integer.to_string(x) <> " > " <> Integer.to_string(y) <> ", Result is " <> Integer.to_string(x + y) <> "."
      ...> ")
      ...> |> Swiex.get_var(:Result)
  """
  defmacro prolog(do: block) do
    compiled_query = Swiex.MacroCompiler.compile_prolog_block(block)
    
    quote do
      Swiex.query(unquote(compiled_query))
    end
  end

  @doc """
  Execute Prolog code with explicit variable binding.

  ## Examples

      def query_with_vars do
        prolog_with_vars do
          member(X, [a, b, c])
        end
        |> bind_vars([:X])
      end
  """
  defmacro prolog_with_vars(do: block) do
    compiled_query = Swiex.MacroCompiler.compile_prolog_block(block)
    
    quote do
      Swiex.query(unquote(compiled_query))
    end
  end

  @doc """
  Define Prolog facts and rules inline.

  ## Examples

      def setup_knowledge_base do
        prolog_define do
          parent(john, mary).
          parent(mary, bob).
          ancestor(X, Y) :- parent(X, Y).
          ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).
        end
      end
  """
  defmacro prolog_define(do: block) do
    compiled_code = Swiex.MacroCompiler.compile_prolog_block(block)
    
    quote do
      Swiex.define(unquote(compiled_code))
    end
  end

  @doc """
  Execute Prolog code asynchronously.

  ## Examples

      def async_factorial(n) do
        Swiex.query_async("factorial(" <> Integer.to_string(n) <> ", Result).")
      end
  """
  defmacro prolog_async(do: block) do
    compiled_query = Swiex.MacroCompiler.compile_prolog_block(block)
    
    quote do
      Swiex.query_async(unquote(compiled_query))
    end
  end

  # Public functions called by macros

  @doc false
  def execute_prolog(block) when is_binary(block) do
    Swiex.query(block)
  end

  @doc false
  def execute_prolog_with_vars(block) when is_binary(block) do
    Swiex.query(block)
  end

  @doc false
  def define_prolog(block) when is_binary(block) do
    Swiex.define(block)
  end

  # Private functions for macro processing

  defmacro __using__(_opts) do
    quote do
      import Swiex.Macros, only: [
        prolog: 1, 
        prolog_with_vars: 1, 
        prolog_define: 1,
        prolog_async: 1
      ]
    end
  end
end 