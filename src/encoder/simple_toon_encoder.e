note
	description: "Encodes JSON values to TOON format"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_TOON_ENCODER

inherit
	SIMPLE_TOON_CONSTANTS

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize encoder with defaults.
		do
			indent := Default_indent
			delimiter := Default_delimiter
			create indent_string.make_filled (Space, indent)
		ensure
			default_indent: indent = Default_indent
			default_delimiter: delimiter = Default_delimiter
		end

feature -- Configuration

	set_indent (a_spaces: INTEGER)
			-- Set indentation spaces.
		require
			positive: a_spaces > 0
		do
			indent := a_spaces
			create indent_string.make_filled (Space, indent)
		ensure
			indent_set: indent = a_spaces
		end

	set_delimiter (a_delimiter: CHARACTER_32)
			-- Set array element delimiter.
		require
			valid: a_delimiter = ',' or a_delimiter = '%T' or a_delimiter = '|'
		do
			delimiter := a_delimiter
		ensure
			delimiter_set: delimiter = a_delimiter
		end

	indent: INTEGER
	delimiter: CHARACTER_32

feature -- Encoding

	encode (a_value: SIMPLE_JSON_VALUE): STRING_32
			-- Encode JSON value to TOON format.
		require
			value_not_void: a_value /= Void
		do
			create Result.make (256)
			encode_value (a_value, 0, Result)
			-- Remove trailing newline if present
			if not Result.is_empty and then Result [Result.count] = '%N' then
				Result.remove_tail (1)
			end
		ensure
			result_attached: Result /= Void
		end

feature -- Analysis

	is_tabular_eligible (a_value: SIMPLE_JSON_VALUE): BOOLEAN
			-- Is value an array of uniform objects suitable for tabular encoding?
		require
			value_not_void: a_value /= Void
		local
			l_array: SIMPLE_JSON_ARRAY
			l_first_keys: detachable ARRAYED_LIST [STRING_32]
			l_current_keys: ARRAYED_LIST [STRING_32]
			l_item: SIMPLE_JSON_VALUE
			i: INTEGER
		do
			if a_value.is_array then
				l_array := a_value.as_array
				if l_array.count >= 2 then
					-- Check if all items are objects with same keys
					from
						i := 1
						Result := True
					until
						i > l_array.count or not Result
					loop
						l_item := l_array.item (i)
						if l_item.is_object then
							l_current_keys := l_item.as_object.keys
							if l_first_keys = Void then
								l_first_keys := l_current_keys
							else
								Result := keys_match (l_first_keys, l_current_keys)
							end
						else
							Result := False
						end
						i := i + 1
					end
				end
			end
		end

