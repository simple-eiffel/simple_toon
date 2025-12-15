note
	description: "Error information for TOON parsing/encoding"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_TOON_ERROR

inherit
	SIMPLE_TOON_CONSTANTS
		export
			{NONE} all
		redefine
			out
		end

create
	make,
	make_with_position,
	make_with_type

feature {NONE} -- Initialization

	make (a_message: STRING_32)
			-- Create error with message only.
		require
			message_not_empty: not a_message.is_empty
		do
			message := a_message
			line := 0
			column := 0
			error_type := Error_type_syntax
		ensure
			message_set: message = a_message
			no_position: line = 0 and column = 0
		end

	make_with_position (a_message: STRING_32; a_line, a_column: INTEGER)
			-- Create error with message and position.
		require
			message_not_empty: not a_message.is_empty
			valid_line: a_line >= 0
			valid_column: a_column >= 0
		do
			message := a_message
			line := a_line
			column := a_column
			error_type := Error_type_syntax
		ensure
			message_set: message = a_message
			line_set: line = a_line
			column_set: column = a_column
		end

	make_with_type (a_message: STRING_32; a_line, a_column, a_type: INTEGER)
			-- Create error with message, position, and type.
		require
			message_not_empty: not a_message.is_empty
			valid_line: a_line >= 0
			valid_column: a_column >= 0
		do
			message := a_message
			line := a_line
			column := a_column
			error_type := a_type
		ensure
			message_set: message = a_message
			line_set: line = a_line
			column_set: column = a_column
			type_set: error_type = a_type
		end

feature -- Access

	message: STRING_32
			-- Error message

	line: INTEGER
			-- Line number (1-based, 0 if unknown)

	column: INTEGER
			-- Column number (1-based, 0 if unknown)

	error_type: INTEGER
			-- Type of error (see SIMPLE_TOON_CONSTANTS)

feature -- Queries

	has_position: BOOLEAN
			-- Is position information available?
		do
			Result := line > 0
		ensure
			definition: Result = (line > 0)
		end

	type_name: STRING_32
			-- Human-readable error type name
		do
			inspect error_type
			when Error_type_syntax then
				Result := "Syntax error"
			when Error_type_delimiter then
				Result := "Delimiter error"
			when Error_type_count_mismatch then
				Result := "Array count mismatch"
			when Error_type_invalid_escape then
				Result := "Invalid escape sequence"
			when Error_type_unterminated_string then
				Result := "Unterminated string"
			when Error_type_indentation then
				Result := "Indentation error"
			else
				Result := "Error"
			end
		end

feature -- Output

	to_string: STRING_32
			-- Error as formatted string
		do
			create Result.make (50)
			Result.append (type_name)
			if has_position then
				Result.append (" at line ")
				Result.append_integer (line)
				Result.append (", column ")
				Result.append_integer (column)
			end
			Result.append (": ")
			Result.append (message)
		end

	out: STRING
			-- <Precursor>
		do
			Result := to_string.to_string_8
		end

invariant
	message_attached: message /= Void
	message_not_empty: not message.is_empty
	non_negative_line: line >= 0
	non_negative_column: column >= 0

end
