note
	description: "Tests for SIMPLE_TOON"
	author: "Larry Rix"
	testing: "covers"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature -- Test Objects

	toon: SIMPLE_TOON
		attribute
			create Result.make
		end

	json: SIMPLE_JSON
		attribute
			create Result
		end

feature -- Encoding Tests

	test_encode_simple_object
			-- Test encoding a simple object.
		local
			l_obj: SIMPLE_JSON_OBJECT
			l_result: STRING_32
		do
			l_obj := json.new_object
			l_obj.put_string ("Alice", "name").do_nothing
			l_obj.put_integer (30, "age").do_nothing

			l_result := toon.encode (l_obj)

			assert ("contains name", l_result.has_substring ("name: Alice"))
			assert ("contains age", l_result.has_substring ("age: 30"))
			assert ("no braces", not l_result.has ('{'))
		end

	test_encode_nested_object
			-- Test encoding nested objects.
		local
			l_obj, l_address: SIMPLE_JSON_OBJECT
			l_result: STRING_32
		do
			l_obj := json.new_object
			l_obj.put_string ("Bob", "name").do_nothing

			l_address := json.new_object
			l_address.put_string ("NYC", "city").do_nothing
			l_address.put_string ("10001", "zip").do_nothing
			l_obj.put_object (l_address, "address").do_nothing

			l_result := toon.encode (l_obj)

			assert ("contains address", l_result.has_substring ("address:"))
			assert ("contains city", l_result.has_substring ("city: NYC"))
			assert ("indented", l_result.has_substring ("  city"))
		end

	test_encode_primitive_array
			-- Test encoding array of primitives.
		local
			l_arr: SIMPLE_JSON_ARRAY
			l_result: STRING_32
		do
			l_arr := json.new_array
			l_arr.add_string ("red").do_nothing
			l_arr.add_string ("green").do_nothing
			l_arr.add_string ("blue").do_nothing

			l_result := toon.encode (l_arr)

			assert ("has count", l_result.has_substring ("[3]"))
			assert ("has values", l_result.has_substring ("red"))
			assert ("inline format", l_result.has_substring ("]: "))
		end

	test_encode_tabular_array
			-- Test encoding uniform object array as tabular.
		local
			l_arr: SIMPLE_JSON_ARRAY
			l_obj1, l_obj2: SIMPLE_JSON_OBJECT
			l_result: STRING_32
		do
			l_arr := json.new_array

			l_obj1 := json.new_object
			l_obj1.put_string ("A1", "sku").do_nothing
			l_obj1.put_integer (10, "qty").do_nothing
			l_arr.add_object (l_obj1).do_nothing

			l_obj2 := json.new_object
			l_obj2.put_string ("B2", "sku").do_nothing
			l_obj2.put_integer (20, "qty").do_nothing
			l_arr.add_object (l_obj2).do_nothing

			l_result := toon.encode (l_arr)

			assert ("has count", l_result.has_substring ("[2]"))
			assert ("has fields", l_result.has_substring ("{sku,qty}"))
			assert ("has data row", l_result.has_substring ("A1,10"))
		end

	test_encode_string_quoting
			-- Test that strings requiring quotes are quoted.
		local
			l_obj: SIMPLE_JSON_OBJECT
			l_result: STRING_32
		do
			l_obj := json.new_object
			l_obj.put_string ("hello: world", "msg").do_nothing
			l_obj.put_string ("true", "bool_str").do_nothing
			l_obj.put_string ("123", "num_str").do_nothing

			l_result := toon.encode (l_obj)

			assert ("colon quoted", l_result.has_substring ("%"hello: world%""))
			assert ("true quoted", l_result.has_substring ("%"true%""))
			assert ("number quoted", l_result.has_substring ("%"123%""))
		end

	test_encode_special_values
			-- Test encoding null, boolean, numbers.
			-- Using SIMPLE_DECIMAL for proper decimal representation.
		local
			l_obj: SIMPLE_JSON_OBJECT
			l_result: STRING_32
			l_price: SIMPLE_DECIMAL
		do
			create l_price.make ("19.99")

			l_obj := json.new_object
			l_obj.put_null ("nothing").do_nothing
			l_obj.put_boolean (True, "active").do_nothing
			l_obj.put_boolean (False, "deleted").do_nothing
			l_obj.put_decimal (l_price, "price").do_nothing

			l_result := toon.encode (l_obj)

			assert ("null encoded", l_result.has_substring ("nothing: null"))
			assert ("true encoded", l_result.has_substring ("active: true"))
			assert ("false encoded", l_result.has_substring ("deleted: false"))
			assert ("number encoded", l_result.has_substring ("price: 19.99"))
		end

