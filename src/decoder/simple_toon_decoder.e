note
	description: "Decodes TOON format to JSON values"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_TOON_DECODER

inherit
	SIMPLE_TOON_CONSTANTS

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize decoder with defaults.
		do
			indent := Default_indent
			delimiter := Default_delimiter
			is_strict := True
			create errors.make (0)
			create lines.make (0)
		ensure
			default_indent: indent = Default_indent
			default_delimiter: delimiter = Default_delimiter
			strict_by_default: is_strict
		end

feature -- Configuration

	set_indent (a_spaces: INTEGER)
			-- Set expected indentation.
		require
			positive: a_spaces > 0
		do
			indent := a_spaces
		ensure
			indent_set: indent = a_spaces
		end

	set_delimiter (a_delimiter: CHARACTER_32)
			-- Set expected delimiter.
		require
			valid: a_delimiter = ',' or a_delimiter = '%T' or a_delimiter = '|'
		do
			delimiter := a_delimiter
		ensure
			delimiter_set: delimiter = a_delimiter
		end

	set_strict (a_enabled: BOOLEAN)
			-- Enable/disable strict mode.
		do
			is_strict := a_enabled
		ensure
			strict_set: is_strict = a_enabled
		end

	indent: INTEGER
	delimiter: CHARACTER_32
	is_strict: BOOLEAN

feature -- Decoding

	decode (a_toon_text: STRING_32): detachable SIMPLE_JSON_VALUE
			-- Decode TOON text to JSON value.
		require
			not_empty: not a_toon_text.is_empty
		local
			l_json: SIMPLE_JSON
		do
			errors.wipe_out
			split_lines (a_toon_text)

			if lines.is_empty then
				-- Empty document = empty object
				create l_json
				Result := l_json.new_object
			else
				Result := parse_document
			end
		end

	errors: ARRAYED_LIST [SIMPLE_TOON_ERROR]
			-- Parsing errors

