# Swiex - Multi-Adapter Prolog Integration for Elixir

Swiex is an Elixir library that provides seamless integration with multiple Prolog implementations, including SWI-Prolog (via MQI), Erlog, and Scryer Prolog. Execute Prolog queries, define inline logic, and leverage constraint solving directly from your Elixir applications.

**Version 0.3.0**: Now with multi-adapter architecture, monitoring capabilities, and a comprehensive Phoenix demo application showcasing real-world Prolog integration!

## Features

### Core Capabilities
- **Multi-Adapter Architecture** - Support for SWI-Prolog, Erlog, and Scryer Prolog
- **Full MQI Protocol Support** - Complete implementation of SWI-Prolog's Machine Query Interface
- **Persistent Sessions** - Maintain stateful connections for complex workflows
- **Inline Prolog Code** - Define facts and rules on-the-fly using `assertz/1`
- **Variable Binding Extraction** - Clean map-based results with variable names
- **Hybrid DSL Support** - Choose between Elixir DSL syntax and raw Prolog code
- **Pin Operator Support** - Variable interpolation in DSL queries using `^` operator
- **Streaming Results** - Handle large datasets efficiently with configurable chunk sizes
- **Transaction Support** - Atomic operations with automatic session management
- **Security Features** - Query validation and sanitization to prevent injection attacks

### New in v0.3.0
- **Adapter Abstraction** - Unified interface for multiple Prolog implementations
- **Performance Monitoring** - Real-time query statistics and session health tracking
- **Phoenix Demo Application** - Full-featured web app demonstrating:
  - Medical causal reasoning with CauseNet data
  - Constraint solving (N-Queens with all 92 solutions, Sudoku)
  - Interactive Prolog playground
  - Multi-adapter comparison interface
  - Real-time monitoring dashboard
- **Enhanced Testing** - Comprehensive test suite with proper concurrent test isolation

## Status: Pre-Alpha forever

This is a vibe-coded toy implementation built for weird reasons. I expect the performance to be horrendous; security to be inexistant; and the potential to summon evil spirits from another century to be very high.


## Installation

Add `swiex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:swiex, "~> 0.3.0"}
    # Optional: Add for Erlog support
    # {:erlog, github: "rvirding/erlog", branch: "develop", optional: true}
  ]
end
```

## Prerequisites

