# Drift Analysis: simple_toon

Generated: 2026-01-24
Method: `ec.exe -flatshort` vs `specs/*.md` + `research/*.md`

## Specification Sources

| Source | Files | Lines |
|--------|-------|-------|
| specs/*.md | 8 | 770 |
| research/*.md | 2 | 602 |

## Classes Analyzed

| Class | Spec'd Features | Actual Features | Drift |
|-------|-----------------|-----------------|-------|
| SIMPLE_TOON | 31 | 82 | +51 |

## Feature-Level Drift

### Specified, Implemented ✓
- `clear_errors` ✓
- `compress_for_llm` ✓
- `compression_ratio` ✓
- `decode_file` ✓
- `decode_to_string` ✓
- `encode_file` ✓
- `encode_string` ✓
- `error_count` ✓
- `errors_as_string` ✓
- `first_error` ✓
- ... and 14 more

### Specified, NOT Implemented ✗
- `simple_csv` ✗
- `simple_json` ✗
- `simple_toml` ✗
- `simple_toon` ✗
- `simple_toon_tests` ✗
- `simple_xml` ✗
- `simple_yaml` ✗

### Implemented, NOT Specified
- `Backslash`
- `Close_brace`
- `Close_bracket`
- `Colon`
- `Default_delimiter`
- `Default_indent`
- `Delimiter_comma`
- `Delimiter_pipe`
- `Delimiter_tab`
- `Error_type_count_mismatch`
- ... and 48 more

## Summary

| Category | Count |
|----------|-------|
| Spec'd, implemented | 24 |
| Spec'd, missing | 7 |
| Implemented, not spec'd | 58 |
| **Overall Drift** | **HIGH** |

## Conclusion

**simple_toon** has high drift. Significant gaps between spec and implementation.