feature {NONE} -- Implementation

	lines: ARRAYED_LIST [STRING_32]
			-- Lines of input

	current_line: INTEGER
			-- Current line being parsed

	split_lines (a_text: STRING_32)
			-- Split text into lines.
		require
			text_not_void: a_text /= Void
		local
			l_line: STRING_32
			i: INTEGER
			c: CHARACTER_32
		do
			lines.wipe_out
			create l_line.make_empty

			from i := 1 until i > a_text.count loop
				c := a_text.item (i)
				if c = '%N' then
					lines.force (l_line)
					create l_line.make_empty
				elseif c /= '%R' then
					l_line.append_character (c)
				end
				i := i + 1
			end

			-- Add final line if not empty
			if not l_line.is_empty then
				lines.force (l_line)
			end
		end

	parse_document: detachable SIMPLE_JSON_VALUE
			-- Parse entire document.
		local
			l_first_line: STRING_32
			l_trimmed: STRING_32
		do
			current_line := 1

			-- Skip empty lines at start
			from until current_line > lines.count or else not line_is_empty (current_line) loop
				current_line := current_line + 1
			end

			if current_line > lines.count then
				-- All empty = empty object
				Result := create_empty_object
			else
				l_first_line := lines [current_line]
				l_trimmed := l_first_line.twin
				l_trimmed.left_adjust

				if is_array_header (l_trimmed) then
					-- Root array
					Result := parse_array_at_depth (0)
				elseif is_primitive_only then
					-- Single primitive
					Result := parse_primitive (l_trimmed)
				else
					-- Root object
					Result := parse_object_at_depth (0)
				end
			end
		end

	parse_object_at_depth (a_depth: INTEGER): detachable SIMPLE_JSON_VALUE
			-- Parse object starting at current line.
		local
			l_obj: SIMPLE_JSON_OBJECT
			l_json: SIMPLE_JSON
			l_line, l_key, l_value_str: STRING_32
			l_line_depth: INTEGER
			l_colon_pos: INTEGER
			l_value: detachable SIMPLE_JSON_VALUE
			l_done: BOOLEAN
		do
			create l_json
			l_obj := l_json.new_object

			from until current_line > lines.count or l_done loop
				if line_is_empty (current_line) then
					current_line := current_line + 1
				else
					l_line := lines [current_line]
					l_line_depth := get_indent_depth (l_line)

					if l_line_depth < a_depth then
						-- Dedent - end of this object
						l_done := True
					elseif l_line_depth > a_depth then
						-- Unexpected indent
						add_error ("Unexpected indentation", current_line, 1)
						current_line := current_line + 1
					else
						-- Parse key: value
						l_line := l_line.twin
						l_line.left_adjust

						l_colon_pos := find_colon (l_line)
						if l_colon_pos > 0 then
							l_key := l_line.substring (1, l_colon_pos - 1)
							l_key.right_adjust
							l_key := unquote_key (l_key)

							l_value_str := l_line.substring (l_colon_pos + 1, l_line.count)
							l_value_str.left_adjust

							if l_value_str.is_empty then
								-- Value on next lines (nested object or array)
								current_line := current_line + 1
								if current_line <= lines.count then
									l_value := parse_nested_value (a_depth + 1)
									if attached l_value then
										l_obj.put_value (l_value, l_key).do_nothing
									end
								end
							elseif is_array_header (l_value_str) then
								-- Inline array header
								l_value := parse_inline_array (l_value_str, a_depth)
								if attached l_value then
									l_obj.put_value (l_value, l_key).do_nothing
								end
								current_line := current_line + 1
							else
								-- Inline value
								l_value := parse_primitive (l_value_str)
								if attached l_value then
									l_obj.put_value (l_value, l_key).do_nothing
								end
								current_line := current_line + 1
							end
						else
							add_error ("Expected key: value", current_line, 1)
							current_line := current_line + 1
						end
					end
				end
			end

			Result := l_obj
		end

	parse_array_at_depth (a_depth: INTEGER): detachable SIMPLE_JSON_VALUE
			-- Parse array starting at current line with header.
		local
			l_line: STRING_32
			l_header: STRING_32
			l_count: INTEGER
			l_fields: detachable ARRAYED_LIST [STRING_32]
			l_arr: SIMPLE_JSON_ARRAY
			l_json: SIMPLE_JSON
		do
			l_line := lines [current_line]
			l_line := l_line.twin
			l_line.left_adjust

			-- Parse header [N]{fields}:
			l_header := l_line
			l_count := parse_array_count (l_header)
			l_fields := parse_array_fields (l_header)

			create l_json
			l_arr := l_json.new_array
			current_line := current_line + 1

			if attached l_fields then
				-- Tabular array
				parse_tabular_rows (l_arr, l_fields, a_depth + 1)
			elseif is_inline_array (l_header) then
				-- Inline primitive array
				parse_inline_primitives (l_arr, l_header)
			else
				-- List array with - items
				parse_list_items (l_arr, a_depth + 1)
			end

			-- Validate count in strict mode
			if is_strict and l_count >= 0 and l_arr.count /= l_count then
				add_error ("Array count mismatch: expected " + l_count.out + ", got " + l_arr.count.out,
					current_line - 1, 1)
			end

			Result := l_arr
		end

	parse_nested_value (a_depth: INTEGER): detachable SIMPLE_JSON_VALUE
			-- Parse value at given depth (could be object or array).
		local
			l_line: STRING_32
		do
			if current_line <= lines.count then
				l_line := lines [current_line]
				l_line := l_line.twin
				l_line.left_adjust

				if is_array_header (l_line) then
					Result := parse_array_at_depth (a_depth)
				elseif l_line.starts_with ("- ") then
					-- This shouldn't happen here, but handle gracefully
					Result := parse_object_at_depth (a_depth)
				else
					Result := parse_object_at_depth (a_depth)
				end
			end
		end

	parse_inline_array (a_header: STRING_32; a_depth: INTEGER): detachable SIMPLE_JSON_VALUE
			-- Parse inline array from header line.
		local
			l_arr: SIMPLE_JSON_ARRAY
			l_json: SIMPLE_JSON
			l_fields: detachable ARRAYED_LIST [STRING_32]
		do
			create l_json
			l_arr := l_json.new_array

			l_fields := parse_array_fields (a_header)

			if attached l_fields then
				-- Has field headers - tabular format
				current_line := current_line + 1
				parse_tabular_rows (l_arr, l_fields, a_depth + 1)
				current_line := current_line - 1  -- Adjust for caller's increment
			elseif is_inline_array (a_header) then
				-- Inline primitives
				parse_inline_primitives (l_arr, a_header)
			else
				-- List items
				current_line := current_line + 1
				parse_list_items (l_arr, a_depth + 1)
				current_line := current_line - 1
			end

			Result := l_arr
		end

	parse_tabular_rows (a_arr: SIMPLE_JSON_ARRAY; a_fields: ARRAYED_LIST [STRING_32]; a_depth: INTEGER)
			-- Parse tabular data rows.
		require
			arr_not_void: a_arr /= Void
			fields_not_void: a_fields /= Void
		local
			l_line: STRING_32
			l_depth: INTEGER
			l_values: LIST [STRING_32]
			l_obj: SIMPLE_JSON_OBJECT
			l_json: SIMPLE_JSON
			i: INTEGER
			l_done: BOOLEAN
		do
			create l_json

			from until current_line > lines.count or l_done loop
				if line_is_empty (current_line) then
					current_line := current_line + 1
				else
					l_line := lines [current_line]
					l_depth := get_indent_depth (l_line)

					if l_depth < a_depth then
						-- Dedent - end of tabular data
						l_done := True
					else
						l_line := l_line.twin
						l_line.left_adjust
						l_values := split_by_delimiter (l_line)

						if l_values.count = a_fields.count then
							l_obj := l_json.new_object
							from i := 1 until i > a_fields.count loop
								if attached parse_primitive (l_values [i]) as l_prim then
								l_obj.put_value (l_prim, a_fields [i]).do_nothing
							end
								i := i + 1
							end
							a_arr.add_object (l_obj).do_nothing
						elseif is_strict then
							add_error ("Row has " + l_values.count.out + " values, expected " + a_fields.count.out,
								current_line, 1)
						end

						current_line := current_line + 1
					end
				end
			end
		end

	parse_inline_primitives (a_arr: SIMPLE_JSON_ARRAY; a_header: STRING_32)
			-- Parse inline primitive values from header.
		local
			l_colon_pos: INTEGER
			l_values_str: STRING_32
			l_values: LIST [STRING_32]
		do
			l_colon_pos := a_header.index_of (':', 1)
			if l_colon_pos > 0 and l_colon_pos < a_header.count then
				l_values_str := a_header.substring (l_colon_pos + 1, a_header.count)
				l_values_str.left_adjust

				if not l_values_str.is_empty then
					l_values := split_by_delimiter (l_values_str)
					across l_values as ic loop
						if attached parse_primitive (ic) as l_val then
							a_arr.add_value (l_val).do_nothing
						end
					end
				end
			end
		end

	parse_list_items (a_arr: SIMPLE_JSON_ARRAY; a_depth: INTEGER)
			-- Parse list items with - prefix.
		local
			l_line: STRING_32
			l_depth: INTEGER
			l_content: STRING_32
			l_value: detachable SIMPLE_JSON_VALUE
			l_done: BOOLEAN
		do
			from until current_line > lines.count or l_done loop
				if line_is_empty (current_line) then
					current_line := current_line + 1
				else
					l_line := lines [current_line]
					l_depth := get_indent_depth (l_line)

					if l_depth < a_depth then
						-- Dedent - end of list
						l_done := True
					else
						l_line := l_line.twin
						l_line.left_adjust

						if l_line.starts_with ("- ") then
							l_content := l_line.substring (3, l_line.count)

							if l_content.has (':') then
								-- Object item - parse inline object
								l_value := parse_list_object (l_content, a_depth)
							else
								-- Primitive item
								l_value := parse_primitive (l_content)
								current_line := current_line + 1
							end

							if attached l_value then
								a_arr.add_value (l_value).do_nothing
							end
						else
							-- Not a list item - end of list
							l_done := True
						end
					end
				end
			end
		end

	parse_list_object (a_first_line: STRING_32; a_depth: INTEGER): detachable SIMPLE_JSON_VALUE
			-- Parse object starting with inline content after "- ".
		local
			l_obj: SIMPLE_JSON_OBJECT
			l_json: SIMPLE_JSON
			l_colon_pos: INTEGER
			l_key, l_value_str: STRING_32
			l_value: detachable SIMPLE_JSON_VALUE
			l_line: STRING_32
			l_line_depth: INTEGER
			l_done: BOOLEAN
		do
			create l_json
			l_obj := l_json.new_object

			-- Parse first key: value from same line
			l_colon_pos := find_colon (a_first_line)
			if l_colon_pos > 0 then
				l_key := a_first_line.substring (1, l_colon_pos - 1)
				l_key.right_adjust
				l_key := unquote_key (l_key)

				l_value_str := a_first_line.substring (l_colon_pos + 1, a_first_line.count)
				l_value_str.left_adjust

				if l_value_str.is_empty then
					-- Nested value
					current_line := current_line + 1
					l_value := parse_nested_value (a_depth + 1)
				else
					l_value := parse_primitive (l_value_str)
					current_line := current_line + 1
				end

				if attached l_value then
					l_obj.put_value (l_value, l_key).do_nothing
				end
			else
				current_line := current_line + 1
			end

			-- Parse remaining fields at depth + 1
			from until current_line > lines.count or l_done loop
				if line_is_empty (current_line) then
					current_line := current_line + 1
				else
					l_line := lines [current_line]
					l_line_depth := get_indent_depth (l_line)

					if l_line_depth <= a_depth then
						-- Back to list level or less - done with this object
						l_done := True
					else
						l_line := l_line.twin
						l_line.left_adjust

						l_colon_pos := find_colon (l_line)
						if l_colon_pos > 0 then
							l_key := l_line.substring (1, l_colon_pos - 1)
							l_key.right_adjust
							l_key := unquote_key (l_key)

							l_value_str := l_line.substring (l_colon_pos + 1, l_line.count)
							l_value_str.left_adjust

							if l_value_str.is_empty then
								current_line := current_line + 1
								l_value := parse_nested_value (a_depth + 2)
							else
								l_value := parse_primitive (l_value_str)
								current_line := current_line + 1
							end

							if attached l_value then
								l_obj.put_value (l_value, l_key).do_nothing
							end
						else
							current_line := current_line + 1
						end
					end
				end
			end

			Result := l_obj
		end

	parse_primitive (a_text: STRING_32): detachable SIMPLE_JSON_VALUE
			-- Parse primitive value (string, number, boolean, null).
		local
			l_text: STRING_32
			l_json: SIMPLE_JSON
		do
			l_text := a_text.twin
			l_text.left_adjust
			l_text.right_adjust

			create l_json

			if l_text.is_equal (Keyword_null) then
				Result := l_json.null_value
			elseif l_text.is_equal (Keyword_true) then
				Result := l_json.boolean_value (True)
			elseif l_text.is_equal (Keyword_false) then
				Result := l_json.boolean_value (False)
			elseif l_text.starts_with ("%"") and l_text.ends_with ("%"") then
				-- Quoted string
				Result := l_json.string_value (unescape_string (l_text.substring (2, l_text.count - 1)))
			elseif is_number (l_text) then
				if l_text.has ('.') then
					Result := l_json.number_value (l_text.to_double)
				else
					Result := l_json.integer_value (l_text.to_integer_64)
				end
			else
				-- Unquoted string
				Result := l_json.string_value (l_text)
			end
		end

	-- Helper features

	line_is_empty (a_line_num: INTEGER): BOOLEAN
			-- Is line empty or whitespace only?
		require
			valid_line: a_line_num >= 1 and a_line_num <= lines.count
		local
			l_line: STRING_32
		do
			l_line := lines [a_line_num]
			l_line := l_line.twin
			l_line.left_adjust
			Result := l_line.is_empty
		end

	get_indent_depth (a_line: STRING_32): INTEGER
			-- Get indentation depth of line.
		require
			line_not_void: a_line /= Void
		local
			i, l_spaces: INTEGER
		do
			from i := 1 until i > a_line.count or else a_line.item (i) /= ' ' loop
				l_spaces := l_spaces + 1
				i := i + 1
			end
			Result := l_spaces // indent
		end

	is_array_header (a_line: STRING_32): BOOLEAN
			-- Does line start with [N] array header?
		require
			line_not_void: a_line /= Void
		do
			Result := a_line.count >= 3 and then a_line.item (1) = '['
		end

	is_inline_array (a_header: STRING_32): BOOLEAN
			-- Is this an inline array (values after colon)?
		require
			header_not_void: a_header /= Void
		local
			l_colon_pos: INTEGER
			l_after: STRING_32
		do
			l_colon_pos := a_header.index_of (':', 1)
			if l_colon_pos > 0 and l_colon_pos < a_header.count then
				l_after := a_header.substring (l_colon_pos + 1, a_header.count)
				l_after.left_adjust
				Result := not l_after.is_empty
			end
		end

	is_primitive_only: BOOLEAN
			-- Does document contain only a single primitive?
		local
			l_non_empty_count: INTEGER
			i: INTEGER
		do
			from i := 1 until i > lines.count loop
				if not line_is_empty (i) then
					l_non_empty_count := l_non_empty_count + 1
				end
				i := i + 1
			end
			if l_non_empty_count = 1 then
				-- Check if it's a key: value or just a value
				Result := not lines [current_line].has (':')
			end
		end

	parse_array_count (a_header: STRING_32): INTEGER
			-- Extract count from [N] header. Returns -1 if invalid.
		local
			l_bracket_end: INTEGER
			l_count_str: STRING_32
		do
			Result := -1
			if a_header.count >= 3 and then a_header.item (1) = '[' then
				l_bracket_end := a_header.index_of (']', 1)
				if l_bracket_end > 2 then
					l_count_str := a_header.substring (2, l_bracket_end - 1)
					if l_count_str.is_integer then
						Result := l_count_str.to_integer
					end
				end
			end
		end

	parse_array_fields (a_header: STRING_32): detachable ARRAYED_LIST [STRING_32]
			-- Extract field names from {field1,field2} in header.
		local
			l_brace_start, l_brace_end: INTEGER
			l_fields_str: STRING_32
		do
			l_brace_start := a_header.index_of ('{', 1)
			l_brace_end := a_header.index_of ('}', 1)

			if l_brace_start > 0 and l_brace_end > l_brace_start then
				l_fields_str := a_header.substring (l_brace_start + 1, l_brace_end - 1)
				Result := split_by_delimiter (l_fields_str)
			end
		end

	split_by_delimiter (a_text: STRING_32): ARRAYED_LIST [STRING_32]
			-- Split text by current delimiter.
		require
			text_not_void: a_text /= Void
		local
			l_parts: LIST [STRING_32]
			l_part: STRING_32
		do
			create Result.make (5)
			l_parts := a_text.split (delimiter)
			across l_parts as ic loop
				l_part := ic.twin
				l_part.left_adjust
				l_part.right_adjust
				Result.force (l_part)
			end
		end

	find_colon (a_line: STRING_32): INTEGER
			-- Find colon position, respecting quotes.
		require
			line_not_void: a_line /= Void
		local
			i: INTEGER
			l_in_quotes: BOOLEAN
			c: CHARACTER_32
		do
			from i := 1 until i > a_line.count or Result > 0 loop
				c := a_line.item (i)
				if c = '"' then
					l_in_quotes := not l_in_quotes
				elseif c = ':' and not l_in_quotes then
					Result := i
				end
				i := i + 1
			end
		end

	unquote_key (a_key: STRING_32): STRING_32
			-- Remove quotes from key if present.
		require
			key_not_void: a_key /= Void
		do
			if a_key.count >= 2 and then a_key.item (1) = '"' and then a_key.item (a_key.count) = '"' then
				Result := unescape_string (a_key.substring (2, a_key.count - 1))
			else
				Result := a_key
			end
		end

	unescape_string (a_string: STRING_32): STRING_32
			-- Process escape sequences in string.
		require
			string_not_void: a_string /= Void
		local
			i: INTEGER
			c: CHARACTER_32
		do
			create Result.make (a_string.count)
			from i := 1 until i > a_string.count loop
				c := a_string.item (i)
				if c = '\' and i < a_string.count then
					i := i + 1
					c := a_string.item (i)
					inspect c
					when 'n' then Result.append_character ('%N')
					when 'r' then Result.append_character ('%R')
					when 't' then Result.append_character ('%T')
					when '\' then Result.append_character ('\')
					when '"' then Result.append_character ('"')
					else
						Result.append_character ('\')
						Result.append_character (c)
					end
				else
					Result.append_character (c)
				end
				i := i + 1
			end
		end

	is_number (a_text: STRING_32): BOOLEAN
			-- Is text a valid number?
		require
			text_not_void: a_text /= Void
		do
			if not a_text.is_empty then
				Result := a_text.is_double or a_text.is_integer_64
			end
		end

	create_empty_object: SIMPLE_JSON_VALUE
			-- Create empty JSON object.
		local
			l_json: SIMPLE_JSON
		do
			create l_json
			Result := l_json.new_object
		end

	add_error (a_message: STRING_32; a_line, a_column: INTEGER)
			-- Add parsing error.
		require
			message_not_empty: not a_message.is_empty
		do
			errors.force (create {SIMPLE_TOON_ERROR}.make_with_position (a_message, a_line, a_column))
		end

invariant
	valid_indent: indent > 0
	valid_delimiter: delimiter = ',' or delimiter = '%T' or delimiter = '|'
	errors_attached: errors /= Void
	lines_attached: lines /= Void

end
