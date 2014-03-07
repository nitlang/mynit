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

# CSV output facilities
module csv

# A CSV document representation
class CSVDocument
	var header: Array[String] writable = new Array[String]
	var lines: Array[Array[String]] = new Array[Array[String]]

	fun set_header(values: Object...) do
		header.clear
		for value in values do
			header.add(value.to_s)
		end
	end

	fun add_line(values: Object...) do
		if values.length != header.length then
			print "CSV error: header declares {header.length} columns, line contains {values.length} values"
			abort
		end
		var line = new Array[String]
		for value in values do
			line.add(value.to_s)
		end
		lines.add(line)
	end

	redef fun to_s do
		var str = header.join(";") + "\n"
		for line in lines do str += line.join(";") + "\n"
		return str
	end

	fun save(file: String) do
		var out = new OFStream.open(file)
		out.write(self.to_s)
		out.close
	end
end
