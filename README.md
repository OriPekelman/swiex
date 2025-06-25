# Swiex - SWI-Prolog MQI Client for Elixir

Swiex is an Elixir library that provides a client for SWI-Prolog's Machine Query Interface (MQI), allowing you to execute Prolog queries and define inline Prolog code directly from Elixir applications.

## Features

- **Full MQI Protocol Support** - Implements the official SWI-Prolog MQI protocol
- **Persistent Sessions** - Maintain stateful connections for complex workflows
- **Inline Prolog Code** - Define facts and rules on-the-fly using `assertz/1`
- **Variable Binding Extraction** - Clean map-based results with variable names
- **Phoenix Integration** - Ready-to-use examples for web applications

## Status: Pre-Alpha forever

This is a toy implementation built for weird reasons. I expect the performance to be horrendous; security to be inexistant; and the potential to summon evil spirits from another century to be very high.


## Installation

Add `swiex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:swiex, "~> 0.1.0"}
  ]
end
```

## Prerequisites

- [SWI-Prolog](https://www.swi-prolog.org/) must be installed and available in your PATH
- Test with: `swipl --version`

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
- Error handling and result display

## Error Handling

The library returns `{:error, reason}` for various error conditions:

- **Connection errors** - Network or authentication issues
- **Syntax errors** - Invalid Prolog syntax
- **Existence errors** - Undefined predicates
- **Protocol errors** - MQI communication issues

## Architecture

Swiex uses SWI-Prolog's official MQI protocol:

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