# Changelog

## [0.3.0] - 2025-01-09

### Added
- **Multi-Adapter Architecture**: Support for multiple Prolog implementations
  - SWI-Prolog adapter via MQI protocol (full-featured)
  - Erlog adapter for embedded Erlang-based Prolog (experimental)
  - Scryer Prolog adapter (experimental)
  - Unified `Swiex.Prolog` module for adapter-agnostic operations
  - Runtime adapter switching and comparison capabilities
- **Monitoring Module**: New `Swiex.Monitoring` module for performance tracking
  - Query execution monitoring with timing and inference counting
  - Session-level statistics aggregation
  - Real-time monitoring dashboard for Phoenix applications
- **Phoenix Demo Application**: Comprehensive showcase of Swiex capabilities
  - **CauseNet Integration**: Real-world causal reasoning with medical data
    - Interactive causal path exploration
    - Medical diagnosis simulation
    - Bidirectional search capabilities
  - **Constraint Solving Demos**:
    - N-Queens solver with all 92 solutions for 8-Queens
    - Sudoku solver with CLP(FD) integration
    - Elixir-Prolog hybrid puzzle generation
  - **Prolog Playground**: Interactive REPL in web browser
  - **Multi-Adapter Comparison**: Side-by-side adapter performance testing
  - **SWI-Prolog MQI Monitoring Dashboard**: Real-time session statistics
- **Improved Test Suite**:
  - Comprehensive MQI protocol tests
  - Adapter-specific test suites
  - Better error handling and skip documentation
  - Fixed concurrent test issues with proper isolation

### Changed
- **MQI Module Enhancements**:
  - Better session management with automatic cleanup
  - Improved error handling and recovery
  - Enhanced logging and debugging capabilities
  - Support for async operations (experimental)
- **Project Structure**:
  - Modular adapter architecture
  - Clear separation of concerns between adapters
  - Improved documentation and examples

### Fixed
- **Test Reliability**: 
  - Fixed ErlogAdapter test error format expectations
  - Resolved compound term format issues in MQI tests
  - Properly skipped unreliable concurrent tests with documentation
  - Fixed memory leak test hanging issues
- **N-Queens Solver**: Fixed artificial 10-solution limit, now returns all 92 solutions for 8-Queens
- **Monitoring Display**: Simplified and improved monitoring dashboard with real-time updates

### Examples
- **Phoenix Demo**: Full-featured web application at `examples/phoenix_demo/`
  - Medical causal reasoning with CauseNet data
  - Interactive constraint solving (N-Queens, Sudoku)
  - Prolog playground with syntax highlighting
  - Multi-adapter comparison interface
  - Real-time monitoring dashboard

## [0.2.0] - 2024-12-19

### Added
- **Security Module**: New `Swiex.Security` module for query sanitization and validation
  - Query size limits and dangerous pattern detection
  - Input validation before query execution
- **DSL Module**: New `Swiex.DSL` module for elegant query construction
  - **Elixir DSL**: Natural Elixir syntax for simple queries
    - `all/1` function for multiple solutions
    - `one/1` function for first solution
    - `solutions/1` and `solutions/2` functions with optional limits
    - `query/1` function for natural syntax
  - **Inline Prolog**: Direct Prolog code embedded in Elixir
    - `prolog/1` macro for defining Prolog predicates inline
    - `query_prolog/1` for executing raw Prolog queries
    - `query_prolog_one/1` for first solution from raw Prolog
    - `query_prolog_solutions/2` for limited solutions from raw Prolog
  - **Transform** module for Elixir-to-Prolog conversion
  - **Pin Operator Support**: Enhanced DSL with variable interpolation using `^` operator
    - `query_with_bindings/2` function for executing queries with variable bindings
    - Support for `^var` syntax in DSL queries
- **Streaming Module**: New `Swiex.Stream` module for handling large result sets
  - `query_stream/2` for streaming query results with configurable chunk sizes
  - `query_stream_with_bindings/3` for streaming DSL queries with bindings
  - Efficient memory usage for large datasets
- **Transaction Module**: New `Swiex.Transaction` module for atomic operations
  - `transaction/1` function for executing operations within a session
  - `batch/1` function for executing multiple operations atomically
  - Automatic session management and cleanup
- **Enhanced Resource Management**: Improved port cleanup and error handling
  - Proper try/after blocks for resource cleanup
  - Enhanced timeout handling with configurable timeouts
  - Better error types including `:query_timeout` and `{:security_error, reason}`
- **Security Integration**: Security validation integrated into MQI operations
  - All queries validated before execution
  - `assertz/2` operations validated for security
  - Comprehensive test coverage for security features

