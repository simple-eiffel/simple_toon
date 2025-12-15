note
	description: "[
		TOON (Token-Oriented Object Notation) encoder/decoder for Eiffel.

		TOON is a compact, human-readable format that encodes JSON with minimal
		quoting and explicit structure, achieving 30-60% token reduction for LLMs.

		Features:
		- Encode JSON values to TOON format
		- Decode TOON text back to JSON values
		- Configurable indentation and delimiters
		- Strict mode validation with detailed errors
		- Token estimation and compression ratio calculation

		Usage:
			local
				toon: SIMPLE_TOON
				json: SIMPLE_JSON
				value: SIMPLE_JSON_VALUE
				toon_text: STRING_32
			do
				create toon.make
				create json
				value := json.parse ("{%"name%": %"Alice%", %"age%": 30}")
				if attached value then
					toon_text := toon.encode (value)
					-- Result: "name: Alice%Nage: 30"
				end
			end
		]"
	date: "$Date$"
	revision: "$Revision$"
	EIS: "name=TOON Specification", "protocol=URI", "src=https://github.com/toon-format/spec"
	EIS: "name=TOON Format", "protocol=URI", "src=https://toonformat.dev/"

class
	SIMPLE_TOON

inherit
	SIMPLE_TOON_CONSTANTS
		export
			{NONE} all
		end

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize with default settings.
		do
			indent := Default_indent
			delimiter := Default_delimiter
			is_strict := True
			create last_errors.make (0)
			create encoder.make
			create decoder.make
		ensure
			default_indent: indent = Default_indent
			default_delimiter: delimiter = Default_delimiter
			strict_by_default: is_strict
			no_errors: not has_errors
		end

feature -- Encoding (JSON to TOON)

	encode,
	to_toon,
	serialize,
	compress_for_llm (a_json: SIMPLE_JSON_VALUE): STRING_32
			-- Convert JSON value to TOON format.
			-- Returns compact TOON representation.
		require
			json_not_void: a_json /= Void
		do
			clear_errors
			encoder.set_indent (indent)
			encoder.set_delimiter (delimiter)
			Result := encoder.encode (a_json)
		ensure
			result_attached: Result /= Void
		end

	encode_string,
	json_to_toon (a_json_text: STRING_32): detachable STRING_32
			-- Parse JSON string and convert to TOON.
			-- Returns Void on parse error.
		require
			not_empty: not a_json_text.is_empty
		local
			l_json: SIMPLE_JSON
			l_value: detachable SIMPLE_JSON_VALUE
		do
			clear_errors
			create l_json
			l_value := l_json.parse (a_json_text)
			if attached l_value then
				Result := encode (l_value)
			else
				add_error (create {SIMPLE_TOON_ERROR}.make ("Invalid JSON input"))
			end
		ensure
			error_on_failure: Result = Void implies has_errors
		end

