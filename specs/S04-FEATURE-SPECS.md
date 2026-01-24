# S04 - Feature Specifications: simple_toon

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_toon
**Date:** 2026-01-23

## Core Features

### SIMPLE_TOON (Facade)

| Feature | Signature | Description |
|---------|-----------|-------------|
| `make` | `()` | Create with defaults |
| `encode` | `(json: SIMPLE_JSON_VALUE): STRING_32` | JSON to TOON |
| `to_toon` | `(json: SIMPLE_JSON_VALUE): STRING_32` | Alias for encode |
| `serialize` | `(json: SIMPLE_JSON_VALUE): STRING_32` | Alias for encode |
| `compress_for_llm` | `(json: SIMPLE_JSON_VALUE): STRING_32` | Alias for encode |
| `encode_string` | `(json_text: STRING_32): STRING_32` | Parse and encode |
| `json_to_toon` | `(json_text: STRING_32): STRING_32` | Alias |
| `decode` | `(toon: STRING_32): SIMPLE_JSON_VALUE` | TOON to JSON |
| `from_toon` | `(toon: STRING_32): SIMPLE_JSON_VALUE` | Alias for decode |
| `deserialize` | `(toon: STRING_32): SIMPLE_JSON_VALUE` | Alias for decode |
| `parse_toon` | `(toon: STRING_32): SIMPLE_JSON_VALUE` | Alias for decode |
| `decode_to_string` | `(toon: STRING_32): STRING_32` | Decode to JSON string |
| `toon_to_json` | `(toon: STRING_32): STRING_32` | Alias |
| `set_indent` | `(spaces: INTEGER)` | Set indentation |
| `set_delimiter` | `(delim: CHARACTER_32)` | Set array delimiter |
| `set_strict_mode` | `(enabled: BOOLEAN)` | Enable validation |
| `indent` | `: INTEGER` | Current indent |
| `delimiter` | `: CHARACTER_32` | Current delimiter |
| `is_strict` | `: BOOLEAN` | Strict mode? |
| `is_valid_toon` | `(text: STRING_32): BOOLEAN` | Validate syntax |
| `token_estimate` | `(json: JSON_VALUE): TUPLE` | Token counts |
| `compression_ratio` | `(json: JSON_VALUE): REAL_64` | TOON/JSON ratio |
| `is_tabular_eligible` | `(json: JSON_VALUE): BOOLEAN` | Tabular check |
| `has_errors` | `: BOOLEAN` | Errors present? |
| `last_errors` | `: LIST [SIMPLE_TOON_ERROR]` | Error list |
| `error_count` | `: INTEGER` | Number of errors |
| `first_error` | `: SIMPLE_TOON_ERROR` | First error |
| `errors_as_string` | `: STRING_32` | Formatted errors |
| `clear_errors` | `()` | Reset errors |
| `encode_file` | `(json_path, toon_path: STRING): BOOLEAN` | Convert file |
| `decode_file` | `(toon_path, json_path: STRING): BOOLEAN` | Convert file |

## TOON Format Examples

### Simple Object
```
JSON:  {"name": "Alice", "age": 30}
TOON:  name: Alice
       age: 30
```

### Primitive Array
```
JSON:  {"tags": ["admin", "ops", "dev"]}
TOON:  tags[3]: admin,ops,dev
```

### Tabular Array
```
JSON:  {"items": [{"sku": "A1", "price": 9.99}, {"sku": "B2", "price": 14.50}]}
TOON:  items[2]{sku,price}:
         A1,9.99
         B2,14.5
```

### Nested Objects
```
JSON:  {"user": {"name": "Bob", "address": {"city": "NYC"}}}
TOON:  user:
         name: Bob
         address:
           city: NYC
```

## Delimiter Options

| Delimiter | Character | Best For |
|-----------|-----------|----------|
| Comma | `,` | Default, most data |
| Tab | `%T` | Tabular data, TSV style |
| Pipe | `|` | Data with commas |

## Token Estimation

Approximates GPT-4 tokenizer:
- ~4 characters per token
- +1 token per punctuation: `{}[]:,`
- TOON reduces punctuation significantly
