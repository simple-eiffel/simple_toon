<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/claude_eiffel_op_docs/main/artwork/LOGO.png" alt="simple_toon logo" width="400">
</p>

# simple_toon

**[Documentation](https://simple-eiffel.github.io/simple_toon/)** | **[GitHub](https://github.com/simple-eiffel/simple_toon)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Eiffel](https://img.shields.io/badge/Eiffel-25.02-blue.svg)](https://www.eiffel.org/)
[![Design by Contract](https://img.shields.io/badge/DbC-enforced-orange.svg)]()
[![SCOOP](https://img.shields.io/badge/SCOOP-compatible-orange.svg)]()

TOON (Token-Oriented Object Notation) encoder/decoder for Eiffel. Reduces LLM token usage by 30-60%.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

**Production** - 25 tests passing

## Overview

TOON is a compact, human-readable format that encodes JSON with minimal quoting and explicit structure, designed specifically for LLM input optimization. simple_toon provides seamless conversion between JSON and TOON formats.

```eiffel
local
    toon: SIMPLE_TOON
    json: SIMPLE_JSON
    value: SIMPLE_JSON_VALUE
    toon_text: STRING_32
do
    create toon.make
    create json

    -- Parse JSON and convert to TOON
    value := json.parse ("{%"name%": %"Alice%", %"items%": [{%"sku%": %"A1%", %"qty%": 10}]}")
    toon_text := toon.encode (value)
    -- Result:
    -- name: Alice
    -- items[1]{sku,qty}:
    --   A1,10

    -- Convert back to JSON
    value := toon.decode (toon_text)
end
```

## Features

- **30-60% Token Reduction**: Eliminates JSON's verbose syntax (braces, quotes, repeated keys)
- **Tabular Arrays**: Uniform object arrays encoded as compact tables with headers
- **Lossless Round-trip**: Convert JSON to TOON and back without data loss
- **Configurable**: Adjustable indentation and delimiters (comma, tab, pipe)
- **Strict Validation**: Optional strict mode with detailed error reporting
- **Token Statistics**: Estimate token counts and compression ratios
- **Decimal Precision**: Integrates with simple_decimal for exact number handling (no floating-point artifacts)
- **Design by Contract**: Full precondition/postcondition/invariant coverage

## TOON Format Examples

**JSON:**
```json
{"name": "Alice", "age": 30, "active": true}
```

**TOON:**
```
name: Alice
age: 30
active: true
```

**Tabular Arrays - JSON:**
```json
[{"sku": "A1", "qty": 10}, {"sku": "B2", "qty": 20}]
```

**Tabular Arrays - TOON:**
```
[2]{sku,qty}:
  A1,10
  B2,20
```

## Installation

1. Set environment variable:
```bash
export SIMPLE_TOON=/path/to/simple_toon
```

2. Add to ECF:
```xml
<library name="simple_toon" location="$SIMPLE_TOON/simple_toon.ecf"/>
```

## Dependencies

- simple_json
- simple_decimal

## API Quick Reference

### Encoding (JSON to TOON)

```eiffel
toon.encode (json_value)           -- SIMPLE_JSON_VALUE to TOON string
toon.json_to_toon (json_string)    -- JSON string to TOON string
toon.encode_file (json_path, toon_path)  -- File conversion
```

### Decoding (TOON to JSON)

```eiffel
toon.decode (toon_string)          -- TOON string to SIMPLE_JSON_VALUE
toon.toon_to_json (toon_string)    -- TOON string to JSON string
toon.decode_file (toon_path, json_path)  -- File conversion
```

### Configuration

```eiffel
toon.set_indent (4)                -- Spaces per level (default: 2)
toon.set_delimiter ('%T')          -- Tab delimiter (default: comma)
toon.set_strict_mode (True)        -- Enable validation
```

### Analysis

```eiffel
toon.is_tabular_eligible (value)   -- Would benefit from tabular format?
toon.compression_ratio (value)     -- Token savings ratio
toon.token_estimate (value)        -- [json_tokens, toon_tokens]
```

## When to Use TOON

**Best for:**
- Uniform arrays of objects (product lists, user records)
- Flat or shallow nested structures
- LLM prompt context optimization

**Consider JSON for:**
- Deeply nested structures
- Non-uniform data
- LLM output (most models trained on JSON)

## License

MIT License
