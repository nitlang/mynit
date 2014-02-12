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

module json_serialization

import serialization

class JsonSerializer
	super Serializer

	# Target writing stream
	var stream: OStream

	init(stream: OStream) do self.stream = stream

	redef fun serialize(object)
	do
		if object == null then
			stream.write "null"
		else object.serialize_to_json(self)
	end

	redef fun serialize_attribute(name, value)
	do
		stream.write ", \"{name}\": "
		super
	end

	redef fun serialize_reference(object)
	do
		if refs_map.keys.has(object) then
			# if already serialized, add local reference
			var id = ref_id_for(object)
			stream.write "\{\"__kind\": \"ref\", \"__id\": {id}\}"
		else
			# serialize here
			serialize object
		end
	end

	# Map of references to already serialized objects
	var refs_map = new HashMap[Serializable,Int]

	private fun ref_id_for(object: Serializable): Int
	do
		if refs_map.keys.has(object) then
			return refs_map[object]
		else
			var id = refs_map.length
			refs_map[object] = id
			return id
		end
	end
end

redef class Serializable
	private fun serialize_to_json(v: JsonSerializer)
	do
		var id = v.ref_id_for(self)
		v.stream.write "\{\"__kind\": \"obj\", \"__id\": {id}, \"__class\": \"{class_name}\""
		core_serialize_to(v)
		v.stream.write "\}"
	end
end

redef class Int
	redef fun serialize_to_json(v) do v.stream.write(to_s)
end

redef class Float
	redef fun serialize_to_json(v) do v.stream.write(to_s)
end

redef class Bool
	redef fun serialize_to_json(v) do v.stream.write(to_s)
end

redef class Char
	redef fun serialize_to_json(v) do v.stream.write("'{to_s}'")
end

redef class String
	redef fun serialize_to_json(v) do v.stream.write("\"{to_json_s}\"")

	private fun to_json_s: String do return self.replace("\\", "\\\\").
		replace("\"", "\\\"").replace("\b", "\\b").replace("/", "\\/").
		replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t")
		# FIXME add support for unicode char when supported by Nit strings
		# FIXME add support for \f! # .replace("\f", "\\f")
end

redef class NativeString
	redef fun serialize_to_json(v) do to_s.serialize_to_json(v)
end

redef class Array[E]
	redef fun serialize_to_json(v) do
		v.stream.write "["
		var is_first = true
		for e in self do
			if is_first then
				is_first = false
			else v.stream.write(", ")
			
			if not v.try_to_serialize(e) then
				v.warn("element of type {e.class_name} is not serializable.")
			end
		end
		v.stream.write "]"
	end
end
