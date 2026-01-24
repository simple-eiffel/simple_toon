# S07 - Specification Summary: simple_toon

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_toon
**Date:** 2026-01-23

## Executive Summary

simple_toon is a TOON (Token-Oriented Object Notation) library for Eiffel, providing compact serialization that achieves 30-60% token reduction compared to JSON, optimized for LLM input.

## Key Statistics

| Metric | Value |
|--------|-------|
| Total Classes | 6 |
| Public Features | ~30 |
| LOC (estimated) | ~1000 |
| Dependencies | base, simple_json |

## Architecture Overview

```
+-------------------+
|   SIMPLE_TOON     |  <-- Facade
+-------------------+
         |
    +----+----+
    |         |
+--------+ +--------+
|Encoder | |Decoder |
+--------+ +--------+
    |         |
+---+---------+---+
| SIMPLE_JSON_VALUE|
+-----------------+
```

## Core Value Proposition

1. **Token Reduction** - 30-60% fewer tokens for LLMs
2. **Human Readable** - Clean, indented format
3. **Lossless** - Perfect JSON round-trip
4. **Semantic Aliases** - `encode`/`to_toon`/`compress_for_llm`
5. **DBC Validation** - Contract-enforced correctness

## Contract Summary

| Category | Preconditions | Postconditions |
|----------|---------------|----------------|
| Encoding | Non-void JSON | Non-void TOON |
| Decoding | Non-empty TOON | JSON or errors |
| Config | Valid values | State updated |
| Files | Paths not empty | Success or errors |

## Feature Categories

| Category | Count | Purpose |
|----------|-------|---------|
| Encoding | 6 | JSON to TOON |
| Decoding | 6 | TOON to JSON |
| Configuration | 4 | Indent, delimiter, strict |
| Analysis | 3 | Tokens, ratio, tabular |
| Errors | 6 | Error handling |
| Files | 2 | File operations |

## Constraints Summary

1. Indent must be > 0 (default 2)
2. Delimiter: comma, tab, or pipe
3. No tabs for indentation
4. UTF-8 encoding always
5. Five escape sequences only

## Known Limitations

1. Full document required (no streaming)
2. No schema validation
3. No comments support
4. No custom type extensions

## Integration Points

| Library | Integration |
|---------|-------------|
| simple_json | Internal representation |
| simple_ai_client | LLM API payloads |
| simple_http | API request/response |

## Future Directions

1. Streaming encoder/decoder
2. Schema-aware encoding
3. Custom type handlers
4. TOON diff/patch
