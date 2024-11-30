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

# HTML rendering of Markdown documents
module markdown_html_rendering

import markdown_rendering
import markdown_github
import markdown_wikilinks
import markdown_maths

import md5

# Markdown document renderer to HTML
class HtmlRenderer
	super MdRenderer

	# Output directory for Maths mode images
	#
	# If `null`, do not generate images.
	# Default: `null`.
	var maths_img_outdir: nullable String = null is writable

	# HTML output under construction
	private var html: Buffer is noinit

	# Render `document` as HTML
	redef fun render(document) do
		reset
		enter_visit(document)
		return html.write_to_string
	end

	redef fun visit(node) do node.render_html(self)

	# Reset `headings` and internal state
	fun reset do
		html = new Buffer
		if enable_heading_ids then headings.clear
	end

	# Last char visited
	#
	# Used to avoid double blank lines.
	private var last_char: nullable Char = null

	# Add `string` to `html`
	private fun add(string: String) do
		html.append(string)
		if not html.is_empty then
			last_char = html.last
		end
	end

	# Add a raw `html` string to the output
	#
	# Raw means that the string will not be escaped.
	fun add_raw(html: String) do add html

	# Add `text` string to the output
	#
	# The string will be escaped.
	fun add_text(text: String) do add html_escape(text, true)

	# Add a blank line to the output
	fun add_line do
		if last_char != null and last_char != '\n' then
			add "\n"
		end
	end

	# Escape `string` to HTML
	#
	# When `keep_entities`, HTML entities will not be escaped.
	fun html_escape(string: String, keep_entities: Bool): String do
		var buf: nullable Buffer = null
		for i in [0..string.length[ do
			var c = string.chars[i]
			var sub = null
			if c == '&' and (not keep_entities or string.search_from(re_entity, i) == null) then
				sub = "&amp;"
			else if c == '<' then
				sub = "&lt;"
			else if c == '>' then
				sub = "&gt;"
			else if c == '"' then
				sub = "&quot;"
			else
				if buf != null then buf.add c
				continue
			end
			if buf == null then
				buf = new Buffer
				for j in [0..i[ do buf.add string.chars[j]
			end
			buf.append sub
		end

		if buf == null then return string
		return buf.to_s
	end

	# HTML entity pattern
	private var re_entity: Regex = "^&(#x[a-f0-9]\{1,8\}|#[0-9]\{1,8\}|[a-z][a-z0-9]\{1,31\});".to_re

	# Encode the `uri` string
	fun encode_uri(uri: String): String do
		var buf = new Buffer

		var i = 0
		while i < uri.length do
			var c = uri.chars[i]
			if (c >= '0' and c <= '9') or
			   (c >= 'a' and c <= 'z') or
			   (c >= 'A' and c <= 'Z') or
			   c == ';' or c == ',' or c == '/' or c == '?' or
			   c == ':' or c == '@' or c == '=' or c == '+' or
			   c == '$' or c == '-' or c == '_' or c == '.' or
			   c == '!' or c == '~' or c == '*' or c == '(' or
			   c == ')' or c == '#' or c == '\''
			then
				buf.add c
			else if c == '&' then
				buf.append "&amp;"
			else if c == '%' and uri.search_from(re_uri_code, i) != null then
				buf.append uri.substring(i, 3)
				i += 2
			else
				var bytes = c.to_s.bytes
				for b in bytes do buf.append "%{b.to_i.to_hex}".to_upper
			end
			i += 1
		end

		return buf.to_s
	end

	# URI encode pattern
	private var re_uri_code: Regex = "^%[a-zA-Z0-9]\{2\}".to_re

	# Add `id` tags to headings
	var enable_heading_ids = false is optional, writable

	# Associate headings ids to blocks
	var headings = new ArrayMap[String, MdHeading]

	# Strip heading id
	fun strip_id(text: String): String do
		# strip id
		var b = new FlatBuffer
		for c in text do
			if c == ' ' then
				b.add '_'
			else
				if not c.is_letter and
				   not c.is_digit and
				   not allowed_id_chars.has(c) then continue
				b.add c
			end
		end
		var res = b.to_s
		if res.is_empty then res = "_"
		var key = res
		# check for multiple id definitions
		if headings.has_key(key) then
			var i = 1
			key = "{res}_{i}"
			while headings.has_key(key) do
				i += 1
				key = "{res}_{i}"
			end
		end
		return key
	end

	# Allowed characters in ids
	var allowed_id_chars: Array[Char] = ['-', '_', ':', '.']
end

redef class MdNode

	# Render `self` as HTML
	fun render_html(v: HtmlRenderer) do visit_all(v)
end

# Blocks

redef class MdBlockQuote
	redef fun render_html(v) do
		v.add_line
		v.add_raw "<blockquote>"
		v.add_line
		visit_all(v)
		v.add_line
		v.add_raw "</blockquote>"
		v.add_line
	end
end

redef class MdCodeBlock
	redef fun render_html(v) do
		var info = self.info
		v.add_line
		v.add_raw "<pre>"
		v.add_raw "<code"
		if info != null and not info.is_empty then
			v.add_raw " class=\"language-{info.split(" ").first}\""
		end
		v.add_raw ">"
		var literal = self.literal or else ""
		var lines = literal.split("\n")
		for i in [0..lines.length[ do
			var line = lines[i]
			v.add_raw v.html_escape(line, false)
			if i < lines.length - 1 then
				v.add_raw "\n"
			end
		end
		v.add_raw "</code>"
		v.add_raw "</pre>"
		v.add_line
	end
end

redef class MdHeading
	redef fun render_html(v) do
		v.add_line
		if v.enable_heading_ids then
			var id = self.id
			if id == null then
				id = v.strip_id(title)
				v.headings[id] = self
				self.id = id
			end
			v.add_raw "<h{level} id=\"{id}\">"
		else
			v.add_raw "<h{level}>"
		end
		visit_all(v)
		v.add_raw "</h{level}>"
		v.add_line
	end

	#
	var id: nullable String = null

	#
	fun title: String do
		var v = new RawTextVisitor
		return v.render(self)
	end
end

redef class MdUnorderedList
	redef fun render_html(v) do
		v.add_line
		v.add_raw "<ul>"
		v.add_line
		visit_all(v)
		v.add_line
		v.add_raw "</ul>"
		v.add_line
	end
end

redef class MdOrderedList
	redef fun render_html(v) do
		var start = self.start_number
		v.add_line
		v.add_raw "<ol"
		if start != 1 then
			v.add_raw " start=\"{start}\""
		end
		v.add_raw ">"
		v.add_line
		visit_all(v)
		v.add_line
		v.add_raw "</ol>"
		v.add_line
	end
end

redef class MdListItem
	redef fun render_html(v) do
		v.add_raw "<li>"
		visit_all(v)
		v.add_raw "</li>"
		v.add_line
	end
end

redef class MdParagraph
	redef fun render_html(v) do
		var is_tight = is_in_tight_list
		if not is_tight then
			v.add_line
			v.add_raw "<p>"
		end
		visit_all(v)
		if not is_tight then
			v.add_raw "</p>"
			v.add_line
		end
	end
end

redef class MdThematicBreak
	redef fun render_html(v) do
		v.add_line
		v.add_raw "<hr />"
		v.add_line
	end
end

redef class MdHtmlBlock
	redef fun render_html(v) do
		v.add_line
		var literal = self.literal or else ""
		var lines = literal.split("\n")
		for i in [0..lines.length[ do
			var line = lines[i]
			if not line.trim.is_empty then
				v.add_raw line
			end
			if i < lines.length - 1 then
				v.add_raw "\n"
			end
		end
		v.add_line
	end
end

# Inlines

redef class MdHardLineBreak
	redef fun render_html(v) do
		v.add_raw "<br />"
		v.add_line
	end
end

redef class MdSoftLineBreak
	redef fun render_html(v) do
		v.add_raw "\n"
	end
end

redef class MdCode
	redef fun render_html(v) do
		v.add_raw "<code>"
		v.add_raw v.html_escape(literal, false)
		v.add_raw "</code>"
	end
end

redef class MdEmphasis
	redef fun render_html(v) do
		v.add_raw "<em>"
		visit_all(v)
		v.add_raw "</em>"
	end
end

redef class MdStrongEmphasis
	redef fun render_html(v) do
		v.add_raw "<strong>"
		visit_all(v)
		v.add_raw "</strong>"
	end
end

redef class MdHtmlInline
	redef fun render_html(v) do
		v.add_raw literal
	end
end

redef class MdImage
	redef fun render_html(v) do
		var url = self.destination
		var title = self.title
		v.add_raw "<img"
		v.add_raw " src=\"{v.encode_uri(url)}\""

		var alt_text = self.alt_text
		v.add_raw " alt=\"{alt_text}\""

		if title != null and not title.is_empty then
			v.add_raw " title=\""
			v.add_text title
			v.add_raw "\""
		end

		v.add_raw " />"
	end

	private fun alt_text: String do
		var v = new RawTextVisitor
		return v.render(self)
	end
end

redef class MdLink
	redef fun render_html(v) do
		var url = self.destination
		var title = self.title
		v.add_raw "<a"
		v.add_raw " href=\"{v.encode_uri(url)}\""
		if title != null and not title.is_empty then
			v.add_raw " title=\""
			v.add_text title
			v.add_raw "\""
		end
		v.add_raw ">"
		visit_all(v)
		v.add_raw "</a>"
	end
end

redef class MdText
	redef fun render_html(v) do
		v.add_text literal
	end
end

# Github mode

redef class MdStrike
	redef fun render_html(v) do
		v.add_raw "<del>"
		visit_all(v)
		v.add_raw "</del>"
	end
end

redef class MdSuper
	redef fun render_html(v) do
		v.add_raw "<sup>"
		visit_all(v)
		v.add_raw "</sup>"
	end
end

# Wikilinks mode

redef class MdWikilink

	# Dummy rendering of wikilinks
	#
	# Clients should redefine this.
	redef fun render_html(v) do
		v.add_raw "<wiki link=\"{v.encode_uri(link)}\">"
		visit_all(v)
		v.add_raw "</wiki>"
	end
end

# Math mode

redef class MdMaths
	redef fun render_html(v) do
		var out_dir = v.maths_img_outdir

		if out_dir == null then
			v.add_raw opening_delimiter
			v.add_raw literal or else ""
			v.add_raw closing_delimiter
			return
		end

		# generate image
		out_dir.mkdir
		var maths = literal or else ""
		var out = "{out_dir}/{maths.md5}.png"
		if not out.file_exists then
			sys.system "tex2im -o {out} -z -n -r 200x200 \"{maths.escape_to_sh}\""
		end

		v.add_raw "<img alt=\""
		v.add_text literal or else ""
		v.add_raw "\" src=\"{out}\" />"
	end
end
