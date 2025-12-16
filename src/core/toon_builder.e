note
	description: "[
		Fluent builder for constructing TOON directly without JSON intermediary.

		Enables direct construction of TOON format for LLM optimization
		without first building JSON structures.

		Usage:
			local
				builder: TOON_BUILDER
			do
				create builder.make
				builder
					.add_string ("name", "Alice")
					.add_integer ("age", 30)
					.add_boolean ("active", True)
					.start_array ("items", <<"sku", "qty">>)
						.row (<<"A1", "10">>)
						.row (<<"B2", "20">>)
					.end_array
				print (builder.to_string)
			end

		Output:
			name: Alice
			age: 30
			active: true
			items[2]{sku,qty}:
			  A1,10
			  B2,20
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	TOON_BUILDER

inherit
	SIMPLE_TOON_CONSTANTS
		export
			{NONE} all
		end

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize empty builder.
		do
			create output.make_empty
			create current_indent.make_empty
			indent_size := Default_indent
			delimiter := Default_delimiter
			in_array := False
			array_row_count := 0
		ensure
			empty_output: output.is_empty
			default_indent: indent_size = Default_indent
			default_delimiter: delimiter = Default_delimiter
			not_in_array: not in_array
		end

feature -- Configuration

	set_indent (a_spaces: INTEGER): like Current
			-- Set indentation spaces per level.
		require
			positive: a_spaces > 0
		do
			indent_size := a_spaces
			Result := Current
		ensure
			result_is_current: Result = Current
			indent_set: indent_size = a_spaces
		end

	set_delimiter (a_char: CHARACTER_32): like Current
			-- Set array delimiter (',' or '%T' or '|').
		require
			valid_delimiter: a_char = ',' or a_char = '%T' or a_char = '|'
		do
			delimiter := a_char
			Result := Current
		ensure
			result_is_current: Result = Current
			delimiter_set: delimiter = a_char
		end

feature -- Scalar Values

	add_string,
	string_value (a_key, a_value: READABLE_STRING_GENERAL): like Current
			-- Add string key-value pair.
		require
			key_not_empty: not a_key.is_empty
			value_not_void: a_value /= Void
			not_in_array_mode: not in_array
		do
			append_line (a_key.to_string_32 + ": " + escape_if_needed (a_value.to_string_32))
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	add_integer,
	integer_value (a_key: READABLE_STRING_GENERAL; a_value: INTEGER_64): like Current
			-- Add integer key-value pair.
		require
			key_not_empty: not a_key.is_empty
			not_in_array_mode: not in_array
		do
			append_line (a_key.to_string_32 + ": " + a_value.out)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	add_real,
	real_value (a_key: READABLE_STRING_GENERAL; a_value: REAL_64): like Current
			-- Add real/decimal key-value pair.
		require
			key_not_empty: not a_key.is_empty
			not_in_array_mode: not in_array
		do
			append_line (a_key.to_string_32 + ": " + a_value.out)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	add_boolean,
	boolean_value (a_key: READABLE_STRING_GENERAL; a_value: BOOLEAN): like Current
			-- Add boolean key-value pair.
		require
			key_not_empty: not a_key.is_empty
			not_in_array_mode: not in_array
		do
			if a_value then
				append_line (a_key.to_string_32 + ": true")
			else
				append_line (a_key.to_string_32 + ": false")
			end
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	add_null,
	null_value (a_key: READABLE_STRING_GENERAL): like Current
			-- Add null key-value pair.
		require
			key_not_empty: not a_key.is_empty
			not_in_array_mode: not in_array
		do
			append_line (a_key.to_string_32 + ": null")
			Result := Current
		ensure
			result_is_current: Result = Current
		end

