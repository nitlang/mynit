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

# Markdown rendering of Markdown documents
module markdown_md_rendering

import markdown_rendering
import markdown_github
import markdown_wikilinks
import markdown_maths

# Markdown document renderer to Markdown
class MarkdownRenderer
	super MdRenderer

	# Markdown output under construction
	private var md: Buffer is noinit

	# Render `node` as Markdown
	redef fun render(node) do
		reset
		enter_visit(node)
		return md.write_to_string
	end

	redef fun visit(node) do node.render_md(self)

	# Reset internal state
	fun reset do
		md = new Buffer
	end

	# Current indentation level
	private var indent = 0

	# Are we currently in a blockquote?
	var in_quote = 0

	# Add a `md` string to the output
	fun add_raw(md: String) do self.md.append(md)

	# Add a blank line to the output
	fun add_line do add_raw "\n"

	# Add an indentation depending on `ident` level
	fun add_indent do
		add_raw " " * indent
	end
end

private class TextLengthVisitor
	super MdVisitor

	var length = 0

	redef fun visit(node) do node.process_len(self)
end

redef class MdNode

	# Render `self` as Markdown
	fun render_md(v: MarkdownRenderer) do visit_all(v)

	private fun process_len(v: TextLengthVisitor) do visit_all(v)
end

redef class MdDocument
	redef fun render_md(v) do
		var node = first_child
		while node != null do
			v.enter_visit(node)
			node = node.next
			if node != null then
				v.add_line
			end
		end
	end
end

# Blocks

redef class MdBlockQuote
	redef fun render_md(v) do
		v.in_quote += 1
		var node = first_child
		while node != null do
			v.add_indent
			v.add_raw "> "
			v.enter_visit(node)
			node = node.next
		end
		v.in_quote -= 1
	end
end

redef class MdIndentedCodeBlock
	redef fun render_md(v) do
		var literal = self.literal
		if literal == null then return

		var lines = literal.split("\n")
		for i in [0..lines.length[ do
			if i == lines.length - 1 then continue
			var line = lines[i]
			if line.is_empty then
				v.add_raw "\n"
			else
				v.add_indent
				if use_tabs then
					v.add_raw "\t"
				else
					v.add_raw " " * 4
				end
				v.add_raw line
				v.add_line
			end
		end
	end
end

redef class MdFencedCodeBlock
	redef fun render_md(v) do
		var info = self.info
		v.add_indent
		v.add_raw fence_char.to_s * fence_length
		v.add_raw info or else ""
		for line in (literal or else "").split("\n") do
			v.add_line
			if not line.is_empty then
				v.add_indent
			end
			v.add_raw line
		end
		v.add_indent
		v.add_raw fence_char.to_s * fence_length
		v.add_line
	end
end

redef class MdHeading
	redef fun render_md(v) do
		if is_setext then
			visit_all(v)
			var length_visitor = new TextLengthVisitor
			length_visitor.enter_visit(self)
			v.add_line
			if level == 1 then
				v.add_raw "=" * length_visitor.length
			else
				v.add_raw "-" * length_visitor.length
			end
		else
			v.add_raw "#" * level
			v.add_raw " "
			visit_all(v)
			if has_atx_trailing then
				v.add_raw " "
				v.add_raw "#" * level
			end
		end
		v.add_line
	end
end

redef class MdOrderedList
	# Children numbering
	private var md_numbering: Int = start_number is lazy
end

redef class MdListItem
	redef fun render_md(v) do
		var parent = self.parent
		var is_tight = parent.as(MdListBlock).is_tight

		v.add_indent
		if parent isa MdUnorderedList then
			v.add_raw parent.bullet_marker.to_s
			v.indent += 2
		else if parent isa MdOrderedList then
			v.add_raw "{parent.md_numbering}{parent.delimiter.to_s}"
			v.indent += 3
		end

		var node = first_child
		if node != null then
			v.add_raw " "
		else
			v.add_line
		end
		while node != null do
			v.enter_visit(node)
			node = node.next
			if node != null and not is_tight then
				v.add_line
			end
		end

		if next != null and not is_tight then
			v.add_line
		end

		if parent isa MdUnorderedList then
			v.indent -= 2
		else if parent isa MdOrderedList then
			parent.md_numbering += 1
			v.indent -= 3
		end
	end
end

redef class MdParagraph
	redef fun render_md(v) do
		if not parent isa MdBlockQuote and not parent isa MdListItem or prev != null then
			v.add_indent
		end
		# if parent isa MdBlockQuote then
			# v.add_raw "> "
			# var node = first_child
			# while node != null do
				# v.enter_visit(node)
				# if node isa MdSoftLineBreak or node isa MdHardLineBreak then
					# v.add_raw "> "
				# end
				# node = node.next
			# end
			# v.add_line
			# return
		# end
		visit_all(v)
		v.add_line
	end
end

redef class MdThematicBreak
	redef fun render_md(v) do
		v.add_raw original_pattern
		v.add_line
	end
end

redef class MdHtmlBlock
	redef fun render_md(v) do
		v.add_raw literal or else ""
		v.add_line
	end
end

# Inlines

redef class MdHardLineBreak
	redef fun render_md(v) do
		if has_backslash then
			v.add_raw "\\"
		else
			v.add_raw "  "
		end
		v.add_line
		v.add_indent
		v.add_raw "> " * v.in_quote
	end

	redef fun process_len(v) do
		super
		v.length += 1
	end
end

redef class MdSoftLineBreak
	redef fun render_md(v) do
		v.add_line
		v.add_indent
		v.add_raw "> " * v.in_quote
	end

	redef fun process_len(v) do
		super
		v.length += 1
	end
end

redef class MdCode
	redef fun render_md(v) do
		v.add_raw delimiter
		v.add_raw literal
		v.add_raw delimiter
	end

	redef fun process_len(v) do
		super
		v.length += delimiter.length
	end
end

redef class MdDelimited
	redef fun render_md(v) do
		v.add_raw delimiter
		visit_all(v)
		v.add_raw delimiter
	end

	redef fun process_len(v) do
		super
		v.length += delimiter.length * 2
	end
end

redef class MdHtmlInline
	redef fun render_md(v) do
		v.add_raw literal
	end

	redef fun process_len(v) do
		v.length += literal.length
	end
end

redef class MdLinkOrImage
	redef fun render_md(v) do
		var title = self.title
		v.add_raw "["
		visit_all(v)
		v.add_raw "]"
		v.add_raw "("
		if has_brackets then
			v.add_raw "<"
		end
		v.add_raw destination
		if has_brackets then
			v.add_raw ">"
		end
		if title != null and not title.is_empty then
			v.add_raw " \""
			v.add_raw title.replace("\"", "\\\"")
			v.add_raw "\""
		end
		v.add_raw ")"
	end
end


redef class MdImage
	redef fun render_md(v) do
		v.add_raw "!"
		super
	end
end

redef class MdLink
	redef fun render_md(v) do
		if is_autolink then
			v.add_raw "<"
			v.add_raw destination
			v.add_raw ">"
			return
		end
		super
	end
end

redef class MdText
	redef fun render_md(v) do
		v.add_raw literal
	end

	redef fun process_len(v) do
		v.length += literal.length
	end
end

# Wikilinks

redef class MdWikilink
	redef fun render_md(v) do
		v.add_raw "[["
		var title = self.title
		if title != null then
			v.add_raw "{title} | "
		end
		v.add_raw link
		v.add_raw "]]"
	end
end

# Math mode

redef class MdMaths
	redef fun render_md(v) do
		v.add_raw "$"
		v.add_raw literal or else ""
		v.add_raw "$"
	end
end
