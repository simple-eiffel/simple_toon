# S05 - Constraints: simple_toon

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_toon
**Date:** 2026-01-23

## Format Constraints

### Indentation
```
Default: 2 spaces per level
Minimum: 1 space
Tabs: NOT allowed for indentation (spec requirement)
Trailing spaces: NOT allowed
Trailing newline at EOF: NOT allowed
```

### Delimiters
```eiffel
Valid delimiters: ',' | '%T' | '|'
Default: ','
```

### String Quoting Requirements

Strings MUST be quoted if they:
- Are empty
- Have leading/trailing whitespace
- Equal `true`, `false`, or `null`
- Match numeric patterns
- Contain leading zeros
- Contain: `:` `"` `\` `[` `]` `{` `}`
- Include control characters
- Contain the active delimiter
- Start with hyphen `-`

### Escape Sequences
Only five escapes permitted (TOON spec 7.1):
```
\\  - backslash
\"  - double quote
\n  - newline
\r  - carriage return
\t  - tab
```

## Array Constraints

### Primitive Arrays
```
Format: key[N]: value1,value2,...,valueN
N must equal actual element count (strict mode)
```

### Tabular Arrays
```
Format: key[N]{field1,field2,...}:
          val1,val2,...
          ...
All rows must have same field count
```

### Objects as List Items
```
Format: key[N]:
          - field: value
            ...
          - field: value
            ...
```

## Strict Mode Constraints

When `is_strict = True`:
- Array count must match actual elements
- Delimiter must be consistent
- All quoting rules enforced
- Detailed error positions reported

When `is_strict = False`:
- Lenient parsing
- Count mismatches tolerated
- Fewer errors reported

## Encoding Constraints

### UTF-8 Required
- Input: STRING_32 (UTF-32 in Eiffel)
- Output: UTF-8 encoded
- Always: UTF-8 encoding (spec requirement)

### Round-Trip Guarantee
```eiffel
-- For valid JSON:
decode (encode (json)).is_equal (json)
```

## Error Constraints

### Error Information
```eiffel
SIMPLE_TOON_ERROR:
  message: STRING_32  -- Human-readable
  line: INTEGER       -- 1-based line number
  column: INTEGER     -- 1-based column
  error_type: INTEGER -- Syntax, delimiter, count
```

### Error Types
| Type | Description |
|------|-------------|
| Syntax | Invalid TOON syntax |
| Delimiter | Wrong delimiter used |
| Count mismatch | Array count != elements |
| Quote required | Unquoted special value |

## File Constraints

### File Operations
- Input file must exist and be readable
- Output directory must be writable
- UTF-8 encoding assumed for files
