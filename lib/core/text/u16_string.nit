# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Wrapper of ICU's UTF-16 encoded strings and conversion
# This module is meant to ease the use of complex string operations provided by the ICU library.
# The module provides a wrapper for ICU's string structure : `UChar *` as well as conversion functions to/from `String`
module u16_string is pkgconfig ("icu-io", "icu-i18n", "icu-uc")

intrude import abstract_text
import core

`{
	#include <unicode/utypes.h>
	#include <unicode/ustring.h>
	#include <unicode/utf16.h>
`}


# UTF-16 encoded string
class U16String
	super Finalizable
	super Text

	# Pointer to a `UChar *` string
	private var uchar_string: UCharString

	# Number of code units (aka UTF-16 encoded code units or `UChar`) allocated to `uchar_string`
	private var capacity = 0

	# Number of code units actually in `uchar_string`.
	# `code_units` <= `capacity`.
	private var code_units = 0

	redef fun length: Int do return uchar_string.code_points(code_units)

	# Returns an empty `U16String` of capacity `cap` or a NULL `U16String` if no `cap` parameter is provided.
	# The `cap` argument is the number of code units (aka UTF-16 encoded characters or `UChar`) allocated to `uchar_string`.
	# If the number of code units is known in advance, it can be provided with the `units` parameter.
	init (cap: nullable Int, units: nullable Int) do
		if cap == null then
			uchar_string = new UCharString.nul
		else
			assert cap >= 0

			if not units == null then
				assert units <= cap
				code_units = units
			end

			uchar_string = new UCharString.empty(cap)
			capacity = cap
		end
	end

	# Returns a converted `U16String` from a `String`
	init from_string(source: String) do
		var csource = source.to_cstring
		var csource_length = source.byte_length

		uchar_string = new UCharString.nul
		var required_length = uchar_string.from_cstring(0, csource, csource_length)

		uchar_string = new UCharString.empty(required_length)
		uchar_string.from_cstring(required_length, csource, csource_length)

		capacity = required_length
		code_units = source.u16_length
	end

	# Copies the characters of `source` to `self`.
	# A maximum of `self.capacity` code units will be copied to `self`.
	# If a code point >0xFFFF has to be divided, it will not be copied.
	fun copy_from(source: String) do
		uchar_string.from_cstring(capacity, source.to_cstring, source.byte_length)

		code_units = source.u16_length
	end

	redef fun chars do return new U16StringCharView(self)

	redef fun[](index: Int): Char do
		assert index >= 0 and index < length
		var offset = 0
		var c = '\0'

		for i in [0..index] do
			c = uchar_string.char_at_offset(offset, code_units)
			if c.to_i > 0xFFFF then offset += 2 else offset +=1
		end
		return c
	end

	redef fun to_cstring: CString do
		var cself = new CString.nul
		var required_length = uchar_string.to_cstring(cself, 0, code_units)

		cself = new CString(required_length + 1)
		uchar_string.to_cstring(cself, required_length + 1, code_units)

		return cself
	end

	# Returns the number of UTF-8 code units (bytes) in `self`
	redef fun byte_length: Int do
		var offset = 0
		var l = 0
		var c = '\0'

		for i in chars do
			c = uchar_string.char_at_offset(offset, code_units)
			var b = c.to_i
			if b > 0xFFFF then offset += 2 else offset +=1

			if b <= 0x7F then
				l += 1
			else if b <= 0x7FF then
				l += 2
			else if b <= 0xD7FF or b > 0x10FFFF then
				l += 0
			else if b <= 0xFFFF then
				l += 3
			else
				l += 4
			end
		end
		return l
	end

	redef fun to_s: String do return to_cstring.to_s_with_length(byte_length)
	redef fun finalize do uchar_string.free
end

# ICU string `UChar *` which are UTF-16 strings
extern class UCharString `{ UChar *`}

	# Returns an empty `UCharString` of length `length`
	new empty (length: Int) `{
		UChar * str = (UChar *)malloc(sizeof(UChar) * length);
		u_memset(str, 0, length);
		return str;
	`}

	# Returns a `NULL` `UCharString`
	new nul `{ return NULL; `}

	# Returns the number of code points up to `code_units` characters
	fun code_points(code_units: Int): Int `{
		if (self == NULL) {
			return -1;
		}
		return u_countChar32(self, code_units);
	`}

	# Converts a `CString` to a `UCharString` and returns the required length of said `UCharString`
	fun from_cstring(dest_length: Int, source: CString, source_length: Int): Int `{
		UErrorCode error = U_ZERO_ERROR;
		int32_t res;
		u_strFromUTF8(self, dest_length, &res, source, source_length, &error);
		return res;
	`}

	# Converts `self` to a `CString` and returns the required length (without the termination character) of said `CString`
	fun to_cstring(dest: CString, dest_length: Int, source_length: Int): Int `{
		UErrorCode error = U_ZERO_ERROR;
		int32_t res;
		u_strToUTF8(dest, dest_length, &res, self, source_length, &error);
		return res;
	`}

	# Get code point at code unit `offset`
	fun char_at_offset(offset: Int, code_units: Int): Char `{
		UChar32 c = 0;
		U16_NEXT(self, offset, code_units, c);
		return c;
	`}
end

private class U16StringCharIterator
	super IndexedIterator[Char]

	var target: U16String

	var curr_pos: Int

	redef fun is_ok do return curr_pos < target.length

	redef fun item do return target[curr_pos]

	redef fun next do curr_pos += 1

	redef fun index do return curr_pos
end

private class U16StringCharReverseIterator
	super IndexedIterator[Char]

	var target: U16String

	var curr_pos: Int

	redef fun is_ok do return curr_pos >= 0

	redef fun item do return target[curr_pos]

	redef fun next do curr_pos -= 1

	redef fun index do return curr_pos
end

private class U16StringCharView
	super StringCharView

	redef type SELFTYPE: U16String

	redef fun [](index) do return target[index]

	redef fun iterator_from(start) do return new U16StringCharIterator(target, start)

	redef fun reverse_iterator_from(start) do return new U16StringCharReverseIterator(target, start)
end

redef class String
	# Returns a UTF-16 encoded version of `self`
	fun to_u16string: U16String do return new U16String.from_string(self)

	# Returns the number of UTF-16 code units in `self`
	fun u16_length: Int do
		var n = 0
		for c in chars do
			if c.to_i > 0xFFFF then n += 2 else n += 1
		end
		return n
	end
end