feature -- Decoding Tests

	test_decode_simple_object
			-- Test decoding a simple object.
		local
			l_toon_text: STRING_32
			l_value: detachable SIMPLE_JSON_VALUE
		do
			l_toon_text := "name: Alice%Nage: 30"
			l_value := toon.decode (l_toon_text)

			assert ("decoded", l_value /= Void)
			if attached l_value as v then
				assert ("is object", v.is_object)
				assert ("has name", attached v.as_object.string_item ("name") as n and then n.is_equal ("Alice"))
				assert ("has age", v.as_object.integer_item ("age") = 30)
			end
		end

	test_decode_nested_object
			-- Test decoding nested objects.
		local
			l_toon_text: STRING_32
			l_value: detachable SIMPLE_JSON_VALUE
		do
			l_toon_text := "person:%N  name: Bob%N  address:%N    city: NYC"
			l_value := toon.decode (l_toon_text)

			assert ("decoded", l_value /= Void)
			if attached l_value as v and then v.is_object then
				if attached v.as_object.item ("person") as person and then person.is_object then
					assert ("has name", attached person.as_object.string_item ("name"))
					if attached person.as_object.item ("address") as addr and then addr.is_object then
						assert ("has city", attached addr.as_object.string_item ("city") as c and then c.is_equal ("NYC"))
					else
						assert ("has address object", False)
					end
				else
					assert ("has person object", False)
				end
			end
		end

	test_decode_primitive_array
			-- Test decoding inline primitive array.
		local
			l_toon_text: STRING_32
			l_value: detachable SIMPLE_JSON_VALUE
		do
			l_toon_text := "[3]: red,green,blue"
			l_value := toon.decode (l_toon_text)

			assert ("decoded", l_value /= Void)
			if attached l_value as v then
				assert ("is array", v.is_array)
				assert ("count 3", v.as_array.count = 3)
				assert ("first is red", attached v.as_array.item (1).as_string_32 as s and then s.is_equal ("red"))
			end
		end

	test_decode_tabular_array
			-- Test decoding tabular array format.
		local
			l_toon_text: STRING_32
			l_value: detachable SIMPLE_JSON_VALUE
		do
			l_toon_text := "[2]{sku,qty}:%N  A1,10%N  B2,20"
			l_value := toon.decode (l_toon_text)

			assert ("decoded", l_value /= Void)
			if attached l_value as v then
				assert ("is array", v.is_array)
				assert ("count 2", v.as_array.count = 2)
				if attached v.as_array.item (1) as first and then first.is_object then
					assert ("first sku", attached first.as_object.string_item ("sku") as s and then s.is_equal ("A1"))
					assert ("first qty", first.as_object.integer_item ("qty") = 10)
				end
			end
		end

	test_decode_list_array
			-- Test decoding list array with - items.
		local
			l_toon_text: STRING_32
			l_value: detachable SIMPLE_JSON_VALUE
		do
			l_toon_text := "[2]:%N  - id: 1%N    name: Alice%N  - id: 2%N    name: Bob"
			l_value := toon.decode (l_toon_text)

			assert ("decoded", l_value /= Void)
			if attached l_value as v then
				assert ("is array", v.is_array)
				assert ("count 2", v.as_array.count = 2)
			end
		end

	test_decode_special_values
			-- Test decoding null, boolean, numbers.
		local
			l_toon_text: STRING_32
			l_value: detachable SIMPLE_JSON_VALUE
		do
			l_toon_text := "nothing: null%Nactive: true%Ndeleted: false%Nprice: 19.99"
			l_value := toon.decode (l_toon_text)

			assert ("decoded", l_value /= Void)
			if attached l_value as v and then v.is_object then
				assert ("null value", v.as_object.item ("nothing") /= Void and then attached v.as_object.item ("nothing") as n and then n.is_null)
				assert ("true value", v.as_object.boolean_item ("active") = True)
				assert ("false value", v.as_object.boolean_item ("deleted") = False)
				assert ("number value", v.as_object.real_item ("price") > 19.0)
			end
		end

	test_decode_quoted_string
			-- Test decoding quoted strings.
		local
			l_toon_text: STRING_32
			l_value: detachable SIMPLE_JSON_VALUE
		do
			l_toon_text := "msg: %"hello: world%""
			l_value := toon.decode (l_toon_text)

			assert ("decoded", l_value /= Void)
			if attached l_value as v and then v.is_object then
				assert ("has msg", attached v.as_object.string_item ("msg") as m and then m.is_equal ("hello: world"))
			end
		end