feature -- Tabular Arrays

	start_array,
	begin_table (a_key: READABLE_STRING_GENERAL; a_columns: ARRAY [READABLE_STRING_GENERAL]): like Current
			-- Start a tabular array with column headers.
			-- Use `row' to add data rows, then `end_array'.
		require
			key_not_empty: not a_key.is_empty
			has_columns: a_columns.count > 0
			not_already_in_array: not in_array
		local
			l_header: STRING_32
			i: INTEGER
		do
			in_array := True
			array_row_count := 0
			array_key := a_key.to_string_32
			create array_columns.make_from_array (a_columns)

			-- Build header: key[n]{col1,col2,...}:
			-- Count will be filled in by end_array
			create l_header.make_from_string (a_key.to_string_32)
			l_header.append ("[")
			array_count_position := output.count + l_header.count + 1
			l_header.append ("]{")
			from i := a_columns.lower until i > a_columns.upper loop
				if i > a_columns.lower then
					l_header.append_character (delimiter)
				end
				l_header.append (a_columns[i].to_string_32)
				i := i + 1
			end
			l_header.append ("}:")
			append_line (l_header)

			-- Increase indent for rows
			push_indent

			Result := Current
		ensure
			result_is_current: Result = Current
			now_in_array: in_array
			zero_rows: array_row_count = 0
		end

	row,
	add_row (a_values: ARRAY [READABLE_STRING_GENERAL]): like Current
			-- Add a row to the current tabular array.
		require
			in_array_mode: in_array
			correct_column_count: column_count = 0 or a_values.count = column_count
		local
			l_row: STRING_32
			i: INTEGER
		do
			create l_row.make_empty
			from i := a_values.lower until i > a_values.upper loop
				if i > a_values.lower then
					l_row.append_character (delimiter)
				end
				l_row.append (escape_if_needed (a_values[i].to_string_32))
				i := i + 1
			end
			append_line (l_row)
			array_row_count := array_row_count + 1
			Result := Current
		ensure
			result_is_current: Result = Current
			row_added: array_row_count = old array_row_count + 1
		end

	end_array,
	end_table: like Current
			-- End the current tabular array.
		require
			in_array_mode: in_array
		do
			pop_indent
			in_array := False
			-- Update the row count in the header
			update_array_count
			array_columns := Void
			Result := Current
		ensure
			result_is_current: Result = Current
			not_in_array: not in_array
		end

feature -- Nested Objects

	start_object,
	begin_object (a_key: READABLE_STRING_GENERAL): like Current
			-- Start a nested object.
		require
			key_not_empty: not a_key.is_empty
			not_in_array_mode: not in_array
		do
			append_line (a_key.to_string_32 + ":")
			push_indent
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	end_object: like Current
			-- End a nested object.
		require
			not_in_array_mode: not in_array
		do
			pop_indent
			Result := Current
		ensure
			result_is_current: Result = Current
		end

feature -- Simple Arrays (non-tabular)

	add_string_array (a_key: READABLE_STRING_GENERAL; a_values: ARRAY [READABLE_STRING_GENERAL]): like Current
			-- Add a simple string array (one line).
		require
			key_not_empty: not a_key.is_empty
			not_in_array_mode: not in_array
		local
			l_line: STRING_32
			i: INTEGER
		do
			create l_line.make_from_string (a_key.to_string_32)
			l_line.append ("[")
			l_line.append_integer (a_values.count)
			l_line.append ("]: ")
			from i := a_values.lower until i > a_values.upper loop
				if i > a_values.lower then
					l_line.append_character (delimiter)
				end
				l_line.append (escape_if_needed (a_values[i].to_string_32))
				i := i + 1
			end
			append_line (l_line)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	add_integer_array (a_key: READABLE_STRING_GENERAL; a_values: ARRAY [INTEGER_64]): like Current
			-- Add a simple integer array (one line).
		require
			key_not_empty: not a_key.is_empty
			not_in_array_mode: not in_array
		local
			l_line: STRING_32
			i: INTEGER
		do
			create l_line.make_from_string (a_key.to_string_32)
			l_line.append ("[")
			l_line.append_integer (a_values.count)
			l_line.append ("]: ")
			from i := a_values.lower until i > a_values.upper loop
				if i > a_values.lower then
					l_line.append_character (delimiter)
				end
				l_line.append (a_values[i].out)
				i := i + 1
			end
			append_line (l_line)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

feature -- Output

	to_string,
	build,
	to_toon: STRING_32
			-- Return the built TOON string.
		require
			not_in_array: not in_array
		do
			Result := output.twin
		ensure
			result_attached: Result /= Void
		end

	reset,
	clear: like Current
			-- Clear and start fresh.
		do
			output.wipe_out
			current_indent.wipe_out
			in_array := False
			array_row_count := 0
			array_columns := Void
			Result := Current
		ensure
			result_is_current: Result = Current
			empty: output.is_empty
			not_in_array: not in_array
		end

