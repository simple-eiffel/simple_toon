note
	description: "Test application for SIMPLE_TOON"
	author: "Larry Rix"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run the tests.
		do
			print ("Running SIMPLE_TOON tests...%N%N")
			passed := 0
			failed := 0

			run_lib_tests

			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")

			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Test Runners

	run_lib_tests
		do
			create lib_tests
			-- Encoding tests
			run_test (agent lib_tests.test_encode_simple_object, "test_encode_simple_object")
			run_test (agent lib_tests.test_encode_nested_object, "test_encode_nested_object")
			run_test (agent lib_tests.test_encode_primitive_array, "test_encode_primitive_array")
			run_test (agent lib_tests.test_encode_tabular_array, "test_encode_tabular_array")
			run_test (agent lib_tests.test_encode_string_quoting, "test_encode_string_quoting")
			run_test (agent lib_tests.test_encode_special_values, "test_encode_special_values")
			-- Decoding tests
			run_test (agent lib_tests.test_decode_simple_object, "test_decode_simple_object")
			run_test (agent lib_tests.test_decode_nested_object, "test_decode_nested_object")
			run_test (agent lib_tests.test_decode_primitive_array, "test_decode_primitive_array")
			run_test (agent lib_tests.test_decode_tabular_array, "test_decode_tabular_array")
			run_test (agent lib_tests.test_decode_list_array, "test_decode_list_array")
			run_test (agent lib_tests.test_decode_special_values, "test_decode_special_values")
			run_test (agent lib_tests.test_decode_quoted_string, "test_decode_quoted_string")
			-- Round-trip tests
			run_test (agent lib_tests.test_roundtrip_simple, "test_roundtrip_simple")
			run_test (agent lib_tests.test_roundtrip_complex, "test_roundtrip_complex")
			-- Configuration tests
			run_test (agent lib_tests.test_tab_delimiter, "test_tab_delimiter")
			run_test (agent lib_tests.test_pipe_delimiter, "test_pipe_delimiter")
			run_test (agent lib_tests.test_custom_indent, "test_custom_indent")
			-- Analysis tests
			run_test (agent lib_tests.test_tabular_eligible, "test_tabular_eligible")
			run_test (agent lib_tests.test_not_tabular_eligible, "test_not_tabular_eligible")
			run_test (agent lib_tests.test_compression_ratio, "test_compression_ratio")
			-- Error tests
			run_test (agent lib_tests.test_strict_count_mismatch, "test_strict_count_mismatch")
			run_test (agent lib_tests.test_valid_toon_check, "test_valid_toon_check")
			-- String conversion tests
			run_test (agent lib_tests.test_json_to_toon_string, "test_json_to_toon_string")
			run_test (agent lib_tests.test_toon_to_json_string, "test_toon_to_json_string")
			-- TOON_BUILDER tests
			run_test (agent lib_tests.test_builder_simple_object, "test_builder_simple_object")
			run_test (agent lib_tests.test_builder_all_types, "test_builder_all_types")
			run_test (agent lib_tests.test_builder_tabular_array, "test_builder_tabular_array")
			run_test (agent lib_tests.test_builder_nested_object, "test_builder_nested_object")
			run_test (agent lib_tests.test_builder_simple_arrays, "test_builder_simple_arrays")
			run_test (agent lib_tests.test_builder_with_escaping, "test_builder_with_escaping")
			run_test (agent lib_tests.test_builder_reset, "test_builder_reset")
			run_test (agent lib_tests.test_builder_custom_delimiter, "test_builder_custom_delimiter")
			run_test (agent lib_tests.test_builder_fluent_chain, "test_builder_fluent_chain")
			run_test (agent lib_tests.test_builder_complex_structure, "test_builder_complex_structure")
		end

feature {NONE} -- Implementation

	lib_tests: LIB_TESTS

	passed: INTEGER
	failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test and update counters.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name + "%N")
			failed := failed + 1
			l_retried := True
			retry
		end

end
