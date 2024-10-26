# This file is part of NIT ( http://www.nitlanguage.org ).
#
# This file is free software, which comes along with NIT.  This software is
# distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without  even  the implied warranty of  MERCHANTABILITY or  FITNESS FOR A
# PARTICULAR PURPOSE.  You can modify it is you want,  provided this header
# is kept unaltered, and a notification of the changes is added.
# You  are  allowed  to  redistribute it and sell it, alone or is a part of
# another product.

# Native structures for text and bytes
module native

import kernel
import math
import fixed_ints

in "C" `{
#ifdef __linux__
	#include <endian.h>
#endif
#ifdef __APPLE__
	#include <libkern/OSByteOrder.h>
	#define be32toh(x) OSSwapBigToHostInt32(x)
#endif
#ifdef _WIN32
	#define be32toh(val) _byteswap_ulong(val)
#endif

#ifndef be32toh
	#define be32toh(val) betoh32(val)
#endif

#include <assert.h>
#include <string.h>
`}

redef class Int
	# Gives the length of the UTF-8 char starting with `self`
	fun u8len: Int do
		if self & 0b1000_0000 == 0 then
			return 1
		else if self & 0b1110_0000 == 0b1100_0000 then
			return 2
		else if self & 0b1111_0000 == 0b1110_0000 then
			return 3
		else if self & 0b1111_1000 == 0b1111_0000 then
			return 4
		else
			return 1
		end
	end

	# Is `self` a valid UTF-8 sequence start ?
	#
	# ~~~nit
	# assert 0.is_valid_utf8_start
	# assert 0xC0.is_valid_utf8_start
	# assert 0xE0.is_valid_utf8_start
	# assert 0xF0.is_valid_utf8_start
	# ~~~
	fun is_valid_utf8_start: Bool do
		if self & 0x80 == 0 then return true
		if self & 0b1110_0000 == 0b1100_0000 then return true
		if self & 0b1111_0000 == 0b1110_0000 then return true
		if self & 0b1111_1000 == 0b1111_0000 then return true
		return false
	end
end

redef class UInt32
	# Returns the code_point from a utf16 surrogate pair
	#
	#     assert 0xD83DDE02u32.from_utf16_surr == 0x1F602u32
	fun from_utf16_surr: UInt32 do
		var hi = (self & 0xFFFF0000u32) >> 16
		var lo = self & 0xFFFFu32
		var cp = 0u32
		cp += (hi - 0xD800u32) << 10
		cp += lo - 0xDC00u32
		cp += 0x10000u32
		return cp
	end

	# The character which code point (unicode-wise) is `self`
	#
	#     assert 65u32.code_point == 'A'
	#     assert 10u32.code_point == '\n'
	#     assert 0x220Bu32.code_point == '∋'
	fun code_point: Char `{ return self; `}
end