feature -- Decoding (TOON to JSON)

	decode,
	from_toon,
	deserialize,
	parse_toon (a_toon_text: STRING_32): detachable SIMPLE_JSON_VALUE
			-- Parse TOON text and return JSON value.
			-- Returns Void on parse error, populates `last_errors'.
		require
			not_empty: not a_toon_text.is_empty
		do
			clear_errors
			decoder.set_indent (indent)
			decoder.set_delimiter (delimiter)
			decoder.set_strict (is_strict)
			Result := decoder.decode (a_toon_text)
			-- Transfer any decoder errors (strict mode warnings, validation errors)
			across decoder.errors as ic loop
				add_error (ic)
			end
		ensure
			errors_transferred: decoder.errors.count <= last_errors.count
		end

	decode_to_string,
	toon_to_json (a_toon_text: STRING_32): detachable STRING_32
			-- Parse TOON and return JSON string.
			-- Returns Void on parse error.
		require
			not_empty: not a_toon_text.is_empty
		local
			l_value: detachable SIMPLE_JSON_VALUE
		do
			l_value := decode (a_toon_text)
			if attached l_value then
				Result := l_value.to_json_string
			end
		ensure
			error_on_failure: Result = Void implies has_errors
		end

feature -- Configuration

	set_indent (a_spaces: INTEGER)
			-- Set indentation spaces per level.
			-- Default is 2 spaces.
		require
			positive: a_spaces > 0
		do
			indent := a_spaces
		ensure
			indent_set: indent = a_spaces
		end

	set_delimiter (a_delimiter: CHARACTER_32)
			-- Set array element delimiter.
			-- Options: ',' (comma), '%T' (tab), '|' (pipe)
		require
			valid_delimiter: a_delimiter = ',' or a_delimiter = '%T' or a_delimiter = '|'
		do
			delimiter := a_delimiter
		ensure
			delimiter_set: delimiter = a_delimiter
		end

	set_strict_mode,
	set_strict (a_enabled: BOOLEAN)
			-- Enable or disable strict validation mode.
			-- Strict mode validates array counts, delimiter consistency, etc.
		do
			is_strict := a_enabled
		ensure
			strict_set: is_strict = a_enabled
		end

	indent: INTEGER
			-- Spaces per indentation level

	delimiter: CHARACTER_32
			-- Array element delimiter

	is_strict: BOOLEAN
			-- Is strict validation enabled?

feature -- Analysis

	is_valid_toon (a_text: STRING_32): BOOLEAN
			-- Is `a_text' valid TOON syntax?
		require
			not_empty: not a_text.is_empty
		do
			Result := decode (a_text) /= Void
			clear_errors  -- Don't preserve validation errors
		end

	token_estimate (a_json: SIMPLE_JSON_VALUE): TUPLE [json_tokens, toon_tokens: INTEGER]
			-- Estimate token counts for JSON vs TOON encoding.
			-- Tokens estimated using GPT-4 tokenizer heuristics.
		require
			json_not_void: a_json /= Void
		local
			l_json_str, l_toon_str: STRING_32
		do
			l_json_str := a_json.to_json_string
			l_toon_str := encode (a_json)
			Result := [estimate_tokens (l_json_str), estimate_tokens (l_toon_str)]
		ensure
			result_attached: Result /= Void
		end

	compression_ratio (a_json: SIMPLE_JSON_VALUE): REAL_64
			-- Ratio of TOON tokens to JSON tokens.
			-- Value < 1.0 indicates token savings.
			-- Example: 0.6 means 40% reduction.
		require
			json_not_void: a_json /= Void
		local
			l_estimate: TUPLE [json_tokens, toon_tokens: INTEGER]
		do
			l_estimate := token_estimate (a_json)
			if l_estimate.json_tokens > 0 then
				Result := l_estimate.toon_tokens / l_estimate.json_tokens
			else
				Result := 1.0
			end
		ensure
			positive: Result >= 0.0
		end

	is_tabular_eligible (a_json: SIMPLE_JSON_VALUE): BOOLEAN
			-- Would `a_json' benefit from tabular TOON encoding?
			-- True if it's an array of uniform objects.
		require
			json_not_void: a_json /= Void
		do
			Result := encoder.is_tabular_eligible (a_json)
		end

feature -- Error Handling

	has_errors: BOOLEAN
			-- Were there errors during the last operation?
		do
			Result := not last_errors.is_empty
		ensure
			definition: Result = not last_errors.is_empty
		end

	last_errors: ARRAYED_LIST [SIMPLE_TOON_ERROR]
			-- Errors from the last operation

	error_count: INTEGER
			-- Number of errors
		do
			Result := last_errors.count
		ensure
			definition: Result = last_errors.count
		end

	first_error: detachable SIMPLE_TOON_ERROR
			-- First error, if any
		do
			if not last_errors.is_empty then
				Result := last_errors.first
			end
		ensure
			has_error_implies_result: has_errors implies Result /= Void
		end

	errors_as_string: STRING_32
			-- All errors as formatted string
		do
			create Result.make_empty
			across last_errors as ic loop
				if not Result.is_empty then
					Result.append_character ('%N')
				end
				Result.append (ic.to_string)
			end
		end

	clear_errors
			-- Clear all errors
		do
			last_errors.wipe_out
		ensure
			no_errors: not has_errors
		end

feature -- File Operations

	encode_file (a_json_path, a_toon_path: STRING_32): BOOLEAN
			-- Read JSON file, write TOON file.
			-- Returns True on success.
		require
			json_path_not_empty: not a_json_path.is_empty
			toon_path_not_empty: not a_toon_path.is_empty
		local
			l_json_file, l_toon_file: PLAIN_TEXT_FILE
			l_content, l_toon: detachable STRING_32
			l_utf: UTF_CONVERTER
		do
			clear_errors
			create l_utf
			create l_json_file.make_with_name (a_json_path)

			if l_json_file.exists and l_json_file.is_readable then
				l_json_file.open_read
				l_json_file.read_stream (l_json_file.count)
				l_content := l_utf.utf_8_string_8_to_string_32 (l_json_file.last_string)
				l_json_file.close

				l_toon := encode_string (l_content)
				if attached l_toon then
					create l_toon_file.make_create_read_write (a_toon_path)
					l_toon_file.put_string (l_utf.utf_32_string_to_utf_8_string_8 (l_toon))
					l_toon_file.close
					Result := True
				end
			else
				add_error (create {SIMPLE_TOON_ERROR}.make ("Cannot read file: " + a_json_path.to_string_8))
			end
		ensure
			error_on_failure: not Result implies has_errors
		end

	decode_file (a_toon_path, a_json_path: STRING_32): BOOLEAN
			-- Read TOON file, write JSON file.
			-- Returns True on success.
		require
			toon_path_not_empty: not a_toon_path.is_empty
			json_path_not_empty: not a_json_path.is_empty
		local
			l_toon_file, l_json_file: PLAIN_TEXT_FILE
			l_content, l_json: detachable STRING_32
			l_utf: UTF_CONVERTER
		do
			clear_errors
			create l_utf
			create l_toon_file.make_with_name (a_toon_path)

			if l_toon_file.exists and l_toon_file.is_readable then
				l_toon_file.open_read
				l_toon_file.read_stream (l_toon_file.count)
				l_content := l_utf.utf_8_string_8_to_string_32 (l_toon_file.last_string)
				l_toon_file.close

				l_json := decode_to_string (l_content)
				if attached l_json then
					create l_json_file.make_create_read_write (a_json_path)
					l_json_file.put_string (l_utf.utf_32_string_to_utf_8_string_8 (l_json))
					l_json_file.close
					Result := True
				end
			else
				add_error (create {SIMPLE_TOON_ERROR}.make ("Cannot read file: " + a_toon_path.to_string_8))
			end
		ensure
			error_on_failure: not Result implies has_errors
		end

feature {NONE} -- Implementation

	encoder: SIMPLE_TOON_ENCODER
			-- Encoder instance

	decoder: SIMPLE_TOON_DECODER
			-- Decoder instance

	add_error (a_error: SIMPLE_TOON_ERROR)
			-- Add error to list
		require
			error_not_void: a_error /= Void
		do
			last_errors.force (a_error)
		ensure
			error_added: last_errors.has (a_error)
		end

	estimate_tokens (a_text: STRING_32): INTEGER
			-- Estimate token count using simple heuristics.
			-- Approximates GPT-4 tokenizer behavior.
		require
			text_not_void: a_text /= Void
		do
			-- Simple heuristic: ~4 characters per token on average
			-- Adjust for punctuation which often gets its own token
			Result := (a_text.count / 4).ceiling_real_64.truncated_to_integer
			-- Add tokens for common punctuation
			across a_text as ic loop
				if ic = '{' or ic = '}' or ic = '[' or ic = ']' or ic = ':' or ic = ',' then
					Result := Result + 1
				end
			end
		ensure
			non_negative: Result >= 0
		end

invariant
	valid_indent: indent > 0
	valid_delimiter: delimiter = ',' or delimiter = '%T' or delimiter = '|'
	errors_attached: last_errors /= Void
	error_consistency: has_errors = not last_errors.is_empty
	encoder_attached: encoder /= Void
	decoder_attached: decoder /= Void

end