feature {NONE} -- Implementation

	indent_string: STRING_32
			-- Cached indent string

	encode_value (a_value: SIMPLE_JSON_VALUE; a_depth: INTEGER; a_output: STRING_32)
			-- Encode value at given depth.
		require
			value_not_void: a_value /= Void
			output_not_void: a_output /= Void
			non_negative_depth: a_depth >= 0
		do
			if a_value.is_null then
				a_output.append (Keyword_null)
			elseif a_value.is_boolean then
				if a_value.as_boolean then
					a_output.append (Keyword_true)
				else
					a_output.append (Keyword_false)
				end
			elseif a_value.is_integer then
				a_output.append_integer_64 (a_value.as_integer)
			elseif a_value.is_number then
				-- Use as_decimal to preserve exact representation from JSON_DECIMAL
				a_output.append (a_value.as_decimal.to_string)
			elseif a_value.is_string then
				encode_string (a_value.as_string_32, a_output)
			elseif a_value.is_array then
				encode_array (a_value.as_array, a_depth, a_output)
			elseif a_value.is_object then
				encode_object (a_value.as_object, a_depth, a_output)
			end
		end

	encode_string (a_string: STRING_32; a_output: STRING_32)
			-- Encode string, quoting if necessary.
		require
			string_not_void: a_string /= Void
			output_not_void: a_output /= Void
		do
			if needs_quoting (a_string) then
				a_output.append_character (Quote)
				a_output.append (escape_string (a_string))
				a_output.append_character (Quote)
			else
				a_output.append (a_string)
			end
		end

	encode_array (a_array: SIMPLE_JSON_ARRAY; a_depth: INTEGER; a_output: STRING_32)
			-- Encode array.
		require
			array_not_void: a_array /= Void
			output_not_void: a_output /= Void
		local
			i: INTEGER
			l_item: SIMPLE_JSON_VALUE
		do
			if a_array.is_empty then
				-- Empty array: [0]:
				a_output.append ("[0]:")
			elseif is_primitive_array (a_array) then
				-- Primitive array: inline format
				encode_primitive_array (a_array, a_output)
			elseif is_tabular_array (a_array) then
				-- Tabular array: header + rows
				encode_tabular_array (a_array, a_depth, a_output)
			else
				-- Mixed/object array: list items
				encode_list_array (a_array, a_depth, a_output)
			end
		end

	encode_primitive_array (a_array: SIMPLE_JSON_ARRAY; a_output: STRING_32)
			-- Encode array of primitives inline.
		require
			array_not_void: a_array /= Void
			output_not_void: a_output /= Void
		local
			i: INTEGER
			l_item: SIMPLE_JSON_VALUE
		do
			a_output.append_character (Open_bracket)
			a_output.append_integer (a_array.count)
			a_output.append ("]: ")
			from i := 1 until i > a_array.count loop
				if i > 1 then
					a_output.append_character (delimiter)
				end
				l_item := a_array.item (i)
				encode_value (l_item, 0, a_output)
				i := i + 1
			end
		end

	encode_tabular_array (a_array: SIMPLE_JSON_ARRAY; a_depth: INTEGER; a_output: STRING_32)
			-- Encode array of uniform objects in tabular format.
		require
			array_not_void: a_array /= Void
			output_not_void: a_output /= Void
			has_items: a_array.count > 0
		local
			l_keys: ARRAYED_LIST [STRING_32]
			l_first_obj: SIMPLE_JSON_OBJECT
			i, j: INTEGER
			l_item: SIMPLE_JSON_VALUE
			l_obj: SIMPLE_JSON_OBJECT
		do
			-- Get keys from first object
			l_first_obj := a_array.item (1).as_object
			l_keys := l_first_obj.keys

			-- Header: [N]{field1,field2}:
			a_output.append_character (Open_bracket)
			a_output.append_integer (a_array.count)
			a_output.append ("]{")
			from j := 1 until j > l_keys.count loop
				if j > 1 then
					a_output.append_character (delimiter)
				end
				a_output.append (l_keys [j])
				j := j + 1
			end
			a_output.append ("}:%N")

			-- Rows
			from i := 1 until i > a_array.count loop
				l_obj := a_array.item (i).as_object
				append_indent (a_depth + 1, a_output)
				from j := 1 until j > l_keys.count loop
					if j > 1 then
						a_output.append_character (delimiter)
					end
					if attached l_obj.item (l_keys [j]) as l_val then
						encode_value (l_val, 0, a_output)
					end
					j := j + 1
				end
				a_output.append_character ('%N')
				i := i + 1
			end
		end

	encode_list_array (a_array: SIMPLE_JSON_ARRAY; a_depth: INTEGER; a_output: STRING_32)
			-- Encode array as list with - prefix.
		require
			array_not_void: a_array /= Void
			output_not_void: a_output /= Void
		local
			i: INTEGER
			l_item: SIMPLE_JSON_VALUE
		do
			a_output.append_character (Open_bracket)
			a_output.append_integer (a_array.count)
			a_output.append ("]:%N")

			from i := 1 until i > a_array.count loop
				l_item := a_array.item (i)
				append_indent (a_depth + 1, a_output)
				a_output.append ("- ")
				if l_item.is_object then
					encode_object_inline (l_item.as_object, a_depth + 1, a_output)
				else
					encode_value (l_item, a_depth + 1, a_output)
					a_output.append_character ('%N')
				end
				i := i + 1
			end
		end

	encode_object (a_object: SIMPLE_JSON_OBJECT; a_depth: INTEGER; a_output: STRING_32)
			-- Encode object.
		require
			object_not_void: a_object /= Void
			output_not_void: a_output /= Void
		local
			l_keys: ARRAYED_LIST [STRING_32]
			l_key: STRING_32
			l_value: detachable SIMPLE_JSON_VALUE
			i: INTEGER
			l_is_first: BOOLEAN
		do
			l_keys := a_object.keys
			l_is_first := True

			from i := 1 until i > l_keys.count loop
				l_key := l_keys [i]
				l_value := a_object.item (l_key)

				if attached l_value then
					if not l_is_first then
						a_output.append_character ('%N')
					end
					l_is_first := False

					append_indent (a_depth, a_output)
					encode_key (l_key, a_output)
					a_output.append (": ")

					if l_value.is_object and then not l_value.as_object.is_empty then
						a_output.append_character ('%N')
						encode_object (l_value.as_object, a_depth + 1, a_output)
					elseif l_value.is_array then
						encode_array (l_value.as_array, a_depth, a_output)
					else
						encode_value (l_value, a_depth, a_output)
					end
				end
				i := i + 1
			end
		end

	encode_object_inline (a_object: SIMPLE_JSON_OBJECT; a_depth: INTEGER; a_output: STRING_32)
			-- Encode object starting inline after "- ".
		require
			object_not_void: a_object /= Void
			output_not_void: a_output /= Void
		local
			l_keys: ARRAYED_LIST [STRING_32]
			l_key: STRING_32
			l_value: detachable SIMPLE_JSON_VALUE
			i: INTEGER
		do
			l_keys := a_object.keys

			from i := 1 until i > l_keys.count loop
				l_key := l_keys [i]
				l_value := a_object.item (l_key)

				if attached l_value then
					if i > 1 then
						append_indent (a_depth + 1, a_output)
					end
					encode_key (l_key, a_output)
					a_output.append (": ")

					if l_value.is_object and then not l_value.as_object.is_empty then
						a_output.append_character ('%N')
						encode_object (l_value.as_object, a_depth + 2, a_output)
					elseif l_value.is_array then
						encode_array (l_value.as_array, a_depth + 1, a_output)
					else
						encode_value (l_value, a_depth + 1, a_output)
					end
					a_output.append_character ('%N')
				end
				i := i + 1
			end
		end

	encode_key (a_key: STRING_32; a_output: STRING_32)
			-- Encode object key.
		require
			key_not_void: a_key /= Void
			output_not_void: a_output /= Void
		do
			if is_valid_identifier (a_key) then
				a_output.append (a_key)
			else
				a_output.append_character (Quote)
				a_output.append (escape_string (a_key))
				a_output.append_character (Quote)
			end
		end

	append_indent (a_depth: INTEGER; a_output: STRING_32)
			-- Append indentation for given depth.
		require
			non_negative: a_depth >= 0
			output_not_void: a_output /= Void
		local
			i: INTEGER
		do
			from i := 1 until i > a_depth loop
				a_output.append (indent_string)
				i := i + 1
			end
		end

	is_primitive_array (a_array: SIMPLE_JSON_ARRAY): BOOLEAN
			-- Are all elements primitives (not objects or arrays)?
		require
			array_not_void: a_array /= Void
		local
			i: INTEGER
			l_item: SIMPLE_JSON_VALUE
		do
			Result := True
			from i := 1 until i > a_array.count or not Result loop
				l_item := a_array.item (i)
				Result := not l_item.is_object and not l_item.is_array
				i := i + 1
			end
		end

	is_tabular_array (a_array: SIMPLE_JSON_ARRAY): BOOLEAN
			-- Is array of uniform objects (same keys)?
		require
			array_not_void: a_array /= Void
		local
			l_first_keys: detachable ARRAYED_LIST [STRING_32]
			l_item: SIMPLE_JSON_VALUE
			i: INTEGER
		do
			if a_array.count >= 1 then
				Result := True
				from i := 1 until i > a_array.count or not Result loop
					l_item := a_array.item (i)
					if l_item.is_object then
						if l_first_keys = Void then
							l_first_keys := l_item.as_object.keys
							-- Also check values are primitives
							Result := has_primitive_values (l_item.as_object)
						else
							Result := keys_match (l_first_keys, l_item.as_object.keys)
								and then has_primitive_values (l_item.as_object)
						end
					else
						Result := False
					end
					i := i + 1
				end
			end
		end

	has_primitive_values (a_object: SIMPLE_JSON_OBJECT): BOOLEAN
			-- Are all values primitives?
		require
			object_not_void: a_object /= Void
		local
			l_keys: ARRAYED_LIST [STRING_32]
			i: INTEGER
			l_val: detachable SIMPLE_JSON_VALUE
		do
			Result := True
			l_keys := a_object.keys
			from i := 1 until i > l_keys.count or not Result loop
				l_val := a_object.item (l_keys [i])
				if attached l_val then
					Result := not l_val.is_object and not l_val.is_array
				end
				i := i + 1
			end
		end

	keys_match (a_keys1, a_keys2: ARRAYED_LIST [STRING_32]): BOOLEAN
			-- Do both lists have same keys in same order?
		require
			keys1_not_void: a_keys1 /= Void
			keys2_not_void: a_keys2 /= Void
		local
			i: INTEGER
		do
			if a_keys1.count = a_keys2.count then
				Result := True
				from i := 1 until i > a_keys1.count or not Result loop
					Result := a_keys1 [i].is_equal (a_keys2 [i])
					i := i + 1
				end
			end
		end

	needs_quoting (a_string: STRING_32): BOOLEAN
			-- Does string need to be quoted in TOON?
		require
			string_not_void: a_string /= Void
		do
			Result := a_string.is_empty
				or else a_string.item (1) = ' '
				or else a_string.item (a_string.count) = ' '
				or else a_string.is_equal (Keyword_true)
				or else a_string.is_equal (Keyword_false)
				or else a_string.is_equal (Keyword_null)
				or else looks_numeric (a_string)
				or else has_special_chars (a_string)
		end

	looks_numeric (a_string: STRING_32): BOOLEAN
			-- Does string look like a number?
		require
			string_not_void: a_string /= Void
		local
			l_first: CHARACTER_32
		do
			if not a_string.is_empty then
				l_first := a_string.item (1)
				Result := l_first.is_digit or l_first = '-' or l_first = '+'
			end
		end

	has_special_chars (a_string: STRING_32): BOOLEAN
			-- Does string contain characters requiring quoting?
		require
			string_not_void: a_string /= Void
		local
			i: INTEGER
			c: CHARACTER_32
		do
			from i := 1 until i > a_string.count or Result loop
				c := a_string.item (i)
				Result := c = Colon or c = Quote or c = Backslash
					or c = Open_bracket or c = Close_bracket
					or c = Open_brace or c = Close_brace
					or c = delimiter or c = '%N' or c = '%R' or c = '%T'
					or c = Hyphen and i = 1
					or c.natural_32_code < 32
				i := i + 1
			end
		end

	is_valid_identifier (a_string: STRING_32): BOOLEAN
			-- Is string a valid unquoted identifier?
		require
			string_not_void: a_string /= Void
		local
			i: INTEGER
			c: CHARACTER_32
		do
			if not a_string.is_empty then
				c := a_string.item (1)
				Result := c.is_alpha or c = '_'
				from i := 2 until i > a_string.count or not Result loop
					c := a_string.item (i)
					Result := c.is_alpha or c.is_digit or c = '_' or c = '.'
					i := i + 1
				end
			end
		end

	escape_string (a_string: STRING_32): STRING_32
			-- Escape special characters in string.
		require
			string_not_void: a_string /= Void
		local
			i: INTEGER
			c: CHARACTER_32
		do
			create Result.make (a_string.count)
			from i := 1 until i > a_string.count loop
				c := a_string.item (i)
				inspect c
				when '\' then
					Result.append ("\\")
				when '"' then
					Result.append ("\%"")
				when '%N' then
					Result.append ("\n")
				when '%R' then
					Result.append ("\r")
				when '%T' then
					Result.append ("\t")
				else
					Result.append_character (c)
				end
				i := i + 1
			end
		end

	format_number (a_number: REAL_64): STRING_32
			-- Format number using SIMPLE_DECIMAL for precision.
		local
			l_decimal: SIMPLE_DECIMAL
			l_int: INTEGER_64
		do
			-- Check if it's actually an integer
			l_int := a_number.truncated_to_integer_64
			if a_number = l_int.to_double then
				create Result.make (20)
				Result.append_integer_64 (l_int)
			else
				-- Use SIMPLE_DECIMAL for proper decimal representation
				create l_decimal.make_from_double (a_number)
				Result := l_decimal.to_string
			end
		end

invariant
	valid_indent: indent > 0
	valid_delimiter: delimiter = ',' or delimiter = '%T' or delimiter = '|'
	indent_string_attached: indent_string /= Void

end
