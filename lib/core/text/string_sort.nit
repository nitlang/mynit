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

# Locale-sensitive string sorting module including a `Collator` class and a `Array[String]` sorter
module string_sort is pkgconfig ("icu-io", "icu-i18n", "icu-uc")

intrude import u16_string
import core::collection::sorter
import locale

`{
	#include <unicode/utypes.h>
	#include <unicode/ucol.h>
`}

redef class String
	# Returns `self` <=> other considering a locale
	fun uni_compare_to (other : String, locale_name : nullable String) : Int
	do
		if locale_name == null then locale_name = default_locale

		var u16other = other.to_u16string

		var collator = new Collator(locale_name.to_cstring)
		var result = collator.collate(to_u16string.uchar_string, u16other.uchar_string, to_u16string.code_units , u16other.code_units)
		collator.free

		return result
	end
end

# Wrapper for ICU's `UCollator` structure
extern class Collator `{ UCollator * `}
	new (locale_name : CString) `{
		UErrorCode error = U_ZERO_ERROR;
		UCollator * collator = ucol_open(locale_name, &error);
		return collator;
	`}

	# Performs the collation of `str1` and `str2` and returns the result.
	# The collator returns `str1 <=> str2`.
	# ~~~raw
	#     var collator = new Collator("fr_FR")
	#     assert collator.collate("côte", "coté") == 1
	# ~~~
	fun collate(str1, str2 : UCharString, len1, len2 : Int) : Int `{
		UCollationResult collRes = ucol_strcoll(self, str1, len1, str2, len2);
		return collRes;
	`}

	redef fun free `{
		ucol_close(self);
	`}

end

# Sorter for `Array[String]`s
# ~~~raw
#     var words = ["cote", "coté", "côte", "côté""]
#     var frenchSorter = new StrSorter("fr_FR")
#     assert frenchSorter.sort(words) == ["cote", "côte", "coté", "côté"]
# ~~~
class StrSorter
	super Comparator

	var locale_name : String = ""

	init do end

	redef type COMPARED: String is fixed

	redef fun compare(a: String, b: String): Int
	do
		return a.uni_compare_to(b, locale_name)
	end
end
