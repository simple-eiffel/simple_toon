# S02 - Class Catalog: simple_toon

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_toon
**Date:** 2026-01-23

## Class Hierarchy

```
SIMPLE_TOON (facade)
|
+-- SIMPLE_TOON_CONSTANTS (inherited)
|
+-- SIMPLE_TOON_ENCODER
|
+-- SIMPLE_TOON_DECODER
|
+-- SIMPLE_TOON_ERROR
|
+-- TOON_BUILDER (fluent)
```

## Class Descriptions

### SIMPLE_TOON (Facade)
Main entry point for TOON encoding and decoding. Provides multiple semantic aliases for operations.

**Creation:** `make`

**Key Features:**
- `encode` / `to_toon` / `serialize` / `compress_for_llm`
- `decode` / `from_toon` / `deserialize` / `parse_toon`
- Configuration: indent, delimiter, strict mode
- Analysis: token estimation, compression ratio

### SIMPLE_TOON_CONSTANTS
Inherited constants for TOON format:
- Default indent (2 spaces)
- Default delimiter (comma)
- Valid delimiters (comma, tab, pipe)

### SIMPLE_TOON_ENCODER
Internal class handling JSON to TOON conversion:
- Primitive value encoding
- Object encoding (key: value)
- Array encoding with [N] notation
- Tabular array detection and formatting

### SIMPLE_TOON_DECODER
Internal class handling TOON to JSON parsing:
- Line-by-line parsing
- Indentation tracking
- Primitive array parsing
- Tabular row parsing
- Error collection

### SIMPLE_TOON_ERROR
Error representation with:
- Message
- Line number
- Column number
- Error type (syntax, delimiter, count_mismatch)

### TOON_BUILDER
Fluent builder for TOON construction (programmatic generation).

## Class Count Summary
- Facade: 1
- Constants: 1
- Encoder: 1
- Decoder: 1
- Error: 1
- Builder: 1
- **Total: 6 classes**
