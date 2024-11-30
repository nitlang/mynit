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

# LaTeX rendering of Markdown documents
module markdown_latex_rendering

import markdown_rendering
import markdown_github
import markdown_wikilinks
import markdown_maths

# Markdown document renderer to LaTeX
class LatexRenderer
	super MdRenderer

	# Generate the LaTeX document wrapper
	#
	# The header includes:
	#  * document class
	#  * package importation
	#  * begin and end document directives
	var wrap_document = false is optional, writable

	# LaTeX document class
	#
	# Default is `article`.
	var document_class = "article" is optional, writable

	# LaTeX document page format
	#
	# Default is `letter`.
	var page_format = "letter" is optional, writable

	# LaTeX font size
	#
	# Default is `10pt`.
	var font_size = "10pt" is optional, writable

	# Use `listings` package for code blocks?
	var use_listings = false is optional, writable

	# LaTeX output under construction
	private var latex: Buffer is noinit

	# Render `document` as LaTeX
	redef fun render(document) do
		latex = new Buffer
		enter_visit(document)
		return latex.write_to_string
	end

	redef fun visit(node) do node.render_latex(self)

	# Indentation level
	var indent = 0

	# Add a raw `string` to the output
	#
	# Raw means that the string will not be escaped.
	fun add_raw(string: String) do latex.append string

	# Add `text` string to the output
	#
	# The string will be escaped.
	fun add_text(text: String) do latex.append latex_escape(text)

	# Add a blank line to the output
	fun add_line do
		if not latex.is_empty and latex.last != '\n' then
			latex.add '\n'
		end
	end

	# Add an indentation depending on `ident` level
	fun add_indent do latex.append " " * indent

	# Escape `string` to LaTeX
	fun latex_escape(string: String): String do
		var buffer = new Buffer
		for i in [0 .. string.length[ do
			var c = string.chars[i]
			if c == '>' then
				buffer.append "\\textgreater"
				continue
			else if c == '<' then
				buffer.append "\\textless"
				continue
			else if c == '\\' then
				buffer.append "\\textbackslash"
				continue
			else if escaped_chars.has(c) then
				buffer.add '\\'
			end
			buffer.add c
		end
		return buffer.to_s
	end

	# LaTeX characters to escape
	var escaped_chars = ['%', '$', '{', '}', '_', '#', '&']
end

redef class MdNode

	# Render `self` as HTML
	fun render_latex(v: LatexRenderer) do visit_all(v)
end

# Blocks

redef class MdDocument
	redef fun render_latex(v) do
		var wrap_document = v.wrap_document
		if v.wrap_document then
			v.add_line
			v.add_raw "\\documentclass[{v.page_format},{v.font_size}]\{{v.document_class}\}\n\n"
			v.add_raw "\\usepackage[utf8]\{inputenc\}\n"
			if v.use_listings then
				v.add_raw "\\usepackage\{listings\}\n"
			end
			v.add_raw "\\usepackage\{hyperref\}\n"
			v.add_raw "\\usepackage\{graphicx\}\n"
			v.add_raw "\\usepackage\{ulem\}\n\n"
			v.add_raw "\\begin\{document\}\n\n"
		end
		var node = first_child
		while node != null do
			v.enter_visit node
			node = node.next
			if node != null then v.add_raw "\n"
		end
		if wrap_document then
			v.add_raw "\n\\end\{document\}\n"
		end
	end
end

redef class MdHeading
	redef fun render_latex(v) do
		var level = self.level
		v.add_indent
		v.add_line
		if level == 1 then
			v.add_raw "\\section\{"
		else if level == 2 then
			v.add_raw "\\subsection\{"
		else if level == 3 then
			v.add_raw "\\subsubsection\{"
		else if level == 4 then
			v.add_raw "\\paragraph\{"
		else if level == 5 then
			v.add_raw "\\subparagraph\{"
		else
			# use bold for level 6 headings
			v.add_raw "\\textbf\{"
		end
		v.add_indent
		visit_all(v)
		v.add_raw "\}"
		v.add_line
	end
end

redef class MdBlockQuote
	redef fun render_latex(v) do
		v.add_line
		v.add_indent
		v.add_raw "\\begin\{quote\}"
		v.add_line
		v.indent += 2
		visit_all(v)
		v.indent -= 2
		v.add_line
		v.add_indent
		v.add_raw "\\end\{quote\}"
		v.add_line
	end
end

redef class MdIndentedCodeBlock
	redef fun render_latex(v) do
		var directive = if v.use_listings then "lstlisting" else "verbatim"
		v.add_line
		v.add_indent
		v.add_raw "\\begin\{{directive}\}"
		v.add_line
		v.add_raw literal or else ""
		v.add_line
		v.add_indent
		v.add_raw "\\end\{{directive}\}"
		v.add_line
	end
end

redef class MdFencedCodeBlock
	redef fun render_latex(v) do
		var info = self.info
		var lstlistings = v.use_listings
		var directive = if lstlistings then "lstlisting" else "verbatim"
		v.add_line
		v.add_indent
		v.add_raw "\\begin\{{directive}\}"
		if lstlistings and info != null and not info.is_empty then
			v.add_raw "[language={info}]"
		end
		v.add_line
		v.add_raw literal or else ""
		v.add_line
		v.add_indent
		v.add_raw "\\end\{{directive}\}"
		v.add_line
	end
end

redef class MdOrderedList
	redef fun render_latex(v) do
		var start = self.start_number
		v.add_line
		v.add_indent
		v.add_raw "\\begin\{enumerate\}"
		v.indent += 2
		v.add_line
		if start != 1 then
			v.add_indent
			v.add_raw "\\setcounter\{enum{nesting_level}\}\{{start}\}"
			v.add_line
		end
		visit_all(v)
		v.indent -= 2
		v.add_line
		v.add_indent
		v.add_raw "\\end\{enumerate\}"
		v.add_line
	end

	# Depth of ordered list
	#
	# Used to compute the `setcounter` level.
	fun nesting_level: String do
		var nesting = 1

		var parent = self.parent
		while parent != null do
			if parent isa MdOrderedList then nesting += 1
			parent = parent.parent
		end

		if nesting <= 3 then
			return "i" * nesting
		end
		return "iv"
	end
end

redef class MdUnorderedList
	redef fun render_latex(v) do
		v.add_line
		v.add_indent
		v.add_raw "\\begin\{itemize\}"
		v.add_line
		v.indent += 2
		visit_all(v)
		v.indent -= 2
		v.add_line
		v.add_indent
		v.add_raw "\\end\{itemize\}"
		v.add_line
	end
end

redef class MdListItem
	redef fun render_latex(v) do
		v.add_indent
		v.add_raw "\\item"
		v.add_line
		v.indent += 2
		visit_all(v)
		v.indent -= 2
		v.add_line
	end
end

redef class MdThematicBreak
	redef fun render_latex(v) do
		v.add_line
		v.add_indent
		v.add_raw "\\begin\{center\}\\rule\{3in\}\{0.4pt\}\\end\{center\}"
		v.add_line
	end
end

redef class MdParagraph
	redef fun render_latex(v) do
		v.add_indent
		visit_all(v)
		v.add_line
	end
end


redef class MdHtmlBlock
	redef fun render_latex(v) do
		v.add_line
		v.add_indent
		v.add_raw "\\begin\{verbatim\}"
		v.add_line
		v.add_indent
		v.add_raw literal or else ""
		v.add_line
		v.add_indent
		v.add_raw "\\end\{verbatim\}"
		v.add_line
	end
end

# Inlines

redef class MdLineBreak
	redef fun render_latex(v) do
		v.add_line
		v.add_indent
	end
end

redef class MdCode
	redef fun render_latex(v) do
		v.add_raw "\\texttt\{"
		v.add_text literal
		v.add_raw "\}"
	end
end

redef class MdEmphasis
	redef fun render_latex(v) do
		v.add_raw "\\textit\{"
		visit_all(v)
		v.add_raw "\}"
	end
end

redef class MdStrongEmphasis
	redef fun render_latex(v) do
		v.add_raw "\\textbf\{"
		visit_all(v)
		v.add_raw "\}"
	end
end

redef class MdHtmlInline
	redef fun render_latex(v) do
		v.add_raw "\\texttt\{"
		v.add_raw v.latex_escape(literal)
		v.add_raw "\}"
	end
end

redef class MdImage
	redef fun render_latex(v) do
		v.add_raw "\\includegraphics\{"
		v.add_text destination
		v.add_raw "\}"
	end

	private fun alt_text: String do
		var v = new RawTextVisitor
		return v.render(self)
	end
end

redef class MdLink
	redef fun render_latex(v) do
		if is_autolink then
			v.add_raw "\\url\{"
			v.add_text destination
			v.add_raw "\}"
			return
		end
		var title = self.title
		v.add_raw "\\href\{"
		v.add_text destination
		v.add_raw "\}\{"
		visit_all(v)
		if title != null and not title.is_empty then
			v.add_raw " ("
			v.add_text title
			v.add_raw ")"
		end
		v.add_raw "\}"
	end
end

redef class MdText
	redef fun render_latex(v) do
		v.add_text literal
	end
end

# Github mode

redef class MdStrike
	redef fun render_latex(v) do
		v.add_raw "\\sout\{"
		visit_all(v)
		v.add_raw "\}"
	end
end

redef class MdSuper
	redef fun render_latex(v) do
		v.add_raw "\\textsuperscript\{"
		visit_all(v)
		v.add_raw "\}"
	end
end

# Wikilinks

redef class MdWikilink
	redef fun render_latex(v) do
		v.add_raw "\\texttt\{"
		var title = self.title
		if title != null then
			v.add_text "{title} | "
		end
		v.add_text link
		v.add_raw "\}"
	end
end

# Math mode

redef class MdMaths
	redef fun render_latex(v) do
		v.add_raw "$"
		v.add_raw literal or else ""
		v.add_raw "$"
	end
end
