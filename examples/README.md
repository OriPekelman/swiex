# Swiex Examples

This directory contains usage examples for the different Prolog adapters available in the Swiex ecosystem. Swiex provides a unified interface to multiple Prolog implementations, each with different capabilities and use cases.

## 🧠 Available Prolog Adapters

| Adapter | Description | Capabilities | Architecture |
|---------|-------------|--------------|--------------|
| **SWI-Prolog** | Industry standard | Full Prolog features | External process (MQI) |
| **Scryer Prolog** | Modern, ISO-compliant | Rich Prolog subset | External process (subprocess) |
| **Erlog** | Embedded interpreter | Basic logic queries | Embedded Erlang/Elixir |

## 📁 Directory Structure

```
examples/
├── erlog_examples/           # Erlog adapter examples
│   ├── basic_queries.exs     # Basic Erlog usage
│   └── adapter_comparison.exs # Compare with other adapters
├── scryer_examples/          # Scryer Prolog examples  
│   ├── basic_queries.exs     # Basic Scryer usage
│   ├── advanced_features.exs # Advanced Prolog features
│   ├── performance_demo.exs  # Performance benchmarking
│   └── module_system.exs     # Module loading and built-ins
├── phoenix_demo/             # Full Phoenix LiveView demo
│   └── ...                   # Interactive web interface
└── README.md                 # This file
```

## 🚀 Getting Started

### Prerequisites

1. **Elixir/Erlang**: Install Elixir and Erlang
2. **SWI-Prolog**: Install SWI-Prolog for the SwiAdapter
3. **Scryer Prolog**: Install Scryer Prolog for the ScryerAdapter
4. **Erlog**: Available only in the phoenix_demo project

### Installation

```bash
# Clone the repository
git clone https://github.com/your-org/swiex
cd swiex

# Install dependencies
mix deps.get

# Compile the project
mix compile
```

### Installing Prolog Implementations

#### SWI-Prolog
```bash
# macOS
brew install swi-prolog

# Ubuntu/Debian  
sudo apt-get install swi-prolog

# Or download from: https://www.swi-prolog.org/
```

#### Scryer Prolog
```bash
# Install Rust first
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install Scryer Prolog
cargo install scryer-prolog

# Or download from: https://github.com/mthom/scryer-prolog
```

#### Erlog
Erlog is included as a dependency in the Phoenix demo project and doesn't require separate installation.

## 🔍 Running Examples

### Erlog Examples

```bash
# Navigate to the phoenix_demo directory (where Erlog is available)
cd examples/phoenix_demo

# Run basic Erlog examples
elixir -S mix run ../../erlog_examples/basic_queries.exs

# Compare adapters
elixir -S mix run ../../erlog_examples/adapter_comparison.exs
```

### Scryer Prolog Examples

```bash
# Basic usage examples
elixir scryer_examples/basic_queries.exs

# Advanced features
elixir scryer_examples/advanced_features.exs

# Performance benchmarking
elixir scryer_examples/performance_demo.exs
```

### Phoenix Demo

```bash
# Start the interactive web demo
cd examples/phoenix_demo
mix phx.server

# Visit http://localhost:4000/causenet/adapters
# Compare all three adapters side-by-side
```

## 📊 Adapter Comparison

### 🥇 SWI-Prolog (Full-Featured)
- **Strengths**: Complete Prolog implementation, extensive libraries
- **Use Cases**: Production Prolog applications, research, education
- **Performance**: Excellent for complex logic programming
- **Dependencies**: Requires SWI-Prolog installation

```elixir
# Example: Advanced logic programming
{:ok, session} = SwiAdapter.start_session()
SwiAdapter.query(session, "findall(X, member(X, [1,2,3]), L)")
```

### 🥈 Scryer Prolog (Modern & Fast) 
- **Strengths**: ISO-compliant, excellent performance, modern codebase
- **Use Cases**: Modern Prolog applications, education, performance-critical
- **Performance**: Very fast, Rust implementation
- **Dependencies**: Requires Scryer Prolog installation

```elixir
# Example: Fast arithmetic and recursion with modules
{:ok, session} = ScryerAdapter.start_session()
ScryerAdapter.query(session, "use_module(library(lists))")  # Load list predicates
ScryerAdapter.assertz(session, "factorial(N, F) :- N > 0, N1 is N - 1, factorial(N1, F1), F is N * F1")
ScryerAdapter.query(session, "factorial(10, X)")
```

