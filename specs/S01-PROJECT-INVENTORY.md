# S01 - Project Inventory: simple_toon

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_toon
**Version:** 1.0
**Date:** 2026-01-23

## Overview

TOON (Token-Oriented Object Notation) encoder/decoder for Eiffel. A compact, LLM-optimized serialization format achieving 30-60% token reduction compared to JSON.

## Project Files

### Core Source Files
| File | Purpose |
|------|---------|
| `src/core/simple_toon.e` | Main facade class |
| `src/core/simple_toon_constants.e` | Format constants and defaults |
| `src/core/simple_toon_error.e` | Error representation |
| `src/core/toon_builder.e` | Fluent TOON construction |

### Encoder Source Files
| File | Purpose |
|------|---------|
| `src/encoder/simple_toon_encoder.e` | JSON to TOON conversion |

### Decoder Source Files
| File | Purpose |
|------|---------|
| `src/decoder/simple_toon_decoder.e` | TOON to JSON parsing |

### Configuration Files
| File | Purpose |
|------|---------|
| `simple_toon.ecf` | EiffelStudio project configuration |
| `simple_toon.rc` | Windows resource file |
| `CHANGELOG.md` | Version history |

### Test Files
| File | Purpose |
|------|---------|
| `tests/` | Conformance test fixtures |

## Dependencies

### ISE Libraries
- base (core Eiffel classes)

### simple_* Libraries
- simple_json (SIMPLE_JSON_VALUE for internal representation)

## Build Targets
- `simple_toon` - Main library
- `simple_toon_tests` - Test suite