# C string `char *`
#
# Used as underlying implementation for `String` and some other `Text`.
extern class CString `{ char* `}
	# Create a new `CString` with the capacity for `length` characters
	new(length: Int) is intern

	# Returns a null `char *`
	new nul `{ return NULL; `}

	# Get a char* starting at `index`.
	#
	# WARNING: Unsafe for extern code, use only for temporary
	# pointer manipulation purposes (e.g. write to file or such)
	fun fast_cstring(index: Int): CString is intern

	# Get char at `index`.
	fun [](index: Int): Int is intern

	# Set char `item` at index.
	fun []=(index: Int, item: Int) is intern

	# Copy `self` to `dest`.
	fun copy_to(dest: CString, length: Int, from: Int, to: Int) is intern

	redef fun ==(o) is intern do return is_same_instance(o)

	redef fun !=(o) is intern do return not is_same_instance(o)

	# Position of the first nul character.
	fun cstring_length: Int
	do
		var l = 0
		while self[l] != 0 do l += 1
		return l
	end

	# Parse `self` as an Int.
	fun atoi: Int is intern

	# Parse `self` as a Float.
	fun atof: Float `{ return atof(self); `}

	# Gets the UTF-8 char at index `pos`
	#
	# Index is expressed in Unicode chars
	#
	# ~~~raw
	#     assert "かきく".as(FlatString).items.char_at(0) == 'か'
	# ~~~
	#
	# If the char at position pos is an invalid Unicode char,
	# the Unicode replacement character � (0xFFFD) will be used.
	#
	# ~~~raw
	#     assert "かきく".as(FlatString).items.char_at(1) == '�'
	# ~~~
	fun char_at(pos: Int): Char do
		var c = self[pos]
		if c & 0x80 == 0 then return c.code_point
		var b = fetch_4_hchars(pos)
		var ret = 0u32
		if b & 0xC00000u32 != 0x800000u32 then return 0xFFFD.code_point
		if b & 0xE0000000u32 == 0xC0000000u32 then
			ret |= (b & 0x1F000000u32) >> 18
			ret |= (b & 0x3F0000u32) >> 16
			return ret.code_point
		end
		if not b & 0xC000u32 == 0x8000u32 then return 0xFFFD.code_point
		if b & 0xF0000000u32 == 0xE0000000u32 then
			ret |= (b & 0xF000000u32) >> 12
			ret |= (b & 0x3F0000u32) >> 10
			ret |= (b & 0x3F00u32) >> 8
			return ret.code_point
		end
		if not b & 0xC0u32 == 0x80u32 then return 0xFFFD.code_point
		if b & 0xF8000000u32 == 0xF0000000u32 then
			ret |= (b & 0x7000000u32) >> 6
			ret |= (b & 0x3F0000u32) >> 4
			ret |= (b & 0x3F00u32) >> 2
			ret |= b & 0x3Fu32
			return ret.code_point
		end
		return 0xFFFD.code_point
	end

	# Gets the byte index of char at position `n` in UTF-8 String
	fun char_to_byte_index(n: Int): Int do return char_to_byte_index_cached(n, 0, 0)

	# Gets the length of the character at position `pos` (1 if invalid sequence)
	fun length_of_char_at(pos: Int): Int do
		var c = self[pos]
		if c & 0x80 == 0x00 then
			return 1
		else if c & 0xE0 == 0xC0 and self[pos + 1] & 0xC0 == 0x80 then
			return 2
		else if c & 0xF0 == 0xE0 and self[pos + 1] & 0xC0 == 0x80 and self[pos + 2] & 0xC0 == 0x80 then
			return 3
		else if c & 0xF8 == 0xF0 and self[pos + 1] & 0xC0 == 0x80 and self[pos + 2] & 0xC0 == 0x80 and self[pos + 3] & 0xC0 == 0x80 then
			return 4
		else
			return 1
		end
	end

	# Gets the byte index of char at position `n` in UTF-8 String
	#
	# `char_from` and `byte_from` are cached values to seek from.
	#
	# NOTE: char_from and byte_from are not guaranteed to be valid cache values
	# It it up to the client to ensure the validity of the information
	fun char_to_byte_index_cached(n, char_from, byte_from: Int): Int do
		var ns_i = byte_from
		var my_i = char_from

		var dist = n - my_i

		while dist > 0 do
			while dist >= 4 do
				var i = fetch_4_chars(ns_i)
				if i & 0x80808080u32 != 0u32 then break
				ns_i += 4
				my_i += 4
				dist -= 4
			end
			if dist == 0 then break
			ns_i += length_of_char_at(ns_i)
			my_i += 1
			dist -= 1
		end

		while dist < 0 do
			while dist <= -4 do
				var i = fetch_4_chars(ns_i - 4)
				if i & 0x80808080u32 != 0u32 then break
				ns_i -= 4
				my_i -= 4
				dist += 4
			end
			if dist == 0 then break
			ns_i = find_beginning_of_char_at(ns_i - 1)
			my_i -= 1
			dist += 1
		end

		return ns_i
	end

	# Gets the char index of byte at position `n` in a UTF-8 String
	#
	# `char_from` and `byte_from` are cached values to seek from.
	#
	# NOTE: char_from and byte_from are not guaranteed to be valid cache values
	# It it up to the client to ensure the validity of the information
	fun byte_to_char_index_cached(n, char_from, byte_from: Int): Int do
		var ns_i = byte_from
		var my_i = char_from

		while ns_i < n do
			ns_i += length_of_char_at(ns_i)
			my_i += 1
		end

		while ns_i > n do
			ns_i = find_beginning_of_char_at(ns_i - 1)
			my_i -= 1
		end

		return my_i
	end

	# Returns the beginning position of the char at position `pos`
	#
	# If the char is invalid UTF-8, `pos` is returned as-is
	#
	# ~~~raw
	#	assert "abc".items.find_beginning_of_char_at(2) == 2
	#	assert "か".items.find_beginning_of_char_at(1) == 0
	#	assert [0x41, 233].to_s.items.find_beginning_of_char_at(1) == 1
	# ~~~
	fun find_beginning_of_char_at(pos: Int): Int do
		var endpos = pos
		var c = self[pos]
		if c & 0x80 == 0x00 then return pos
		while c & 0xC0 == 0x80 do
			pos -= 1
			c = self[pos]
		end
		var stpos = pos
		if length_of_char_at(stpos) >= (endpos - stpos + 1) then return pos
		return endpos
	end

	# Number of UTF-8 characters in `self` starting at `from`, for a length of `byte_length`
	fun utf8_length(from, byte_length: Int): Int is intern do
		var st = from
		var ln = 0
		while byte_length > 0 do
			while byte_length >= 4 do
				var i = fetch_4_chars(st)
				if i & 0x80808080u32 != 0u32 then break
				byte_length -= 4
				st += 4
				ln += 4
			end
			if byte_length == 0 then break
			var cln = length_of_char_at(st)
			st += cln
			ln += 1
			byte_length -= cln
		end
		return ln
	end

	# Fetch 4 chars in `self` at `pos`
	fun fetch_4_chars(pos: Int): UInt32 is intern `{ return *((uint32_t*)(self+pos)); `}

	# Fetch 4 chars in `self` at `pos`
	fun fetch_4_hchars(pos: Int): UInt32 is intern `{ return (uint32_t)be32toh(*((uint32_t*)(self+pos))); `}

	# Right shifts `len` bytes of `self` from `sh` bytes starting at position `pos`
	fun rshift(sh, len, pos: Int) do
		copy_to(self, len, pos, pos + sh)
	end

	# Left shifts `len` bytes of `self` from `sh` bytes starting at position `pos`
	fun lshift(sh, len, pos: Int) do
		copy_to(self, len, pos, pos - sh)
	end

	# Sets the contents of `self` to `value` for `len` bytes
	fun memset(value, len: Int) `{
		assert(len >= 0);
		memset(self, value, len);
	`}
end
