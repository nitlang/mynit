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

# Locale-sensitive number and date formatting module
module formatting is pkgconfig ("icu-io", "icu-i18n", "icu-uc")

intrude import u16_string
import date
import locale

`{
	#include <unicode/utypes.h>
	#include <unicode/ustring.h>
	#include <unicode/unum.h>
	#include <unicode/udat.h>
	#include <time.h>
`}

# Wrapper for ICU's `UNumberFormatStyle` enum.
# There are 6 styles available : decimal, percent, ordinal, currency and spellout.
extern class NumberFormatStyle `{ UNumberFormatStyle `}
	new (style : CString) `{
		if (!strcmp(style, "decimal")) {
			return UNUM_DECIMAL;
		} else if (!strcmp(style, "percent")) {
			return UNUM_PERCENT;
		} else if (!strcmp(style, "scientific")) {
			return UNUM_SCIENTIFIC;
		} else if (!strcmp(style, "ordinal")) {
			return UNUM_ORDINAL;
		} else if (!strcmp(style, "currency")) {
			return UNUM_CURRENCY;
		} else if (!strcmp(style, "spellout")) {
			return UNUM_SPELLOUT;
		} else {
			return UNUM_DEFAULT;
		}
	`}
end

# Wrapper for ICU's `UDateFormatStyle` enum.
# There are 4 styles available : full, long, medium and short.
extern class DateFormatStyle `{ UDateFormatStyle `}
	new (style : CString) `{
		if (!strcmp(style, "full")) {
			return UDAT_FULL;
		} else if (!strcmp(style, "long")) {
			return UDAT_LONG;
		} else if (!strcmp(style, "medium")) {
			return UDAT_MEDIUM;
		} else if (!strcmp(style, "short")) {
			return UDAT_SHORT;
		} else {
			return UDAT_DEFAULT;
		}
	`}
end

# Wrapper for ICU's `UNumberFormat` structure
extern class NumberFormatter `{ UNumberFormat * `}
	new (locale_name : CString, style : NumberFormatStyle) `{
		UErrorCode error = U_ZERO_ERROR;
		UNumberFormat* numberFormatter = unum_open(style, NULL, -1, locale_name, NULL, &error);
		return numberFormatter;
		`}

	# Returns a formatted `UCharString` from a `Float`
	fun format (number : Float, dest : UCharString, dest_length : Int) : Int `{
		UErrorCode error = U_ZERO_ERROR;
		UFieldPosition pos;

		uint32_t required_length = unum_formatDouble(self, number, dest, dest_length, &pos, &error);
		return required_length;
		`}

	redef fun free `{
		unum_close(self);
	`}
end

# Wrapper for ICU's `UDateFormat` structure
extern class TimeFormatter `{ UDateFormat *`}
	new (locale_name : CString, style : DateFormatStyle) `{
		UErrorCode error = U_ZERO_ERROR;
		UDateFormat * dateFormatter = udat_open(style, UDAT_NONE, locale_name, NULL, -1, NULL, -1, &error);
		return dateFormatter;
	`}

	# Returns a formatted `UCharString` from a `Int` (date in miliseconds)
	fun format(time : Int, dest : UCharString, dest_length : Int) : Int `{
		UErrorCode error = U_ZERO_ERROR;
		extern long timezone;
		tzset();
		UDate date = time + timezone * 1000;

		uint32_t required_length = udat_format(self, date, dest, dest_length, NULL, &error);
		return required_length;
	`}

	redef fun free `{
		udat_close(self);
	`}
end

redef class Float
	# Returns a formatted `String` from `self` considering a locale and a style.
	# There are 6 styles available : decimal, percent, ordinal, currency and spellout.
	# ~~~raw
	#     assert 12.7.format("spellout", "en_US") == "twelve point seven"
	# ~~~
	fun format(style : String, locale_name : nullable String) : String
	do
		if locale_name == null then locale_name = default_locale

		var nf = new NumberFormatter(locale_name.to_cstring, new NumberFormatStyle(style.to_cstring))
		var required_length = nf.format(self, new UCharString.nul, 0)
		var result = new U16String(required_length + 1, required_length + 1)
		nf.format(self, result.uchar_string, result.capacity)
		nf.free
		return result.to_s
	end
end

redef class Int
	# Returns a formatted `String` from `self` considering a locale and a style.
	# There are 6 styles available : decimal, percent, ordinal, currency and spellout.
	# ~~~raw
	#     assert 12.format("spellout", "en_US") == "twelve"
	# ~~~
	fun format(style : String, locale_name : nullable String) : String
	do
		return to_f.format(style, locale_name)
	end
end

redef class Time
	redef fun to_s : String do return format("", default_locale)

	# Returns the number of miliseconds in `self`
	# ~~~raw
	#     var time = new Time(5,5,5)
	#     assert time.to_ms == 18305000
	# ~~~
	fun to_ms : Int
	do
		var h = hour * 60 * 60 * 1000
		var m = minute * 60 * 1000
		var s = second * 1000

		return h + m + s
	end

	# Returns a formatted `String` from `self` considring a locale and a style.
	# There are 4 styles available : full, long, medium and short.
	# ~~~raw
	#     var time = new Time(5,5,5)
	#     assert time.format("full", "en_US") == "5:05:05 AM"
	# ~~~
	fun format(style : String, locale_name : nullable String) : String
	do
		if locale_name == null then locale_name = default_locale

		var df = new TimeFormatter(locale_name.to_cstring, new DateFormatStyle(style.to_cstring))
		var required_length = df.format(to_ms, new UCharString.nul, 0)
		var result = new U16String(required_length + 1, required_length + 1)
		df.format(to_ms, result.uchar_string, required_length + 1)
		df.free
		return result.to_s
	end
end
