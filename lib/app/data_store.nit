# This file is part of NIT ( http://www.nitlanguage.org ).
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

# Simple data storage services
#
# The implementation varies per platform.
module data_store

import app_base
import serialization

# Platform variations
# TODO: move on the platform once qualified names are understand in the condition
import linux::data_store is conditional(linux)
import android::data_store is conditional(android)

redef class App
	# Services to store and load data
	fun data_store: DataStore is abstract
end

# Simple data storage facility
interface DataStore

	# Get the object stored at `key`, or null if nothing is available
	fun [](key: String): nullable Object is abstract

	# Store `value` at `key`
	fun []=(key: String, value: nullable Serializable) is abstract
end
