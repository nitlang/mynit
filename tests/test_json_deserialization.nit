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

import test_deserialization
import json::serialization
#alt1# import test_deserialization_serial

var entities = new TestEntities

var tests = entities.without_generics#alt1##alt2#
#alt1#var tests = entities.with_generics
#alt2#var tests = entities.with_generics

for o in tests do
	var stream = new StringWriter
	var serializer = new JsonSerializer(stream)
	#alt2#serializer.plain_json = true
	serializer.serialize(o)

	var deserializer = new JsonDeserializer(stream.to_s)#alt2#
	var deserialized = deserializer.deserialize#alt2#

	print "# Nit:\n{o}\n"
	print "# Json:\n{stream}\n"
	print "# Back in Nit:\n{deserialized or else "null"}\n"#alt2#
end
