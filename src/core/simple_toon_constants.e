note
	description: "Constants for TOON encoding/decoding"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_TOON_CONSTANTS

feature -- Defaults

	Default_indent: INTEGER = 2
			-- Default indentation (2 spaces)

	Default_delimiter: CHARACTER_32 = ','
			-- Default array delimiter (comma)

feature -- Delimiters

	Delimiter_comma: CHARACTER_32 = ','
	Delimiter_tab: CHARACTER_32 = '%T'
	Delimiter_pipe: CHARACTER_32 = '|'

feature -- Special Characters

	Newline: CHARACTER_32 = '%N'
	Colon: CHARACTER_32 = ':'
	Hyphen: CHARACTER_32 = '-'
	Open_bracket: CHARACTER_32 = '['
	Close_bracket: CHARACTER_32 = ']'
	Open_brace: CHARACTER_32 = '{'
	Close_brace: CHARACTER_32 = '}'
	Quote: CHARACTER_32 = '"'
	Backslash: CHARACTER_32 = '\'
	Space: CHARACTER_32 = ' '

feature -- Keywords

	Keyword_true: STRING_32 = "true"
	Keyword_false: STRING_32 = "false"
	Keyword_null: STRING_32 = "null"

feature -- Error Types

	Error_type_syntax: INTEGER = 1
	Error_type_delimiter: INTEGER = 2
	Error_type_count_mismatch: INTEGER = 3
	Error_type_invalid_escape: INTEGER = 4
	Error_type_unterminated_string: INTEGER = 5
	Error_type_indentation: INTEGER = 6

feature -- Patterns

	Identifier_pattern: STRING_32 = "^[A-Za-z_][A-Za-z0-9_.]*$"
			-- Pattern for unquoted keys

	Numeric_chars: STRING_32 = "0123456789.-+eE"
			-- Characters that appear in numbers

feature -- Escape Sequences

	Valid_escapes: STRING_32 = "\%"nrt"
			-- Valid escape characters after backslash

end
