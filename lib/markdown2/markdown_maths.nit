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

# Markdown Maths mode
#
# Allows to write Maths equation with the LaTeX Maths mode.
#
# This mode requires `tex2im` to be installed and added to the path.
# See: <http://www.nought.de/tex2im.php>
module markdown_maths

intrude import markdown_inline_parsing
intrude import markdown_block_parsing

redef class MdParser

	# Enable maths mode
	var maths_mode = false is writable

	redef var inline_parser is lazy do
		var parser = super
		parser.maths_mode = maths_mode
		return parser
	end
end

redef class MdInlineParser

	# Enable maths mode
	private var maths_mode = false

	redef var delimiter_processors is lazy do
		var processors = super
		if maths_mode then
			processors.add new MdMathsProcessor
		end
		return processors
	end
end

# Maths equation processor
class MdMathsProcessor
	super MdDelimiterProcessor

	# Maths equation delimiter
	#
	# Default is `$`.
	var delimiter_char = '$'

	redef var min_length = 1
	redef fun opening_delimiter do return delimiter_char
	redef fun closing_delimiter do return delimiter_char
	redef fun delimiter_use(opener, closer) do return 1

	redef fun process(opener, closer, delimiter_use) do
		var node = new MdMaths(
			new MdLocation(
				opener.location.line_start, opener.location.column_start,
				closer.location.line_end, closer.location.column_end),
			opening_delimiter.to_s)

		var buffer = new Buffer
		var tmp = opener.next
		while tmp != null and tmp != closer do
			var next = tmp.next
			tmp.maths_literal(buffer)
			tmp.unlink
			tmp = next
		end
		node.literal = buffer.to_s
		opener.insert_after(node)
	end
end

# Math equation node
class MdMaths
	super MdDelimited

	# Literal Maths string
	var literal: nullable String = null
end

# Inline nodes

redef class MdNode

	# Return the content of the node as a literal string
	private fun maths_literal(buffer: Buffer) do
		var node = first_child
		while node != null do
			node.maths_literal(buffer)
			node = node.next
		end
	end
end

redef class MdCode
	redef fun maths_literal(buffer) do buffer.append "{delimiter}{literal}{delimiter}"
end

redef class MdDelimited
	redef fun maths_literal(buffer) do
		buffer.append opening_delimiter
		super
		buffer.append closing_delimiter
	end
end

redef class MdHtmlInline
	redef fun maths_literal(buffer) do buffer.append literal
end

redef class MdLinkOrImage
	redef fun maths_literal(buffer) do
		if self isa MdLink and is_autolink then
			buffer.append "<{destination}>"
			return
		end
		if self isa MdImage then
			buffer.append "!"
		end
		buffer.append "["
		super
		buffer.append "]"
		buffer.append "({destination})"
	end
end

redef class MdLink
	redef fun maths_literal(buffer) do buffer.append "[{title or else ""}]({destination})"
end

redef class MdText
	redef fun maths_literal(buffer) do buffer.append literal
end