feature -- Round-trip Tests

	test_roundtrip_simple
			-- Test encode then decode returns equivalent.
		local
			l_obj: SIMPLE_JSON_OBJECT
			l_toon_text: STRING_32
			l_decoded: detachable SIMPLE_JSON_VALUE
		do
			l_obj := json.new_object
			l_obj.put_string ("Test", "name").do_nothing
			l_obj.put_integer (42, "value").do_nothing

			l_toon_text := toon.encode (l_obj)
			l_decoded := toon.decode (l_toon_text)

			assert ("roundtrip ok", l_decoded /= Void)
			if attached l_decoded as d and then d.is_object then
				assert ("name matches", attached d.as_object.string_item ("name") as n and then n.is_equal ("Test"))
				assert ("value matches", d.as_object.integer_item ("value") = 42)
			end
		end

	test_roundtrip_complex
			-- Test roundtrip with nested structure.
		local
			l_obj, l_inner: SIMPLE_JSON_OBJECT
			l_arr: SIMPLE_JSON_ARRAY
			l_toon_text: STRING_32
			l_decoded: detachable SIMPLE_JSON_VALUE
		do
			l_obj := json.new_object
			l_obj.put_string ("test", "type").do_nothing

			l_inner := json.new_object
			l_inner.put_integer (10, "x").do_nothing
			l_inner.put_integer (20, "y").do_nothing
			l_obj.put_object (l_inner, "pos").do_nothing

			l_arr := json.new_array
			l_arr.add_string ("a").do_nothing
			l_arr.add_string ("b").do_nothing
			l_obj.put_array (l_arr, "tags").do_nothing

			l_toon_text := toon.encode (l_obj)
			l_decoded := toon.decode (l_toon_text)

			assert ("roundtrip ok", l_decoded /= Void)
		end

feature -- Configuration Tests

	test_tab_delimiter
			-- Test using tab as delimiter.
		local
			l_arr: SIMPLE_JSON_ARRAY
			l_result: STRING_32
		do
			toon.set_delimiter ('%T')
			l_arr := json.new_array
			l_arr.add_string ("a").do_nothing
			l_arr.add_string ("b").do_nothing
			l_arr.add_string ("c").do_nothing

			l_result := toon.encode (l_arr)

			assert ("has tabs", l_result.has ('%T'))

			-- Reset
			toon.set_delimiter (',')
		end

	test_pipe_delimiter
			-- Test using pipe as delimiter.
		local
			l_arr: SIMPLE_JSON_ARRAY
			l_result: STRING_32
		do
			toon.set_delimiter ('|')
			l_arr := json.new_array
			l_arr.add_string ("x").do_nothing
			l_arr.add_string ("y").do_nothing

			l_result := toon.encode (l_arr)

			assert ("has pipes", l_result.has ('|'))

			-- Reset
			toon.set_delimiter (',')
		end

	test_custom_indent
			-- Test custom indentation.
		local
			l_obj, l_inner: SIMPLE_JSON_OBJECT
			l_result: STRING_32
		do
			toon.set_indent (4)
			l_obj := json.new_object
			l_inner := json.new_object
			l_inner.put_string ("val", "key").do_nothing
			l_obj.put_object (l_inner, "nested").do_nothing

			l_result := toon.encode (l_obj)

			assert ("4 space indent", l_result.has_substring ("    key"))

			-- Reset
			toon.set_indent (2)
		end

