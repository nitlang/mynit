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

# Enumeration of common locale names as well as default locale name
module locale is pkgconfig ("icu-io", "icu-i18n", "icu-uc")

`{
	#include <string.h>
	#include <unicode/uloc.h>
`}

private fun get_default_locale(locale: CString): Int `{
	const char * default_locale = uloc_getDefault();
	if (locale != NULL) {
		strcpy(locale, default_locale);
	}
	return strlen(default_locale);
`}

redef class Sys
	fun default_locale: String do
		var required_length = get_default_locale(new CString.nul)
		var locale = new CString(required_length + 1)
		get_default_locale(locale)
		return locale.to_s
	end
end
