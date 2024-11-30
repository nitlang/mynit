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

# Manpages rendering of Markdown documents
module markdown_man_rendering

import markdown_rendering
import markdown_github
import markdown_wikilinks
import markdown_maths

# Markdown document renderer to Manpage
class ManRenderer
	super MdRenderer

	# Output under construction
	private var man: Buffer is noinit

	# Render `node` as Markdown
	redef fun render(node) do
		man = new Buffer
		enter_visit(node)
		return man.write_to_string
	end

	redef fun visit(node) do node.render_man(self)

	# Add `string` to `man`
	fun add(string: String) do
		man.append(string.replace("-", "\\-"))
	end

	# Add code that need to be escaped
	fun add_code(code: String) do
		add code.replace(" ", "\\ ")
	end

	# Add a blank line to the output
	fun add_line do
		add "\n"
	end
end

redef class MdNode

	# Render `self` as Manpage format
	fun render_man(v: ManRenderer) do visit_all(v)
end

# Blocks

redef class MdBlockQuote
	redef fun render_man(v) do
		v.add ".RS"
		visit_all(v)
		v.add ".RE"
		v.add_line
	end
end

redef class MdCodeBlock
	redef fun render_man(v) do
		v.add ".RS\n.nf\n\\f[C]"
		v.add_line

		var literal = self.literal
		if literal != null then
			var lines = literal.split("\n")
			for i in [0 .. lines.length[ do
				if i == lines.length - 1 then break
				var line = lines[i]
				v.add_code line
				v.add_line
			end
		end

		v.add "\\f[]\n.fi\n.RE"
		v.add_line
	end
end

redef class MdHeading
	redef fun render_man(v) do
		var level = self.level

		if level == 1 then
			v.add ".SH "
		else if level == 2 then
			v.add ".SS "
		else if level >= 3 then
			# We use dictionary (titled paragraph) to simulate a 3rd level (or more)
			v.add ".TP\n"
		end
		visit_all(v)
		v.add_line
	end
end

redef class MdUnorderedList
	redef fun render_man(v) do
		v.add ".RS"
		v.add_line

		var node = first_child
		while node != null do
			v.add ".IP \\[bu] 3"
			v.add_line
			v.enter_visit node
			v.add_line
			node = node.next
		end

		v.add ".RE"
		v.add_line
	end
end

redef class MdOrderedList
	redef fun render_man(v) do
		v.add ".RS"
		v.add_line

		var index = start_number
		var node = first_child
		while node != null do
			v.add ".IP \"{index}.\" 3"
			v.add_line
			v.enter_visit node
			v.add_line
			node = node.next
			index += 1
		end

		v.add ".RE"
		v.add_line
	end
end

redef class MdParagraph
	redef fun render_man(v) do
		var in_list = is_in_list
		if not in_list then
			v.add_line
		end
		visit_all(v)
		if not in_list then
			v.add_line
		end
	end
end

redef class MdThematicBreak
	redef fun render_man(v) do
		v.add "***"
		v.add_line
	end
end

redef class MdHtmlBlock
	redef fun render_man(v) do
		v.add_line
		v.add literal or else ""
		v.add_line
	end
end

# Inlines

redef class MdLineBreak
	redef fun render_man(v) do
		v.add_line
	end
end

redef class MdCode
	redef fun render_man(v) do
		v.add "\\f[C]"
		v.add_code literal
		v.add "\\f[]"
	end
end

redef class MdEmphasis
	redef fun render_man(v) do
		v.add "\\f[I]"
		visit_all(v)
		v.add "\\f[]"
	end
end

redef class MdStrongEmphasis
	redef fun render_man(v) do
		v.add "\\f[B]"
		visit_all(v)
		v.add "\\f[]"
	end
end

redef class MdHtmlInline
	redef fun render_man(v) do
		v.add literal
	end
end

redef class MdLinkOrImage
	redef fun render_man(v) do
		var title = self.title

		visit_all(v)
		v.add " ("
		v.add destination
		if title != null and not title.is_empty then
			v.add " "
			v.add title
		end
		v.add ")"
	end
end

redef class MdText
	redef fun render_man(v) do
		v.add literal
	end
end

# Github

redef class MdStrike
	redef fun render_man(v) do
		v.add "[STRIKEOUT:"
		visit_all(v)
		v.add "]"
	end
end

# Wikilinks

redef class MdWikilink
	redef fun render_man(v) do
		v.add "("
		var title = self.title
		if title != null then
			v.add "{title} | "
		end
		v.add link
		v.add ")"
	end
end

# Math mode

redef class MdMaths
	redef fun render_man(v) do
		v.add "$"
		v.add literal or else ""
		v.add "$"
	end
end
