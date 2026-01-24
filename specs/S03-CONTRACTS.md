# S03 - Contracts: simple_toon

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_toon
**Date:** 2026-01-23

## SIMPLE_TOON Contracts

### Initialization

```eiffel
make
    ensure
        default_indent: indent = Default_indent
        default_delimiter: delimiter = Default_delimiter
        strict_by_default: is_strict
        no_errors: not has_errors
```

### Encoding

```eiffel
encode,
to_toon,
serialize,
compress_for_llm (a_json: SIMPLE_JSON_VALUE): STRING_32
    require
        json_not_void: a_json /= Void
    ensure
        result_attached: Result /= Void

encode_string,
json_to_toon (a_json_text: STRING_32): detachable STRING_32
    require
        not_empty: not a_json_text.is_empty
    ensure
        error_on_failure: Result = Void implies has_errors
```

### Decoding

```eiffel
decode,
from_toon,
deserialize,
parse_toon (a_toon_text: STRING_32): detachable SIMPLE_JSON_VALUE
    require
        not_empty: not a_toon_text.is_empty
    ensure
        errors_transferred: decoder.errors.count <= last_errors.count

decode_to_string,
toon_to_json (a_toon_text: STRING_32): detachable STRING_32
    require
        not_empty: not a_toon_text.is_empty
    ensure
        error_on_failure: Result = Void implies has_errors
```

### Configuration

```eiffel
set_indent (a_spaces: INTEGER)
    require
        positive: a_spaces > 0
    ensure
        indent_set: indent = a_spaces

set_delimiter (a_delimiter: CHARACTER_32)
    require
        valid_delimiter: a_delimiter = ',' or a_delimiter = '%T' or a_delimiter = '|'
    ensure
        delimiter_set: delimiter = a_delimiter

set_strict_mode,
set_strict (a_enabled: BOOLEAN)
    ensure
        strict_set: is_strict = a_enabled
```

### Analysis

```eiffel
token_estimate (a_json: SIMPLE_JSON_VALUE): TUPLE [json_tokens, toon_tokens: INTEGER]
    require
        json_not_void: a_json /= Void
    ensure
        result_attached: Result /= Void

compression_ratio (a_json: SIMPLE_JSON_VALUE): REAL_64
    require
        json_not_void: a_json /= Void
    ensure
        positive: Result >= 0.0
```

### File Operations

```eiffel
encode_file (a_json_path, a_toon_path: STRING_32): BOOLEAN
    require
        json_path_not_empty: not a_json_path.is_empty
        toon_path_not_empty: not a_toon_path.is_empty
    ensure
        error_on_failure: not Result implies has_errors

decode_file (a_toon_path, a_json_path: STRING_32): BOOLEAN
    require
        toon_path_not_empty: not a_toon_path.is_empty
        json_path_not_empty: not a_json_path.is_empty
    ensure
        error_on_failure: not Result implies has_errors
```

## Invariants

```eiffel
class SIMPLE_TOON
invariant
    valid_indent: indent > 0
    valid_delimiter: delimiter = ',' or delimiter = '%T' or delimiter = '|'
    errors_attached: last_errors /= Void
    error_consistency: has_errors = not last_errors.is_empty
    encoder_attached: encoder /= Void
    decoder_attached: decoder /= Void
end
```
