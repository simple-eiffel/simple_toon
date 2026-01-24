# S06 - Boundaries: simple_toon

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_toon
**Date:** 2026-01-23

## Scope Boundaries

### In Scope
- JSON to TOON encoding
- TOON to JSON decoding
- Configurable indentation
- Configurable delimiters (comma, tab, pipe)
- Strict mode validation
- Tabular array detection
- Token estimation
- Compression ratio calculation
- File operations

### Out of Scope
- **Schema validation** - No JSON Schema support
- **Streaming** - Full document required
- **Binary format** - Text only
- **Custom types** - JSON types only
- **Comments** - Not supported in TOON spec
- **Incremental updates** - Full re-encode required

## API Boundaries

### Public API (SIMPLE_TOON facade)
- All encoding methods (with aliases)
- All decoding methods (with aliases)
- Configuration methods
- Analysis methods
- Error handling
- File operations

### Internal API (not exported)
- Encoder implementation details
- Decoder state machine
- Token estimation heuristics

## Integration Boundaries

### Input Boundaries

| Input Type | Format | Validation |
|------------|--------|------------|
| JSON value | SIMPLE_JSON_VALUE | Non-void |
| JSON string | STRING_32 | Non-empty, valid JSON |
| TOON string | STRING_32 | Non-empty |
| Indent | INTEGER | > 0 |
| Delimiter | CHARACTER_32 | , or %T or | |

### Output Boundaries

| Output Type | Format | Notes |
|-------------|--------|-------|
| TOON string | STRING_32 | UTF-32 |
| JSON value | SIMPLE_JSON_VALUE | May be Void on error |
| JSON string | STRING_32 | May be Void on error |
| Errors | LIST [ERROR] | Position info included |

## Performance Boundaries

### Expected Performance

| Operation | Time Complexity | Notes |
|-----------|-----------------|-------|
| Encode | O(n) | n = JSON nodes |
| Decode | O(n) | n = TOON lines |
| Token estimate | O(n) | n = string length |

### Size Expectations

| Data Type | TOON/JSON Ratio |
|-----------|-----------------|
| Simple objects | 0.7 - 0.8 |
| Primitive arrays | 0.6 - 0.7 |
| Tabular arrays | 0.4 - 0.5 |
| Nested structures | 0.7 - 0.9 |

## Extension Points

### Custom Encoding
- No extension mechanism
- Use TOON_BUILDER for programmatic generation

### Error Handling
- All errors collected in list
- Access via `last_errors`

## Dependency Boundaries

### Required Dependencies
- EiffelBase
- simple_json (SIMPLE_JSON_VALUE)

### No External Dependencies
- Pure Eiffel implementation
- No C code required

## Interoperability

### Compatible Formats
- JSON (lossless round-trip)
- TOON spec v3.0 compliant

### TOON Ecosystem
- Reference: @toon-format/toon (TypeScript)
- Python: python-toon
- Rust: toon-format
- Go: toon-go
