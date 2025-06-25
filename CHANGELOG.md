# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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