### 🥉 Erlog (Embedded & Simple)
- **Strengths**: No external dependencies, embedded in Elixir
- **Use Cases**: Simple logic validation, embedded systems
- **Performance**: Good for basic queries
- **Dependencies**: None (Erlang/Elixir only)

```elixir
# Example: Basic embedded logic
{:ok, session} = ErlogAdapter.start_session()
ErlogAdapter.query(session, "true")  # Works
ErlogAdapter.query(session, "complex_query(X)") # Returns :unsupported
```

## 🎯 Use Case Guidelines

### Choose **SWI-Prolog** when:
- You need full Prolog compatibility
- Working with existing Prolog codebases
- Require extensive Prolog libraries
- Building complex logic applications

### Choose **Scryer Prolog** when:
- You want modern, fast Prolog
- Performance is important
- You prefer ISO-compliant implementations
- Building new Prolog applications

### Choose **Erlog** when:
- You need embedded logic capabilities
- External dependencies are not allowed
- Only basic logical queries are needed
- Working in constrained environments

## 🧪 Example Highlights

### Erlog Examples
- **basic_queries.exs**: Demonstrates Erlog's limited but useful capabilities
- **adapter_comparison.exs**: Side-by-side comparison with other adapters

### Scryer Examples
- **basic_queries.exs**: Arithmetic, variables, facts, and queries
- **advanced_features.exs**: Recursion, lists, family relations, mathematical sequences
- **performance_demo.exs**: Benchmarking and performance analysis
- **module_system.exs**: Module loading, built-in predicates, and library usage

### Phoenix Demo
- **Interactive Web Interface**: Compare all adapters in real-time
- **CauseNet Dataset**: Explore causal relationships with Prolog
- **Sudoku Solver**: Constraint logic programming example
- **N-Queens**: Classic Prolog problem demonstration

## 🔧 Scryer Prolog Module System

Scryer Prolog follows ISO Prolog standards and uses a module system for organizing predicates. Many built-in predicates require explicit module loading:

### Loading Modules
```elixir
# Load the lists library
ScryerAdapter.query(session, "use_module(library(lists))")

# Now you can use list predicates
ScryerAdapter.query(session, "member(2, [1,2,3])")
ScryerAdapter.query(session, "is_list([1,2,3])")
```

### Common Modules
- **`library(lists)`**: List predicates (`member/2`, `append/3`, `is_list/1`)
- **`library(arithmetic)`**: Extended arithmetic (`succ/2`, `plus/3`, `between/3`)  
- **`library(format)`**: Formatted output predicates
- **`library(dcgs)`**: Definite Clause Grammars
- **`library(iso_ext)`**: ISO extensions

### Built-in Predicates (No Module Needed)
- Type checking: `atom/1`, `number/1`, `var/1`, `nonvar/1`
- Arithmetic: `is/2`, `>/2`, `</2`, `=:=/2`, `=\=/2`
- Unification: `=/2`, `\=/2`
- Control: `true/0`, `false/0`, `!/0`

## 🔧 Development

### Adding New Examples

1. Create a new `.exs` file in the appropriate directory
2. Add the Swiex path: `Code.prepend_path("../../_build/dev/lib/swiex/ebin")`
3. Import the relevant adapter: `alias Swiex.Adapters.YourAdapter`
4. Follow the existing example patterns
5. Update this README with your new example

### Testing Examples

```bash
# Test all examples
./scripts/test_examples.sh

# Test specific adapter
elixir scryer_examples/basic_queries.exs
```

## 📚 Further Reading

- [Swiex Documentation](../README.md)
- [SWI-Prolog Documentation](https://www.swi-prolog.org/pldoc/)
- [Scryer Prolog Documentation](https://github.com/mthom/scryer-prolog)
- [Erlog Documentation](https://github.com/rvirding/erlog)
- [Phoenix LiveView Documentation](https://hexdocs.pm/phoenix_live_view/)

## 🤝 Contributing

We welcome contributions to the examples! Please:

1. Follow the existing code style
2. Add comprehensive comments
3. Include error handling
4. Update documentation
5. Test your examples

## 📄 License

These examples are part of the Swiex project and are licensed under the same terms as the main project.

---

**Happy Prolog Programming! 🧠✨**