# Changelog

All notable changes to simple_toon will be documented in this file.

## [1.1.0] - 2025-12-16

### Added
- **TOON_BUILDER**: Fluent API for direct TOON construction without JSON intermediary
  - Scalar values: `add_string`, `add_integer`, `add_real`, `add_boolean`, `add_null`
  - Tabular arrays: `start_array`/`row`/`end_array` with column headers
  - Nested objects: `start_object`/`end_object`
  - Simple arrays: `add_string_array`, `add_integer_array`
  - Configuration: `set_indent`, `set_delimiter`, `reset`
- **Cookbook documentation** (`docs/cookbook.html`): Complex real-world examples, format guide, best practices
- 10 new tests for TOON_BUILDER (35 total)

### Changed
- Updated README with builder examples and cookbook link

## [1.0.0] - 2025-12-14

### Added
- Initial release
- TOON encoder: Convert JSON to compact TOON format
- TOON decoder: Convert TOON back to JSON
- Tabular array support for uniform object arrays
- Configurable indentation and delimiters (comma, tab, pipe)
- Strict validation mode with detailed error reporting
- Compression ratio and token estimation utilities
- Integration with simple_decimal for exact number handling
- 25 comprehensive tests
