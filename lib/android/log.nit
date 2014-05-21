# This file is part of NIT (http://www.nitlanguage.org).
#
# Copyright 2014 Alexis Laferrière <alexis.laf@xymus.net>
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

# Advanced Android logging services
module log

import platform

in "C" `{
	#include <android/log.h>
`}

# Default Android log priority
protected fun priority_default: Int do return 1

# Verbose Android log priority
protected fun priority_verbose: Int do return 2

# Debug Android log priority
protected fun priority_debug: Int do return 3

# Info Android log priority
protected fun priority_info: Int do return 4

# Warn Android log priority
protected fun priority_warn: Int do return 5

# Error Android log priority
protected fun priority_error: Int do return 6

# Fatal Android log priority
protected fun priority_fatal: Int do return 7

# Silent Android log priority
protected fun priority_silent: Int do return 8

# Write `text` to Android log at priority `level` with tag `tag`
protected fun log_write(level: Int, tag, text: NativeString) `{
	__android_log_write(level, tag, text);
`}