feature -- Analysis Tests

	test_tabular_eligible
			-- Test tabular eligibility detection.
		local
			l_arr: SIMPLE_JSON_ARRAY
			l_obj1, l_obj2: SIMPLE_JSON_OBJECT
		do
			l_arr := json.new_array

			l_obj1 := json.new_object
			l_obj1.put_string ("1", "a").do_nothing
			l_obj1.put_string ("2", "b").do_nothing
			l_arr.add_object (l_obj1).do_nothing

			l_obj2 := json.new_object
			l_obj2.put_string ("3", "a").do_nothing
			l_obj2.put_string ("4", "b").do_nothing
			l_arr.add_object (l_obj2).do_nothing

			assert ("is tabular eligible", toon.is_tabular_eligible (l_arr))
		end

	test_not_tabular_eligible
			-- Test non-uniform array is not tabular eligible.
		local
			l_arr: SIMPLE_JSON_ARRAY
			l_obj1, l_obj2: SIMPLE_JSON_OBJECT
		do
			l_arr := json.new_array

			l_obj1 := json.new_object
			l_obj1.put_string ("1", "a").do_nothing
			l_arr.add_object (l_obj1).do_nothing

			l_obj2 := json.new_object
			l_obj2.put_string ("2", "b").do_nothing
			l_arr.add_object (l_obj2).do_nothing

			assert ("not tabular eligible", not toon.is_tabular_eligible (l_arr))
		end

	test_compression_ratio
			-- Test compression ratio calculation.
		local
			l_obj: SIMPLE_JSON_OBJECT
			l_ratio: REAL_64
		do
			l_obj := json.new_object
			l_obj.put_string ("test", "name").do_nothing
			l_obj.put_integer (123, "value").do_nothing

			l_ratio := toon.compression_ratio (l_obj)

			assert ("ratio positive", l_ratio > 0.0)
			assert ("ratio reasonable", l_ratio < 2.0)
		end

feature -- Error Tests

	test_strict_count_mismatch
			-- Test strict mode catches count mismatch.
		local
			l_toon_text: STRING_32
			l_value: detachable SIMPLE_JSON_VALUE
		do
			toon.set_strict_mode (True)
			l_toon_text := "[5]: a,b,c"

			l_value := toon.decode (l_toon_text)

			assert ("has errors", toon.has_errors)

			toon.clear_errors
		end

	test_valid_toon_check
			-- Test is_valid_toon.
		do
			assert ("valid simple", toon.is_valid_toon ("name: test"))
			assert ("valid array", toon.is_valid_toon ("[2]: a,b"))
		end

feature -- String Conversion Tests

	test_json_to_toon_string
			-- Test JSON string to TOON string conversion.
		local
			l_json_str: STRING_32
			l_toon_str: detachable STRING_32
		do
			l_json_str := "{%"name%": %"Alice%", %"age%": 30}"
			l_toon_str := toon.json_to_toon (l_json_str)

			assert ("converted", l_toon_str /= Void)
			if attached l_toon_str as t then
				assert ("has name", t.has_substring ("name: Alice"))
				assert ("has age", t.has_substring ("age: 30"))
			end
		end

	test_toon_to_json_string
			-- Test TOON string to JSON string conversion.
		local
			l_toon_str: STRING_32
			l_json_str: detachable STRING_32
		do
			l_toon_str := "name: Bob%Nage: 25"
			l_json_str := toon.toon_to_json (l_toon_str)

			assert ("converted", l_json_str /= Void)
			if attached l_json_str as j then
				assert ("is json", j.has ('{') and j.has ('}'))
				assert ("has name", j.has_substring ("%"name%""))
			end
		end

end