- [SWI-Prolog](https://www.swi-prolog.org/) must be installed and available in your PATH
- Test with: `swipl --version`

Possily we also get to have:

```
brew install scryer-prolog
```

## Quick Start

### Basic Query

```elixir
# Simple one-shot query
case Swiex.MQI.query("member(X, [1,2,3])") do
  {:ok, results} ->
    IO.inspect(results)
    # Returns: [%{"X" => 1}, %{"X" => 2}, %{"X" => 3}]
  {:error, reason} ->
    IO.puts("Error: #{reason}")
end
```

### Persistent Sessions with Inline Code

```elixir
# Start a persistent session
{:ok, session} = Swiex.MQI.start_session()

# Define Prolog predicates inline
Swiex.MQI.assertz(session, "factorial(0, 1).")
Swiex.MQI.assertz(session, "factorial(N, Result) :- N > 0, N1 is N - 1, factorial(N1, F1), Result is N * F1.")

# Query the defined predicates
case Swiex.MQI.query(session, "factorial(5, Result)") do
  {:ok, [%{"Result" => result}]} ->
    IO.puts("Factorial of 5 = #{result}")  # Prints: Factorial of 5 = 120
  {:error, reason} ->
    IO.puts("Error: #{reason}")
end

# Clean up
Swiex.MQI.stop_session(session)
```

## Domain Specific Language (DSL)

Swiex provides a powerful DSL that gives you two approaches for working with Prolog:

### Elixir DSL (Natural Syntax)

```elixir
import Swiex.DSL

# Simple, natural syntax
all(member(X, [1,2,3]))           # Get all solutions
one(factorial(5, Result))         # Get first solution
solutions(member(X, [1,2,3]), 2)  # Get limited solutions
query(factorial(5, Result))       # Execute query
```

### Inline Prolog (Raw Prolog Code)

```elixir
import Swiex.DSL

# Define Prolog predicates inline
prolog do
  """
  member(X, [X|_]).
  member(X, [_|T]) :- member(X, T).
  
  append([], L, L).
  append([H|T], L, [H|R]) :- append(T, L, R).
  """
end

# Execute raw Prolog queries
query_prolog("member(X, [1,2,3]), X > 2")
query_prolog_one("member(X, [1,2,3,4,5]), X > 3")
query_prolog_solutions("member(X, [1,2,3,4,5]), X > 2", 2)
```

### Mixed Approach

```elixir
# Use inline Prolog for complex predicate definition
Swiex.MQI.consult_string("""
  filter_positive([], []).
  filter_positive([H|T], [H|R]) :- H > 0, filter_positive(T, R).
  filter_positive([H|T], R) :- H =< 0, filter_positive(T, R).
""")

# Use Elixir DSL for simple queries
all(filter_positive([-1, 2, -3, 4, -5], Result))

# Use inline Prolog for complex queries
query_prolog("""
  filter_positive([-1, 2, -3, 4, -5], PosList),
  sum_list(PosList, Sum),
  Sum > 5
""")
```

See `examples/hybrid_dsl_usage.exs` for comprehensive examples.

## API Reference

### One-Shot Queries

```elixir
# Execute a Prolog query
Swiex.MQI.query(prolog_query, opts \\ [])

# Options:
# - :host - Server host (default: {127, 0, 0, 1})
# - :timeout - Connection timeout in milliseconds (default: 5000)
```

### Session Management

```elixir
# Start a persistent session
{:ok, session} = Swiex.MQI.start_session(opts \\ [])

# Stop a session
Swiex.MQI.stop_session(session)
```

### Session-Based Operations

```elixir
# Query within a session
Swiex.MQI.query(session, prolog_query)

# Assert a Prolog clause
Swiex.MQI.assertz(session, "predicate(X, Y) :- condition(X), action(Y).")

# Consult Prolog code from a string
Swiex.MQI.consult_string(session, """
  factorial(0, 1).
  factorial(N, Result) :-
    N > 0,
    N1 is N - 1,
    factorial(N1, F1),
    Result is N * F1.
""")
```

### Utility Functions

```elixir
# Check if MQI server is available
Swiex.MQI.ping(opts \\ [])

# Execute async query (placeholder implementation)
{:ok, query_id} = Swiex.MQI.query_async(prolog_query)
```

## Examples

### DSL Usage

```bash
# Hybrid DSL examples (Elixir DSL + Inline Prolog)
mix run examples/hybrid_dsl_usage.exs

# Basic DSL examples
mix run examples/dsl_usage.exs

# Advanced features demo (Pin Operator, Streaming, Transactions)
mix run examples/advanced_features_demo.exs
```

### List Processing

```elixir
{:ok, session} = Swiex.MQI.start_session()

# Define a list processing predicate
Swiex.MQI.assertz(session, "double_list([], []).")
Swiex.MQI.assertz(session, "double_list([H|T], [H2|T2]) :- H2 is H * 2, double_list(T, T2).")

# Use it
case Swiex.MQI.query(session, "double_list([1,2,3], Result)") do
  {:ok, [%{"Result" => result}]} ->
    IO.inspect(result)  # [2, 4, 6]
end

Swiex.MQI.stop_session(session)
```

### Complex Logic

```elixir
{:ok, session} = Swiex.MQI.start_session()

# Define a family tree
Swiex.MQI.assertz(session, "parent(john, mary).")
Swiex.MQI.assertz(session, "parent(mary, bob).")
Swiex.MQI.assertz(session, "ancestor(X, Y) :- parent(X, Y).")
Swiex.MQI.assertz(session, "ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).")

# Query relationships
case Swiex.MQI.query(session, "ancestor(john, X)") do
  {:ok, results} ->
    IO.inspect(results)  # [%{"X" => "mary"}, %{"X" => "bob"}]
end

Swiex.MQI.stop_session(session)
```

## Phoenix Integration

See the `examples/phoenix_demo/` directory for a complete Phoenix application example that demonstrates:

- Web interface for Prolog queries
- Real-time query execution
- Session management in web context

## Advanced Features

### Pin Operator Support

The DSL supports variable interpolation using the pin operator (`^`):

```elixir
import Swiex.DSL

# Define a query with variables
member_ast = {:member, [], [{:^, [], [{:X, [], nil}]}, [1, 2, 3, 4, 5]]}

# Execute with bindings
case query_with_bindings(member_ast, [X: 3]) do
  {:ok, results} ->
    IO.inspect(results)  # [%{}] (ground query returns true)
  {:error, reason} ->
    IO.puts("Error: #{reason}")
end
```

### Streaming Results

Handle large datasets efficiently with streaming:

```elixir
import Swiex.Stream

# Stream results with custom chunk size
stream = query_stream("member(X, [1,2,3,4,5])", 2)

# Process results as they arrive
results = stream
  |> Stream.map(fn result -> result["X"] end)
  |> Stream.filter(fn x -> rem(x, 2) == 0 end)  # Only even numbers
  |> Enum.to_list()

IO.inspect(results)  # [2, 4]
```

### Transaction Support

Execute multiple operations atomically:

```elixir
import Swiex.Transaction

# Simple transaction
result = transaction(fn session ->
  Swiex.MQI.assertz(session, "person(alice, 28)")
  Swiex.MQI.assertz(session, "person(david, 32)")
  {:ok, "Both persons added"}
end)

# Batch operations
operations = [
  {"person(john, 30)", :assertz},
  {"person(jane, 25)", :assertz},
  {"person(john, Age)", :query}
]

case batch(operations) do
  {:ok, results} ->
    IO.inspect(results)
  {:error, reason} ->
    IO.puts("Error: #{reason}")
end
```
- Error handling and result display

## Error Handling

The library returns `{:error, reason}` for various error conditions:

- **Connection errors** - Network or authentication issues
- **Syntax errors** - Invalid Prolog syntax
- **Existence errors** - Undefined predicates
- **Protocol errors** - MQI communication issues

## Multi-Adapter Support

Swiex now supports multiple Prolog implementations through a unified adapter interface:

### Available Adapters

- **SWI-Prolog** (via MQI) - Full-featured, production-ready
- **Erlog** - Embedded Erlang-based Prolog (experimental)
- **Scryer Prolog** - ISO-compliant Prolog (experimental)

### Using Different Adapters

```elixir
# Use the default adapter (SWI-Prolog)
{:ok, results} = Swiex.Prolog.query("member(X, [1,2,3])")

# Specify a different adapter
{:ok, results} = Swiex.Prolog.query("member(X, [1,2,3])", adapter: Swiex.Adapters.ErlogAdapter)

# Start a session with a specific adapter
{:ok, session} = Swiex.Prolog.start_session(adapter: Swiex.Adapters.ScryerAdapter)

# Compare results across all adapters
results = Swiex.Prolog.query_all("member(X, [1,2,3])")
```

## Phoenix Demo Application

The `examples/phoenix_demo` directory contains a comprehensive web application showcasing Swiex capabilities:

### Features

- **Medical Causal Reasoning** - Interactive exploration of cause-effect relationships using CauseNet data
- **Constraint Solving** - N-Queens solver (returns all 92 solutions for 8-Queens), Sudoku solver with CLP(FD)
- **Prolog Playground** - Browser-based REPL with syntax highlighting
- **Multi-Adapter Comparison** - Side-by-side performance testing
- **Real-time Monitoring** - Live statistics dashboard for SWI-Prolog MQI sessions

### Running the Demo

```bash
cd examples/phoenix_demo
mix deps.get
mix phx.server
# Visit http://localhost:4000
```

## Architecture

### Core Architecture

Swiex uses a modular adapter-based architecture:

1. **Adapter Interface** - Common behavior for all Prolog implementations
2. **Session Management** - Persistent connections with automatic cleanup
3. **Monitoring** - Performance tracking and statistics collection
4. **Security** - Query validation and sanitization

### SWI-Prolog MQI Protocol

For SWI-Prolog specifically:

1. **Server Management** - Automatically starts `swipl mqi --write_connection_values=true`
2. **Connection Handling** - TCP socket communication with proper framing
3. **Message Protocol** - `<length>.\n<message>.\n` format as per MQI specification
4. **JSON Parsing** - Extracts variable bindings from MQI JSON responses

## Development

### Running Examples

```bash
# Basic usage examples
mix run examples/basic_usage.exs

# Phoenix demo
cd examples/phoenix_demo
mix deps.get
mix phx.server
```

### Testing

```bash
mix test
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## Acknowledgments

- SWI-Prolog team for the MQI protocol
- Elixir community for inspiration and tooling 