### Changed
- **MQI Module**: Enhanced with security validation and better error handling
  - Resource cleanup now guaranteed in all code paths
  - Timeout handling improved with `recv_response/2`
  - Security validation integrated into `query/2` and `assertz/2`

### Examples
- **New DSL Examples**: `examples/dsl_usage.exs` demonstrating new DSL features
- **Hybrid DSL Examples**: `examples/hybrid_dsl_usage.exs` showing both Elixir DSL and inline Prolog approaches
- **Security Examples**: Examples showing security features in action
- **Advanced Features Demo**: `examples/advanced_features_demo.exs` showcasing pin operator, streaming, and transaction features

### Security
- **Query Validation**: All queries validated for size limits and dangerous patterns
- **Injection Prevention**: Protection against Prolog injection attacks
- **Input Sanitization**: Proper escaping of special characters

### Testing
- **Security Tests**: `test/security_test.exs` for security module functionality
- **Security Integration Tests**: `test/security_integration_test.exs` for MQI integration
- **DSL Tests**: `test/dsl_test.exs` for DSL and Transform modules
- **Stream Tests**: `test/stream_test.exs` for streaming functionality
- **Transaction Tests**: `test/transaction_test.exs` for transaction support
- **Enhanced Coverage**: All existing tests updated and passing

## [0.1.0] - 2024-12-19

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Security Module**: New `Swiex.Security` module for query sanitization and validation
  - Query size limits (10KB max)
  - Dangerous pattern detection (halt, shell, system, etc.)
  - Special character escaping for Prolog strings
  - Input validation before query execution
- **DSL Module**: New `Swiex.DSL` module for elegant query construction
  - **Elixir DSL**: Natural Elixir syntax for simple queries
    - `all/1` function for multiple solutions
    - `one/1` function for first solution
    - `solutions/1` and `solutions/2` functions with optional limits
    - `query/1` function for natural syntax
  - **Inline Prolog**: Direct Prolog code embedded in Elixir
    - `prolog/1` macro for defining Prolog predicates inline
    - `query_prolog/1` for executing raw Prolog queries
    - `query_prolog_one/1` for first solution from raw Prolog
    - `query_prolog_solutions/2` for limited solutions from raw Prolog
  - **Transform** module for Elixir-to-Prolog conversion
- **Enhanced Resource Management**: Improved port cleanup and error handling
  - Proper try/after blocks for resource cleanup
  - Consistent port and socket cleanup in all error paths
  - Better timeout handling with configurable timeouts
- **Security Integration**: All queries now validated through security module
  - Automatic rejection of dangerous queries
  - Protection against injection attacks
  - Secure handling of user input

### Changed
- **MQI Module**: Enhanced with security validation and better error handling
  - All queries now validated before execution
  - Improved timeout handling with `:query_timeout` error type
  - Better resource cleanup in error scenarios
- **Error Types**: New security error types for better error handling
  - `{:security_error, :potentially_dangerous_query}`
  - `{:security_error, :query_too_large}`
  - `{:security_error, :invalid_query_type}`

### Security
- **Query Validation**: All Prolog queries now validated for security
- **Input Sanitization**: Automatic escaping of special characters
- **Pattern Blocking**: Rejection of potentially dangerous Prolog predicates
- **Size Limits**: Protection against oversized queries

### Examples
- **New DSL Examples**: `examples/dsl_usage.exs` demonstrating new DSL features
- **Hybrid DSL Examples**: `examples/hybrid_dsl_usage.exs` showing both Elixir DSL and inline Prolog approaches
- **Security Examples**: Examples showing security features in action

## [0.1.0] - 2024-01-XX

### Added
- Initial release of Swiex
- Full SWI-Prolog MQI protocol implementation
- Persistent session management
- Inline Prolog code support via `assertz/1` and `consult_string/1`
- Variable binding extraction with clean map-based results
- Phoenix integration example
- Comprehensive test suite covering various Prolog data types
- Support for compound queries, error handling, and complex data structures
- Automatic MQI server management
- Robust connection handling with proper timeout and error recovery

### Features
- One-shot queries for simple operations
- Session-based workflows for complex logic
- Support for Prolog tuples, lists, dicts, booleans, and nil values
- Proper escaping and quoting for Prolog strings and atoms
- Integration with Phoenix web applications
- Comprehensive error handling for connection, syntax, and protocol errors

### Technical Details
- Uses SWI-Prolog's official MQI protocol
- TCP socket communication with proper message framing
- JSON parsing for variable binding extraction
- Automatic server startup and connection management
- Process dictionary-based session persistence for stateless operations 