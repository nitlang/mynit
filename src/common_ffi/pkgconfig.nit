# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2013 Alexis Laferrière <alexis.laf@xymus.net>
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

# Offers the `PkgconfigPhase` to use the external program "pkg-config" in order
# to discover what options to pass to the C or C++ compiler.
module pkgconfig

import c

redef class ToolContext
	var pkgconfig_phase: Phase = new PkgconfigPhase(self, null)
end

# Detects the `pkgconfig` annotation on the module declaration only.
class PkgconfigPhase
	super Phase

	redef fun process_annotated_node(nmoduledecl, nat)
	do
		# Skip if we are not interested
		if nat.n_atid.n_id.text != "pkgconfig" then return

		# Do some validity checks and print errors if the annotation is used incorrectly
		var modelbuilder = toolcontext.modelbuilder

		if not nmoduledecl isa AModuledecl then
			modelbuilder.error(nat, "Syntax error: only the declaration of modules may use \"pkgconfig\".")
			return
		end

		var args = nat.n_args
		if args.is_empty then
			modelbuilder.error(nat, "Syntax error: \"pkgconfig\" expects at least one argument.")
			return
		end

		var pkgs = new Array[String]
		for arg in args do
			if not arg isa AExprAtArg then
				modelbuilder.error(nat, "Syntax error: \"pkgconfig\" expects its arguments to be the name of the package as String literals.")
				return
			end

			var expr = arg.n_expr
			if not expr isa AStringFormExpr then
				modelbuilder.error(nat, "Syntax error: \"pkgconfig\" expects its arguments to be the name of the package as String literals.")
				return
			end

			var pkg = expr.collect_text
			pkg = pkg.substring(1, pkg.length-2)
			pkgs.add(pkg)
		end

		# retreive module
		var nmodule = nmoduledecl.parent.as(AModule)

		# check availability of pkg-config
		var proc_which = new IProcess("which", "pkg-config")
		proc_which.wait
		var status = proc_which.status
		if status != 0 then
			modelbuilder.error(nat, "Error: program pkg-config not found, make sure it is installed.")
			return
		end

		for pkg in pkgs do
			var proc_exist = new Process("pkg-config", "--exists", pkg)
			proc_exist.wait
			status = proc_exist.status
			if status == 1 then
				modelbuilder.error(nat, "Error: package \"{pkg}\" unknown by pkg-config, make sure the development package is be installed.")
				return
			else if status != 0 then
				modelbuilder.error(nat, "Error: something went wrong calling pkg-config, make sure it is correctly installed.")
				return
			end

			# compiler
			var proc = new IProcess("pkg-config", "--cflags", pkg)
			var compiler_opts = proc.read_all
			nmodule.c_compiler_options = "{nmodule.c_compiler_options} {compiler_opts.replace("\n", " ")}"

			# linker
			proc = new IProcess("pkg-config", "--libs", pkg)
			var linker_opts = proc.read_all
			nmodule.c_linker_options = "{nmodule.c_linker_options} {linker_opts.replace("\n", " ")}"
		end

	end
end
