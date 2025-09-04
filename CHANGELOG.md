# Changelog

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
  - `all/1` function for multiple solutions
  - `one/1` function for first solution
  - `solutions/1` and `solutions/2` functions with optional limits
  - `query/1` macro for natural syntax
  - `Transform` module for Elixir-to-Prolog conversion
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