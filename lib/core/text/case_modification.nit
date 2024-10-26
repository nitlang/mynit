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

# Locale-sensitive case modification (lowercasing, uppercasing and titlecasing)
module case_modification is pkgconfig ("icu-io", "icu-i18n", "icu-uc")

intrude import u16_string
import locale

`{
	#include <unicode/utypes.h>
	#include <unicode/ustring.h>
`}

redef class U16String
	# Returns an uppercased `U16String` from `self` considering a `locale`
	fun uni_to_upper(locale : CString) : U16String
	do
		var required_length = uchar_string.uni_to_upper(new UCharString.nul, 0, locale, code_units)
		var result = new U16String(required_length + 1, required_length + 1)
		uchar_string.uni_to_upper(result.uchar_string, result.capacity , locale, code_units)
		return result
	end

	# Returns an lowercased `U16String` from `self` considering a `locale`
	fun uni_to_lower(locale : CString) : U16String
	do
		var required_length = uchar_string.uni_to_lower(new UCharString.nul, 0, locale, code_units)
		var result = new U16String(required_length + 1, required_length + 1)
		uchar_string.uni_to_lower(result.uchar_string, result.capacity , locale, code_units)
		return result
	end

	# Returns an titlecased `U16String` from `self` considering a `locale`
	fun uni_to_title(locale : CString) : U16String
	do
		var required_length = uchar_string.uni_to_title(new UCharString.nul, 0, locale, code_units)
		var result = new U16String(required_length + 1, required_length + 1)
		uchar_string.uni_to_title(result.uchar_string, result.capacity , locale, code_units)
		return result
	end
end

redef class UCharString
	# Returns the number of code units required for the uppercased `UCharString` from `self` and writes the resulting `UCharString` in `dest`
	fun uni_to_upper(dest : UCharString, dest_cap : Int, locale : CString, src_length : Int) : Int `{
		UErrorCode error = U_ZERO_ERROR;
		int32_t res = u_strToUpper(dest, dest_cap, self, src_length, locale, &error);
		return res;
	`}

	# Returns the number of code units required for the lowercased `UCharString` from `self` and writes the resulting `UCharString` in `dest`
	fun uni_to_lower(dest : UCharString, dest_cap : Int, locale : CString, src_length : Int) : Int `{
		UErrorCode error = U_ZERO_ERROR;
		int32_t res = u_strToLower(dest, dest_cap, self, src_length, locale, &error);
		return res;
	`}

	# Returns the number of code units required for the titlecased `UCharString` from `self` and writes the resulting `UCharString` in `dest`
	fun uni_to_title(dest : UCharString, dest_cap : Int, locale : CString, src_length : Int) : Int `{
		UErrorCode error = U_ZERO_ERROR;
		int32_t res = u_strToTitle(dest, dest_cap, self, src_length, NULL, locale, &error);
		return res;
	`}
end

redef class String
	# Returns an uppercased `String` from `self` considering an optional `locale` parameter
	#
	# ~~~raw
	#     assert "kedi".uni_to_upper("tr_TR") == "KEDİ"
	#     assert "kedi".uni_to_upper("en_US") != "KEDİ"
	# ~~~
	fun uni_to_upper(locale : nullable String) : String
	do
		if locale == null then locale = default_locale
		return to_u16string.uni_to_upper(locale.to_cstring).to_s
	end

	# Returns a lowercased `String` from `self` considering an optional `locale` parameter
	#
	# ~~~raw
	#     assert "YAZIM".uni_to_lower("tr_TR") == "yazım"
	#     assert "YAZIM".uni_to_lower("en_US") != "yazım"
	# ~~~
	fun uni_to_lower(locale : nullable String) : String
	do
		if locale == null then locale = default_locale
		return to_u16string.uni_to_lower(locale.to_cstring).to_s
	end

	# Returns a titlecased `String` from `self` considering an optional `locale` parameter
	#
	# ~~~raw
	#     assert "istanbul".uni_to_upper("tr_TR") == "İstanbul"
	#     assert "istanbul".uni_to_upper("en_US") != "Istanbul"
	# ~~~
	fun uni_to_title(locale : nullable String) : String
	do
		if locale == null then locale = default_locale
		return to_u16string.uni_to_title(locale.to_cstring).to_s
	end
end
