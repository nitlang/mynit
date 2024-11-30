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

# Tests for markdown Maths mode
module test_markdown_maths is test

import test_markdown
import test_markdown_location
import test_markdown_md
import test_markdown_man
import test_markdown_latex

redef class TestMarkdown
	redef var md_parser is lazy do
		var parser = super
		parser.maths_mode = true
		return parser
	end
end

class TestMathsLocation
	super TestMarkdownLocation
	test

	fun test_maths_strike is test do
		var md = """
A $formula$ text.
"""
		var loc = """
MdDocument: 1,1--1,17
  MdParagraph: 1,1--1,17
    MdText: 1,1--1,2
    MdMaths: 1,3--1,11
    MdText: 1,12--1,17
"""
		assert md_to_loc(md) == loc
	end

	fun test_maths_strike2 is test do
		var md = """
A $$formula$$ text.
"""
		var loc = """
MdDocument: 1,1--1,19
  MdParagraph: 1,1--1,19
    MdText: 1,1--1,2
    MdMaths: 1,3--1,13
    MdText: 1,14--1,19
"""
		assert md_to_loc(md) == loc
	end
end

class TestMathsHtml
	super TestMarkdownHtml
	test

	var img_out_dir = "maths.out"

	fun before is before do
		html_renderer.maths_img_outdir = null
	end

	fun after is after do
		img_out_dir.rmdir
	end

	fun test_maths1 is test do
		var md = """foo $bar$ baz\n"""
		var html = """<p>foo $bar$ baz</p>\n"""
		assert md_to_html(md) == html
	end

	fun test_maths2 is test do
		var md = """foo $1 * 2 * 3$ baz\n"""
		var html = """<p>foo $1 * 2 * 3$ baz</p>\n"""
		assert md_to_html(md) == html
	end

	fun test_maths3 is test do
		var md = """foo $1 ^ 2 ^ 3$ baz\n"""
		var html = """<p>foo $1 ^ 2 ^ 3$ baz</p>\n"""
		assert md_to_html(md) == html
	end

	fun test_maths4 is test do
		var md = """foo $1 _2_3$ baz\n"""
		var html = """<p>foo $1 _2_3$ baz</p>\n"""
		assert md_to_html(md) == html
	end

	fun test_maths5 is test do
		var md = """foo $\\psi_{tot}(x,-t_0,r) = \\frac{1}{(2\\pi)^2} \\int\\!\\!\\!\\int\\tilde\\Psi_{tot}\\left(k_x,\\frac{c}{2}\\sqrt{k_x^2 + k_r^2},r=0\\right)$ baz\n"""
		var html = """<p>foo $\\psi_{tot}(x,-t_0,r) = \\frac{1}{(2\\pi)^2} \\int!!!\\int\\tilde\\Psi_{tot}\\left(k_x,\\frac{c}{2}\\sqrt{k_x^2 + k_r^2},r=0\\right)$ baz</p>\n"""
		assert md_to_html(md) == html
	end

	fun test_maths6 is test do
		html_renderer.maths_img_outdir = img_out_dir
		var md = """foo $\\psi_{tot}(x,-t_0,r) = \\frac{1}{(2\\pi)^2}$ baz\n"""
		var html = """<p>foo <img alt="\\psi_{tot}(x,-t_0,r) = \\frac{1}{(2\\pi)^2}" src="{{{img_out_dir}}}/b123b75db5eb96ac4496d017a18633b5.png" /> baz</p>\n"""
		assert md_to_html(md) == html
	end

	fun test_maths_bad is test do
		var md = """foo $bar baz\n"""
		var html = """<p>foo $bar baz</p>\n"""
		assert md_to_html(md) == html
	end

	fun test_maths_bad2 is test do
		var md = """foo $$bar$ baz\n"""
		var html = """<p>foo $$bar$ baz</p>\n"""
		assert md_to_html(md) == html
	end

	fun test_maths_bad3 is test do
		var md = """foo $$$bar$ baz\n"""
		var html = """<p>foo $$$bar$ baz</p>\n"""
		assert md_to_html(md) == html
	end

	fun test_maths_bad4 is test do
		var md = """foo bar$ baz\n"""
		var html = """<p>foo bar$ baz</p>\n"""
		assert md_to_html(md) == html
	end

	fun test_maths_bad5 is test do
		var md = """foo $bar$$$$ baz\n"""
		var html = """<p>foo $bar$$$$ baz</p>\n"""
		assert md_to_html(md) == html
	end
end

class TestMathsMd
	super TestMarkdownMd
	test

	fun test_maths_md is test do
		var md = """$foo$\n"""
		assert md_to_md(md) == md
	end
end

class TessMathsMan
	super TestMarkdownMan
	test

	fun test_maths_man is test do
		var md = """$formula$\n"""
		var man = """\n$formula$\n"""
		assert md_to_man(md) == man
	end
end

class TestMathsLatex
	super TestMarkdownLatex
	test

	fun test_maths_latex is test do
		var md = """A $formula$ text.\n"""
		assert md_to_tex(md) == md
	end
end
