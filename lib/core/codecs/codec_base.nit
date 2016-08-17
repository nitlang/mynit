# This file is part of NIT (http://www.nitlanguage.org).
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	 http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Base for codecs to use with streams
#
# A Codec (Coder/Decoder) is a tranformer from a byte-format to another
#
# As Nit Strings are UTF-8, a codec works as :
# - Coder: From a UTF-8 string to a specified format (writing)
# - Decoder: From a specified format to a UTF-8 string (reading)
module codec_base

import text
import bytes

# Codes/Decodes entities from/to UTF-8
abstract class Codec
	# Maximum size of a `character` in supported encoding
	fun char_max_size: Int is abstract

	# Transforms `c` to its representation in the format of `self`
	fun encode_char(c: Char): NativeString is abstract

	# Adds a char `c` to bytes `s`
	#
	# Returns the number of bytes written to `s`
	fun add_char_to(c: Char, s: NativeString): Int is abstract

	# Transforms `s` to the format of `self`
	fun encode_string(s: Text): Bytes is abstract

	# Encode a string using a fast path, used to avoid repeatedly instanciating
	# `Bytes` objects when writing text.
	fun fast_encode(str: FlatText, ln: Ref[Int]): NativeString is abstract

	# Adds a string `s` coded as the supported encoding to `b`
	#
	# Returns the number of bytes written to `b`
	fun add_string_to(s: Text, b: Bytes): Int is abstract

	# Adds a string `s` coded as the supported encoding to `ns`
	#
	# Returns the number of bytes written to `ns`
	#
	# NOTE: `ns` must be large enough to contain the encoded `s`
	fun add_str_to_ns(s: Text, ns: NativeString): Int is abstract

	# Size of a codet for the target encoding
	fun codet_size: Int is abstract

	# How many lookaheads might be required to decode a single char ?
	fun max_lookahead: Int is abstract

	# Is the sequence of bytes in `ns` at `position` a valid Char ?
	#
	# Returns either
	# * 0 if valid
	# * 1 if incomplete
	# * 2 if invalid
	fun is_valid_char(ns: NativeString, position: Int): Int is abstract

	# Decodes the first char from `b` to a Unicode code-point
	#
	# NOTE: Unsafe is `b` is too short for decoding a char, will go out of bounds.
	fun decode_char(b: NativeString): Char is abstract

	# Decodes a string `b` to UTF-8
	fun decode_string(b: NativeString, len: Int): String is abstract
end
