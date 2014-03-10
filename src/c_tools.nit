# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2012 Alexis Laferrière <alexis.laf@xymus.net>
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

# provides tools to write C .c and .h files
module c_tools

import template

# Accumulates all C code for a compilation unit
class CCompilationUnit
	## header
	# comments and native interface imports
	var header_c_base = new Template

	# custom C header code or generated for other languages
	var header_custom = new Template

	# types of extern classes and friendly types
	var header_c_types = new Template

	# implementation declaration for extern methods
	var header_decl = new Template

	## body
	# comments, imports, etc
	var body_decl = new Template

	# custom code and generated for ffi
	var body_custom = new Template

	# implementation body of extern methods
	var body_impl = new Template

	# files to compile TODO check is appropriate
	var files = new Array[String]

	fun add_local_function( efc : CFunction )
	do
		body_decl.add( "{efc.signature};\n" )
		body_impl.add( "\n" )
		body_impl.add( efc.to_writer )
	end

	fun add_exported_function( efc : CFunction )
	do
		header_decl.add( "{efc.signature};\n" )
		body_impl.add( "\n" )
		body_impl.add( efc.to_writer )
	end

	fun compile_header_core( stream : OStream )
	do
		header_c_base.write_to( stream )
		header_custom.write_to( stream )
		header_c_types.write_to( stream )
		header_decl.write_to( stream )
	end

	fun compile_body_core( stream : OStream )
	do
		body_decl.write_to( stream )
		body_custom.write_to( stream )
		body_impl.write_to( stream )
	end
end

# Accumulates C code related to a specific function
class CFunction
	var signature : String

	var decls = new Template
	var exprs = new Template

	fun to_writer: Template
	do
		var w = new Template

		w.add(signature)
		w.add("\n\{\n")
		w.add(decls)
		w.add("\n")
		w.add(exprs)
		w.add("\}\n")

		return w
	end
end