feature -- Status

	is_empty: BOOLEAN
			-- Is the builder empty?
		do
			Result := output.is_empty
		end

	in_array: BOOLEAN
			-- Are we currently building a tabular array?

	column_count: INTEGER
			-- Number of columns in current array (0 if not in array).
		do
			if attached array_columns as cols then
				Result := cols.count
			end
		ensure
			non_negative: Result >= 0
			zero_when_not_in_array: not in_array implies Result = 0
		end

	line_count: INTEGER
			-- Number of lines in current output
		local
			i: INTEGER
		do
			Result := 1
			from i := 1 until i > output.count loop
				if output[i] = '%N' then
					Result := Result + 1
				end
				i := i + 1
			end
			if output.count > 0 and then output[output.count] = '%N' then
				Result := Result - 1
			end
		end

feature {NONE} -- Implementation

	output: STRING_32
			-- Accumulated TOON output

	current_indent: STRING_32
			-- Current indentation string

	indent_size: INTEGER
			-- Spaces per indent level

	delimiter: CHARACTER_32
			-- Array element delimiter

	array_row_count: INTEGER
			-- Count of rows in current array

	array_key: detachable STRING_32
			-- Key of current array

	array_columns: detachable ARRAY [READABLE_STRING_GENERAL]
			-- Column headers of current array

	array_count_position: INTEGER
			-- Position in output where array count should be inserted

	append_line (a_line: STRING_32)
			-- Append line with current indentation.
		do
			if not output.is_empty then
				output.append_character ('%N')
			end
			output.append (current_indent)
			output.append (a_line)
		end

	push_indent
			-- Increase indentation level.
		local
			i: INTEGER
		do
			from i := 1 until i > indent_size loop
				current_indent.append_character (' ')
				i := i + 1
			end
		end

	pop_indent
			-- Decrease indentation level.
		do
			if current_indent.count >= indent_size then
				current_indent.remove_tail (indent_size)
			end
		end

	update_array_count
			-- Update the array count placeholder with actual count.
		local
			l_before, l_after: STRING_32
			l_bracket_pos, l_close_pos: INTEGER
		do
			-- Find the array header line and update count
			-- Format: key[n]{...}: where n is the placeholder
			if attached array_key as k then
				l_bracket_pos := output.substring_index (k + "[", 1)
				if l_bracket_pos > 0 then
					l_bracket_pos := l_bracket_pos + k.count
					l_close_pos := output.index_of (']', l_bracket_pos + 1)
					if l_close_pos > l_bracket_pos then
						l_before := output.substring (1, l_bracket_pos)
						l_after := output.substring (l_close_pos, output.count)
						output.wipe_out
						output.append (l_before)
						output.append_integer (array_row_count)
						output.append (l_after)
					end
				end
			end
		end

	escape_if_needed (a_value: STRING_32): STRING_32
			-- Escape value if it contains special characters.
		local
			l_needs_escape: BOOLEAN
			i: INTEGER
		do
			-- Check if escaping needed
			from i := 1 until i > a_value.count or l_needs_escape loop
				inspect a_value[i]
				when ',', '%T', '|', ':', '%N', '"', '\' then
					l_needs_escape := True
				else
					-- OK
				end
				i := i + 1
			end

			if l_needs_escape then
				create Result.make (a_value.count + 10)
				Result.append_character ('"')
				from i := 1 until i > a_value.count loop
					inspect a_value[i]
					when '"' then
						Result.append ("\%"")
					when '\' then
						Result.append ("\\")
					when '%N' then
						Result.append ("\n")
					when '%R' then
						Result.append ("\r")
					when '%T' then
						Result.append ("\t")
					else
						Result.append_character (a_value[i])
					end
					i := i + 1
				end
				Result.append_character ('"')
			else
				Result := a_value
			end
		ensure
			result_attached: Result /= Void
		end

invariant
	output_attached: output /= Void
	indent_attached: current_indent /= Void
	valid_indent_size: indent_size > 0
	valid_delimiter: delimiter = ',' or delimiter = '%T' or delimiter = '|'
	row_count_non_negative: array_row_count >= 0

end
