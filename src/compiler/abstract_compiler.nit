# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2012 Jean Privat <jean@pryen.org>
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

# Abstract compiler
module abstract_compiler

import literal
import semantize
import platform
import c_tools
private import annotation
import mixin
import counter
import pkgconfig
private import explain_assert_api
import contracts

# Add compiling options
redef class ToolContext
	# --output
	var opt_output = new OptionString("Filename of the generated executable", "-o", "--output")
	# --dir
	var opt_dir = new OptionString("Output directory", "--dir")
	# --run
	var opt_run = new OptionBool("Execute the binary after the compilation", "--run")
	# --no-cc
	var opt_no_cc = new OptionBool("Do not invoke the C compiler", "--no-cc")
	# --no-main
	var opt_no_main = new OptionBool("Do not generate main entry point", "--no-main")
	# --shared-lib
	var opt_shared_lib = new OptionBool("Compile to a native shared library", "--shared-lib")
	# --make-flags
	var opt_make_flags = new OptionString("Additional options to the `make` command", "--make-flags")
	# --max-c-lines
	var opt_max_c_lines = new OptionInt("Maximum number of lines in generated C files. Use 0 for unlimited", 10000, "--max-c-lines")
	# --group-c-files
	var opt_group_c_files = new OptionBool("Group all generated code in the same series of files", "--group-c-files")
	# --compile-dir
	var opt_compile_dir = new OptionString("Directory used to generate temporary files", "--compile-dir")
	# --hardening
	var opt_hardening = new OptionBool("Generate contracts in the C code against bugs in the compiler", "--hardening")
	# --no-check-covariance
	var opt_no_check_covariance = new OptionBool("Disable type tests of covariant parameters (dangerous)", "--no-check-covariance")
	# --no-check-attr-isset
	var opt_no_check_attr_isset = new OptionBool("Disable isset tests before each attribute access (dangerous)", "--no-check-attr-isset")
	# --no-check-assert
	var opt_no_check_assert = new OptionBool("Disable the evaluation of explicit `assert` and `as` (dangerous)", "--no-check-assert")
	# --no-check-autocast
	var opt_no_check_autocast = new OptionBool("Disable implicit casts on unsafe expression usage (dangerous)", "--no-check-autocast")
	# --no-check-null
	var opt_no_check_null = new OptionBool("Disable tests of null receiver (dangerous)", "--no-check-null")
	# --no-check-all
	var opt_no_check_all = new OptionBool("Disable all tests (dangerous)", "--no-check-all")
	# --typing-test-metrics
	var opt_typing_test_metrics = new OptionBool("Enable static and dynamic count of all type tests", "--typing-test-metrics")
	# --invocation-metrics
	var opt_invocation_metrics = new OptionBool("Enable static and dynamic count of all method invocations", "--invocation-metrics")
	# --isset-checks-metrics
	var opt_isset_checks_metrics = new OptionBool("Enable static and dynamic count of isset checks before attributes access", "--isset-checks-metrics")
	# --no-stacktrace
	var opt_no_stacktrace = new OptionBool("Disable the generation of stack traces", "--no-stacktrace")
	# --no-gcc-directives
	var opt_no_gcc_directive = new OptionArray("Disable advanced gcc directives for optimization", "--no-gcc-directive")
	# --release
	var opt_release = new OptionBool("Compile in release mode and finalize application", "--release")
	# -g
	var opt_debug = new OptionBool("Compile in debug mode (no C-side optimization)", "-g", "--debug")
	# --trace
	var opt_trace = new OptionBool("Compile with lttng's instrumentation", "--trace")

	redef init
	do
		super
		self.option_context.add_option(self.opt_output, self.opt_dir, self.opt_run, self.opt_no_cc, self.opt_no_main, self.opt_shared_lib, self.opt_make_flags, self.opt_compile_dir, self.opt_hardening)
		self.option_context.add_option(self.opt_no_check_covariance, self.opt_no_check_attr_isset, self.opt_no_check_assert, self.opt_no_check_autocast, self.opt_no_check_null, self.opt_no_check_all)
		self.option_context.add_option(self.opt_typing_test_metrics, self.opt_invocation_metrics, self.opt_isset_checks_metrics)
		self.option_context.add_option(self.opt_no_stacktrace)
		self.option_context.add_option(self.opt_no_gcc_directive)
		self.option_context.add_option(self.opt_release)
		self.option_context.add_option(self.opt_max_c_lines, self.opt_group_c_files)
		self.option_context.add_option(self.opt_debug)
		self.option_context.add_option(self.opt_trace)

		opt_no_main.hidden = true
		opt_shared_lib.hidden = true
	end

	redef fun process_options(args)
	do
		super

		if opt_output.value != null and opt_dir.value != null then
			print "Option Error: cannot use both --dir and --output"
			exit(1)
		end

		if opt_no_check_all.value then
			opt_no_check_covariance.value = true
			opt_no_check_attr_isset.value = true
			opt_no_check_assert.value = true
			opt_no_check_autocast.value = true
			opt_no_check_null.value = true
		end
	end
end

redef class ModelBuilder
	# Simple indirection to `Toolchain::write_and_make`
	protected fun write_and_make(compiler: AbstractCompiler)
	do
		var platform = compiler.target_platform
		var toolchain = platform.toolchain(toolcontext, compiler)
		compiler.toolchain = toolchain
		toolchain.write_and_make
	end
end

redef class Platform
	# The specific tool-chain associated to the platform
	fun toolchain(toolcontext: ToolContext, compiler: AbstractCompiler): Toolchain
	do
		return new MakefileToolchain(toolcontext, compiler)
	end
end

# Build toolchain for a specific target program, varies per `Platform`
class Toolchain

	# Toolcontext
	var toolcontext: ToolContext

	# Compiler of the target program
	var compiler: AbstractCompiler

	# Directory where to generate all files
	#
	# The option `--compile_dir` change this directory.
	fun root_compile_dir: String
	do
		var compile_dir = toolcontext.opt_compile_dir.value
		if compile_dir == null then compile_dir = "nit_compile"
		return compile_dir
	end

	# Directory where to generate all C files
	#
	# By default it is `root_compile_dir` but some platform may require that it is a subdirectory.
	fun compile_dir: String do return root_compile_dir

	# Write all C files and compile them
	fun write_and_make is abstract
end

# Default toolchain using a Makefile
class MakefileToolchain
	super Toolchain

	redef fun write_and_make
	do
		var debug = toolcontext.opt_debug.value
		var compile_dir = compile_dir

		# Remove the compilation directory unless explicitly set
		var auto_remove = toolcontext.opt_compile_dir.value == null
		# If debug flag is set, do not remove sources
		if debug then auto_remove = false

		# Generate the .h and .c files
		# A single C file regroups many compiled rumtime functions
		# Note that we do not try to be clever an a small change in a Nit source file may change the content of all the generated .c files
		var time0 = get_time
		self.toolcontext.info("*** WRITING C ***", 1)

		root_compile_dir.mkdir
		compile_dir.mkdir

		var cfiles = new Array[String]
		write_files(compile_dir, cfiles)

		# Generate the Makefile

		write_makefile(compile_dir, cfiles)

		var time1 = get_time
		self.toolcontext.info("*** END WRITING C: {time1-time0} ***", 2)

		toolcontext.check_errors

		# Execute the Makefile

		if self.toolcontext.opt_no_cc.value then return

		time0 = time1
		self.toolcontext.info("*** COMPILING C ***", 1)

		compile_c_code(compile_dir)

		if auto_remove then
			sys.system("rm -r -- '{root_compile_dir.escape_to_sh}/'")
		end

		if toolcontext.opt_run.value then
			var mainmodule = compiler.mainmodule
			var out = outfile(mainmodule)
			var cmd = ["."/out]
			cmd.append toolcontext.option_context.rest
			toolcontext.exec_and_check(cmd, "--run")
		end

		time1 = get_time
		self.toolcontext.info("*** END COMPILING C: {time1-time0} ***", 2)
	end

	# Write all source files to the `compile_dir`
	fun write_files(compile_dir: String, cfiles: Array[String])
	do
		var platform = compiler.target_platform
		if platform.supports_libunwind then compiler.build_c_to_nit_bindings
		var cc_opt_with_libgc = "-DWITH_LIBGC"
		if not platform.supports_libgc then cc_opt_with_libgc = ""

		# Add gc_choser.h to aditionnal bodies
		var gc_chooser = new ExternCFile("gc_chooser.c", cc_opt_with_libgc)
		if cc_opt_with_libgc != "" then gc_chooser.pkgconfigs.add "bdw-gc"
		compiler.extern_bodies.add(gc_chooser)
		var clib = toolcontext.nit_dir / "clib"
		compiler.files_to_copy.add "{clib}/gc_chooser.c"
		compiler.files_to_copy.add "{clib}/gc_chooser.h"

		# Add lttng traces provider to external bodies
		if toolcontext.opt_trace.value then
			#-I. is there in order to make the TRACEPOINT_INCLUDE directive in clib/traces.h refer to the directory in which gcc was invoked.
			var traces = new ExternCFile("traces.c", "-I.")
			traces.pkgconfigs.add "lttng-ust"
			compiler.extern_bodies.add(traces)
			compiler.files_to_copy.add "{clib}/traces.c"
			compiler.files_to_copy.add "{clib}/traces.h"
		end

		# FFI
		for m in compiler.mainmodule.in_importation.greaters do
			compiler.finalize_ffi_for_module(m)
		end

		# Copy original .[ch] files to compile_dir
		for src in compiler.files_to_copy do
			var basename = src.basename
			var dst = "{compile_dir}/{basename}"
			src.file_copy_to dst
		end

		var hfilename = compiler.header.file.name + ".h"
		var hfilepath = "{compile_dir}/{hfilename}"
		var h = new FileWriter.open(hfilepath)
		for l in compiler.header.decl_lines do
			h.write l
			h.write "\n"
		end
		for l in compiler.header.lines do
			h.write l
			h.write "\n"
		end
		h.close

		var max_c_lines = toolcontext.opt_max_c_lines.value
		for f in compiler.files do
			var i = 0
			var count = 0
			var file: nullable FileWriter = null
			for vis in f.writers do
				if vis == compiler.header then continue
				var total_lines = vis.lines.length + vis.decl_lines.length
				if total_lines == 0 then continue
				count += total_lines
				if file == null or (count > max_c_lines and max_c_lines > 0) then
					i += 1
					if file != null then file.close
					var cfilename = "{f.name}.{i}.c"
					var cfilepath = "{compile_dir}/{cfilename}"
					self.toolcontext.info("new C source files to compile: {cfilepath}", 3)
					cfiles.add(cfilename)
					file = new FileWriter.open(cfilepath)
					file.write "#include \"{f.name}.0.h\"\n"
					count = total_lines
				end
				for l in vis.decl_lines do
					file.write l
					file.write "\n"
				end
				for l in vis.lines do
					file.write l
					file.write "\n"
				end
			end
			if file == null then continue
			file.close

			var cfilename = "{f.name}.0.h"
			var cfilepath = "{compile_dir}/{cfilename}"
			var hfile: nullable FileWriter = null
			hfile = new FileWriter.open(cfilepath)
			hfile.write "#include \"{hfilename}\"\n"
			for key in f.required_declarations do
				if not compiler.provided_declarations.has_key(key) then
					var node = compiler.requirers_of_declarations.get_or_null(key)
					if node != null then
						node.debug "No provided declaration for {key}"
					else
						print "No provided declaration for {key}"
					end
					abort
				end
				hfile.write compiler.provided_declarations[key]
				hfile.write "\n"
			end
			hfile.close
		end

		self.toolcontext.info("Total C source files to compile: {cfiles.length}", 2)
	end

	# Get the name of the Makefile to use
	fun makefile_name: String do return "{compiler.mainmodule.c_name}.mk"

	# Get the default name of the executable to produce
	fun default_outname: String
	do
		var mainmodule = compiler.mainmodule.first_real_mmodule
		return mainmodule.name
	end

	# Combine options and platform informations to get the final path of the outfile
	fun outfile(mainmodule: MModule): String
	do
		var res = self.toolcontext.opt_output.value
		if res != null then return res
		res = default_outname
		var dir = self.toolcontext.opt_dir.value
		if dir != null then return dir.join_path(res)
		return res
	end

	# Write the Makefile
	fun write_makefile(compile_dir: String, cfiles: Array[String])
	do
		var mainmodule = compiler.mainmodule
		var platform = compiler.target_platform

		var outname = outfile(mainmodule)

		var real_outpath = compile_dir.relpath(outname)
		var outpath = real_outpath.escape_to_mk
		if outpath != real_outpath then
			# If the name is crazy and need escaping, we will do an indirection
			# 1. generate the binary in the nit_compile dir under an escaped name
			# 2. copy the binary at the right place in the `all` goal.
			outpath = mainmodule.c_name
		end
		var makename = makefile_name
		var makepath = "{compile_dir}/{makename}"
		var makefile = new FileWriter.open(makepath)

		var linker_options = new HashSet[String]
		for m in mainmodule.in_importation.greaters do
			var libs = m.collect_linker_libs
			if libs != null then linker_options.add_all(libs)
		end
		var debug = toolcontext.opt_debug.value

		makefile.write """
ifeq ($(origin CC), default)
        CC = ccache cc
endif
ifeq ($(origin CXX), default)
        CXX = ccache c++
endif
CFLAGS ?= -g {{{if not debug then "-O2" else ""}}} -Wno-unused-value -Wno-switch -Wno-attributes -Wno-trigraphs -Wno-switch-unreachable
CINCL =
LDFLAGS ?=
LDLIBS  ?= -lm {{{linker_options.join(" ")}}}
\n"""

		if self.toolcontext.opt_trace.value then makefile.write "LDLIBS += -llttng-ust -ldl\n"

		if toolcontext.opt_shared_lib.value then
			makefile.write """
CFLAGS += -fPIC
LDFLAGS += -shared -Wl,-soname,{{{outname}}}
"""
		end

		makefile.write "\n# SPECIAL CONFIGURATION FLAGS\n"
		if platform.supports_libunwind then
			if toolcontext.opt_no_stacktrace.value then
				makefile.write "NO_STACKTRACE ?= True"
			else
				makefile.write "NO_STACKTRACE ?= # Set to `True` to enable"
			end
		end

		# Dynamic adaptations
		# While `platform` enable complex toolchains, they are statically applied
		# For a dynamic adaptsation of the compilation, the generated Makefile should check and adapt things itself
		makefile.write "\n\n"

		# Check and adapt the targeted system
		makefile.write("uname_S := $(shell sh -c 'uname -s 2>/dev/null || echo not')\n")

		# Check and adapt for the compiler used
		# clang need an additionnal `-Qunused-arguments`
		makefile.write("clang_check := $(shell sh -c '$(CC) -v 2>&1 | grep -q clang; echo $$?')\nifeq ($(clang_check), 0)\n\tCFLAGS += -Qunused-arguments\nendif\n")

		if platform.supports_libunwind then
			makefile.write """
ifneq ($(NO_STACKTRACE), True)
  # Check and include lib-unwind in a portable way
  ifneq ($(uname_S),Darwin)
    # already included on macosx, but need to get the correct flags in other supported platforms.
    ifeq ($(shell pkg-config --exists 'libunwind'; echo $$?), 0)
      LDLIBS += `pkg-config --libs libunwind`
      CFLAGS += `pkg-config --cflags libunwind`
    else
      $(warning "[_] stack-traces disabled. Please install libunwind-dev.")
      CFLAGS += -D NO_STACKTRACE
    endif
  endif
else
  # Stacktraces disabled
  CFLAGS += -D NO_STACKTRACE
endif

"""
		else
			makefile.write("CFLAGS += -D NO_STACKTRACE\n\n")
		end

		makefile.write """
# Special configuration for Darwin
ifeq ($(uname_S),Darwin)
	# Remove POSIX flag -lrt
	LDLIBS := $(filter-out -lrt,$(LDLIBS))
endif

# Special configuration for Windows under mingw64
ifneq ($(findstring MINGW64,$(uname_S)),)
	# Use the pcreposix regex library
	LDLIBS += -lpcreposix

	# Remove POSIX flag -lrt
	LDLIBS := $(filter-out -lrt,$(LDLIBS))

	# Silence warnings when storing Int, Char and Bool as pointer address
	CFLAGS += -Wno-pointer-to-int-cast -Wno-int-to-pointer-cast
endif

# Add the compilation dir to the Java CLASSPATH
ifeq ($(CLASSPATH),)
	CLASSPATH := .
else
	CLASSPATH := $(CLASSPATH):.
endif

"""

		makefile.write("all: {outpath}\n")
		if outpath != real_outpath then
			makefile.write("\tcp -- {outpath.escape_to_sh} {real_outpath.escape_to_sh.replace("$","$$")}")
		end
		makefile.write("\n")

		var ofiles = new Array[String]
		var dep_rules = new Array[String]
		# Compile each generated file
		for f in cfiles do
			var o = f.strip_extension(".c") + ".o"
			makefile.write("{o}: {f}\n\t$(CC) $(CFLAGS) $(CINCL) -c -o {o} {f}\n\n")
			ofiles.add(o)
			dep_rules.add(o)
		end

		# Generate linker script, if any
		if not compiler.linker_script.is_empty then
			var linker_script_path = "{compile_dir}/linker_script"
			ofiles.add "linker_script"
			var f = new FileWriter.open(linker_script_path)
			for l in compiler.linker_script do
				f.write l
				f.write "\n"
			end
			f.close
		end

		# pkg-config annotation support
		var pkgconfigs = new Array[String]
		for f in compiler.extern_bodies do
			pkgconfigs.add_all f.pkgconfigs
		end

		# Only test if pkg-config is used
		if not pkgconfigs.is_empty then

			# Check availability of pkg-config, silence the proc output
			toolcontext.check_pkgconfig_packages pkgconfigs

			# Double the check in the Makefile in case it's distributed
			makefile.write """
# does pkg-config exists?
ifneq ($(shell which pkg-config >/dev/null; echo $$?), 0)
$(error "Command `pkg-config` not found. Please install it")
endif
"""
			for p in pkgconfigs do
				makefile.write """
# Check for library {{{p}}}
ifneq ($(shell pkg-config --exists '{{{p}}}'; echo $$?), 0)
$(error "pkg-config: package {{{p}}} is not found.")
endif
"""
			end
		end

		# Compile each required extern body into a specific .o
		var java_files = new Array[ExternFile]
		for f in compiler.extern_bodies do
			var o = f.makefile_rule_name
			makefile.write("{o}: {f.filename}\n")
			makefile.write("\t{f.makefile_rule_content}\n\n")
			dep_rules.add(f.makefile_rule_name)

			if f.compiles_to_o_file then ofiles.add(o)
			if f.add_to_jar then java_files.add(f)
		end

		if not java_files.is_empty then
			var jar_file = "{outpath}.jar"

			var class_files_array = new Array[String]
			for f in java_files do class_files_array.add(f.makefile_rule_name)
			var class_files = class_files_array.join(" ")

			makefile.write("{jar_file}: {class_files}\n")
			makefile.write("\tjar cf {jar_file} {class_files}\n\n")
			dep_rules.add jar_file
		end

		# Link edition
		var pkg = ""
		if not pkgconfigs.is_empty then
			pkg = "`pkg-config --libs {pkgconfigs.join(" ")}`"
		end
		makefile.write("{outpath}: {dep_rules.join(" ")}\n\t$(CC) $(LDFLAGS) -o {outpath.escape_to_sh} {ofiles.join(" ")} $(LDLIBS) {pkg}\n\n")
		# Clean
		makefile.write("clean:\n\trm -f {ofiles.join(" ")} 2>/dev/null\n")
		if outpath != real_outpath then
			makefile.write("\trm -f -- {outpath.escape_to_sh} 2>/dev/null\n")
		end
		makefile.close
		self.toolcontext.info("Generated makefile: {makepath}", 2)

		makepath.file_copy_to "{compile_dir}/Makefile"
	end

	# The C code is generated, compile it to an executable
	fun compile_c_code(compile_dir: String)
	do
		var makename = makefile_name

		var makeflags = self.toolcontext.opt_make_flags.value
		if makeflags == null then makeflags = ""

		var command = "make -B -C {compile_dir} -f {makename} -j 4 {makeflags}"
		self.toolcontext.info(command, 2)

		var res
		if self.toolcontext.verbose_level >= 3 then
			res = sys.system("{command} 2>&1")
		else if is_windows then
			res = sys.system("{command} 2>&1 >nul")
		else
			res = sys.system("{command} 2>&1 >/dev/null")
		end
		if res != 0 then
			toolcontext.error(null, "Compilation Error: `make` failed with error code: {res}. The command was `{command}`.")
		end
	end
end

# Singleton that store the knowledge about the compilation process
abstract class AbstractCompiler
	type VISITOR: AbstractCompilerVisitor

	# Table corresponding c_names to nit names (methods)
	var names = new HashMap[String, String]

	# The main module of the program currently compiled
	# Is assigned during the separate compilation
	var mainmodule: MModule is writable

	# The real main module of the program
	var realmainmodule: MModule is noinit

	# The modelbuilder used to know the model and the AST
	var modelbuilder: ModelBuilder is protected writable

	# The associated toolchain
	#
	# Set by `modelbuilder.write_and_make` and permit sub-routines to access the current toolchain if required.
	var toolchain: Toolchain is noinit

	# Is hardening asked? (see --hardening)
	fun hardening: Bool do return self.modelbuilder.toolcontext.opt_hardening.value

	# The targeted specific platform
	var target_platform: Platform is noinit

	# All methods who already has a callref_thunk generated for
	var compiled_callref_thunk = new HashSet[MMethodDef]

	var all_routine_types_name: Set[String] do
		var res = new HashSet[String]
		for name in ["Fun", "Proc", "FunRef", "ProcRef"] do
			# Currently there's 20 arity per func type
			for i in [0..20[ do
				res.add("{name}{i}")
			end
		end
		return res
	end

	init
	do
		self.realmainmodule = mainmodule
		target_platform = mainmodule.target_platform or else new Platform
	end

	# Do the full code generation of the program `mainmodule`
	# It is the main method usually called after the instantiation
	fun do_compilation is abstract

	# Force the creation of a new file
	# The point is to avoid contamination between must-be-compiled-separately files
	fun new_file(name: String): CodeFile
	do
		if modelbuilder.toolcontext.opt_group_c_files.value then
			if self.files.is_empty then
				var f = new CodeFile(mainmodule.c_name)
				self.files.add(f)
			end
			return self.files.first
		end
		var f = new CodeFile(name)
		self.files.add(f)
		return f
	end

	# The list of all associated files
	# Used to generate .c files
	var files = new Array[CodeFile]

	# Initialize a visitor specific for a compiler engine
	fun new_visitor: VISITOR is abstract

	# Where global declaration are stored (the main .h)
	var header: CodeWriter is writable, noinit

	# Additionnal linker script for `ld`.
	# Mainly used to do specific link-time symbol resolution
	var linker_script = new Array[String]

	# Provide a declaration that can be requested (before or latter) by a visitor
	fun provide_declaration(key: String, s: String)
	do
		if self.provided_declarations.has_key(key) then
			assert self.provided_declarations[key] == s
		end
		self.provided_declarations[key] = s
	end

	private var provided_declarations = new HashMap[String, String]

	private var requirers_of_declarations = new HashMap[String, ANode]

	# Builds the .c and .h files to be used when generating a Stack Trace
	# Binds the generated C function names to Nit function names
	fun build_c_to_nit_bindings
	do
		var compile_dir = toolchain.compile_dir

		var stream = new FileWriter.open("{compile_dir}/c_functions_hash.c")
		stream.write("#include <string.h>\n")
		stream.write("#include <stdlib.h>\n")
		stream.write("#include \"c_functions_hash.h\"\n")
		stream.write("typedef struct C_Nit_Names\{char* name; char* nit_name;\}C_Nit_Names;\n")
		stream.write("const char* get_nit_name(register const char* procproc, register unsigned int len)\{\n")
		stream.write("char* procname = malloc(len+1);")
		stream.write("memcpy(procname, procproc, len);")
		stream.write("procname[len] = '\\0';")
		stream.write("static const C_Nit_Names map[{names.length}] = \{\n")
		for i in names.keys do
			stream.write("\{\"")
			stream.write(i.escape_to_c)
			stream.write("\",\"")
			stream.write(names[i].escape_to_c)
			stream.write("\"\},\n")
		end
		stream.write("\};\n")
		stream.write("int i;")
		stream.write("for(i = 0; i < {names.length}; i++)\{")
		stream.write("if(strcmp(procname,map[i].name) == 0)\{")
		stream.write("free(procname);")
		stream.write("return map[i].nit_name;")
		stream.write("\}")
		stream.write("\}")
		stream.write("free(procname);")
		stream.write("return NULL;")
		stream.write("\}\n")
		stream.close

		stream = new FileWriter.open("{compile_dir}/c_functions_hash.h")
		stream.write("const char* get_nit_name(register const char* procname, register unsigned int len);\n")
		stream.close

		extern_bodies.add(new ExternCFile("c_functions_hash.c", ""))
	end

	# Compile C headers
	# This method call compile_header_strucs method that has to be refined
	fun compile_header do
		self.header.add_decl("#include <stdlib.h>")
		self.header.add_decl("#include <stdio.h>")
		self.header.add_decl("#include <string.h>")
		# longjmp !
		self.header.add_decl("#include <setjmp.h>\n")
		self.header.add_decl("#include <sys/types.h>\n")
		self.header.add_decl("#include <unistd.h>\n")
		self.header.add_decl("#include <stdint.h>\n")
		self.header.add_decl("#ifdef __linux__")
		self.header.add_decl("	#include <endian.h>")
		self.header.add_decl("#endif")
		self.header.add_decl("#include <inttypes.h>\n")
		self.header.add_decl("#include \"gc_chooser.h\"")
		if modelbuilder.toolcontext.opt_trace.value then self.header.add_decl("#include \"traces.h\"")
		self.header.add_decl("#ifdef __APPLE__")
		self.header.add_decl("	#include <TargetConditionals.h>")
		self.header.add_decl("	#include <syslog.h>")
		self.header.add_decl("	#include <libkern/OSByteOrder.h>")
		self.header.add_decl("	#define be32toh(x) OSSwapBigToHostInt32(x)")
		self.header.add_decl("#endif")
		self.header.add_decl("#ifdef _WIN32")
		self.header.add_decl("	#define be32toh(val) _byteswap_ulong(val)")
		self.header.add_decl("#endif")
		self.header.add_decl("#ifdef ANDROID")
		self.header.add_decl("	#ifndef be32toh")
		self.header.add_decl("		#define be32toh(val) betoh32(val)")
		self.header.add_decl("	#endif")
		self.header.add_decl("	#include <android/log.h>")
		self.header.add_decl("	#define PRINT_ERROR(...) (void)__android_log_print(ANDROID_LOG_WARN, \"Nit\", __VA_ARGS__)")
		self.header.add_decl("#elif TARGET_OS_IPHONE")
		self.header.add_decl("	#define PRINT_ERROR(...) syslog(LOG_ERR, __VA_ARGS__)")
		self.header.add_decl("#else")
		self.header.add_decl("	#define PRINT_ERROR(...) fprintf(stderr, __VA_ARGS__)")
		self.header.add_decl("#endif")

		compile_header_structs
		compile_nitni_structs
		compile_catch_stack

		var gccd_disable = modelbuilder.toolcontext.opt_no_gcc_directive.value
		if gccd_disable.has("noreturn") or gccd_disable.has("all") then
			# Signal handler function prototype
			self.header.add_decl("void fatal_exit(int);")
		else
			self.header.add_decl("void fatal_exit(int) __attribute__ ((noreturn));")
		end

		if gccd_disable.has("likely") or gccd_disable.has("all") then
			self.header.add_decl("#define likely(x)       (x)")
			self.header.add_decl("#define unlikely(x)     (x)")
		else if gccd_disable.has("correct-likely") then
			# invert the `likely` definition
			# Used by masochists to bench the worst case
			self.header.add_decl("#define likely(x)       __builtin_expect((x),0)")
			self.header.add_decl("#define unlikely(x)     __builtin_expect((x),1)")
		else
			self.header.add_decl("#define likely(x)       __builtin_expect((x),1)")
			self.header.add_decl("#define unlikely(x)     __builtin_expect((x),0)")
		end

		# Global variable used by intern methods
		self.header.add_decl("extern int glob_argc;")
		self.header.add_decl("extern char **glob_argv;")
		self.header.add_decl("extern val *glob_sys;")
	end

	# Stack stocking environment for longjumps
	protected fun compile_catch_stack do
		self.header.add_decl """
struct catch_stack_t {
	int cursor;
	int currentSize;
	jmp_buf *envs;
};
extern struct catch_stack_t *getCatchStack();
"""
	end

	# Declaration of structures for live Nit types
	protected fun compile_header_structs is abstract

	# Declaration of structures for nitni undelying the FFI
	protected fun compile_nitni_structs
	do
		self.header.add_decl """
/* Native reference to Nit objects */
/* This structure is used to represent every Nit type in extern methods and custom C code. */
struct nitni_ref {
	struct nitni_ref *next,
		*prev; /* adjacent global references in global list */
	int count; /* number of time this global reference has been marked */
};

/* List of global references from C code to Nit objects */
/* Instanciated empty at init of Nit system and filled explicitly by user in C code */
struct nitni_global_ref_list_t {
	struct nitni_ref *head, *tail;
};
extern struct nitni_global_ref_list_t *nitni_global_ref_list;

/* Initializer of global reference list */
extern void nitni_global_ref_list_init();

/* Intern function to add a global reference to the list */
extern void nitni_global_ref_add( struct nitni_ref *ref );

/* Intern function to remove a global reference from the list */
extern void nitni_global_ref_remove( struct nitni_ref *ref );

/* Increase count on an existing global reference */
extern void nitni_global_ref_incr( struct nitni_ref *ref );

/* Decrease count on an existing global reference */
extern void nitni_global_ref_decr( struct nitni_ref *ref );
"""
	end

	fun compile_finalizer_function
	do
		var finalizable_type = mainmodule.finalizable_type
		if finalizable_type == null then return

		var finalize_meth = mainmodule.try_get_primitive_method("finalize", finalizable_type.mclass)

		if finalize_meth == null then
			modelbuilder.toolcontext.error(null, "Error: the `Finalizable` class does not declare the `finalize` method.")
			return
		end

		var v = self.new_visitor
		v.add_decl "void gc_finalize (void *obj, void *client_data) \{"
		var recv = v.new_expr("obj", finalizable_type)
		v.send(finalize_meth, [recv])
		v.add "\}"
	end

	# Hook to add specif piece of code before the the main C function.
	#
	# Is called by `compile_main_function`
	fun compile_before_main(v: VISITOR)
	do
	end

	# Hook to add specif piece of code at the begin on the main C function.
	#
	# Is called by `compile_main_function`
	fun compile_begin_main(v: VISITOR)
	do
	end

	# Generate the main C function.
	#
	# This function:
	#
	# * allocate the Sys object if it exists
	# * call init if is exists
	# * call main if it exists
	fun compile_main_function
	do
		var v = self.new_visitor
		v.add_decl("#include <signal.h>")
		var platform = target_platform

		var no_main = platform.no_main or modelbuilder.toolcontext.opt_no_main.value

		if platform.supports_libunwind then
			v.add_decl("#ifndef NO_STACKTRACE")
			v.add_decl("#define UNW_LOCAL_ONLY")
			v.add_decl("#include <libunwind.h>")
			v.add_decl("#include \"c_functions_hash.h\"")
			v.add_decl("#endif")
		end
		v.add_decl("int glob_argc;")
		v.add_decl("char **glob_argv;")
		v.add_decl("val *glob_sys;")

		# Store catch stack in thread local storage
		v.add_decl """
#if defined(TARGET_OS_IPHONE)
	// Use pthread_key_create and others for iOS
	#include <pthread.h>

	static pthread_key_t catch_stack_key;
	static pthread_once_t catch_stack_key_created = PTHREAD_ONCE_INIT;

	static void create_catch_stack()
	{
		pthread_key_create(&catch_stack_key, NULL);
	}

	struct catch_stack_t *getCatchStack()
	{
		pthread_once(&catch_stack_key_created, &create_catch_stack);
		struct catch_stack_t *data = pthread_getspecific(catch_stack_key);
		if (data == NULL) {
			data = malloc(sizeof(struct catch_stack_t));
			data->cursor = -1;
			data->currentSize = 0;
			data->envs = NULL;
			pthread_setspecific(catch_stack_key, data);
		}
		return data;
	}
#else
	// Use __thread when available
	__thread struct catch_stack_t catchStack = {-1, 0, NULL};

	struct catch_stack_t *getCatchStack()
	{
		return &catchStack;
	}
#endif
"""

		if self.modelbuilder.toolcontext.opt_typing_test_metrics.value then
			for tag in count_type_test_tags do
				v.add_decl("long count_type_test_resolved_{tag};")
				v.add_decl("long count_type_test_unresolved_{tag};")
				v.add_decl("long count_type_test_skipped_{tag};")
				v.compiler.header.add_decl("extern long count_type_test_resolved_{tag};")
				v.compiler.header.add_decl("extern long count_type_test_unresolved_{tag};")
				v.compiler.header.add_decl("extern long count_type_test_skipped_{tag};")
			end
		end

		if self.modelbuilder.toolcontext.opt_invocation_metrics.value then
			v.add_decl("long count_invoke_by_tables;")
			v.add_decl("long count_invoke_by_direct;")
			v.add_decl("long count_invoke_by_inline;")
			v.compiler.header.add_decl("extern long count_invoke_by_tables;")
			v.compiler.header.add_decl("extern long count_invoke_by_direct;")
			v.compiler.header.add_decl("extern long count_invoke_by_inline;")
		end

		if self.modelbuilder.toolcontext.opt_isset_checks_metrics.value then
			v.add_decl("long count_attr_reads = 0;")
			v.add_decl("long count_isset_checks = 0;")
			v.compiler.header.add_decl("extern long count_attr_reads;")
			v.compiler.header.add_decl("extern long count_isset_checks;")
		end

		v.add_decl("static void show_backtrace(void) \{")
		if platform.supports_libunwind then
			v.add_decl("#ifndef NO_STACKTRACE")
			v.add_decl("char* opt = getenv(\"NIT_NO_STACK\");")
			v.add_decl("unw_cursor_t cursor;")
			v.add_decl("if(opt==NULL)\{")
			v.add_decl("unw_context_t uc;")
			v.add_decl("unw_word_t ip;")
			v.add_decl("char* procname = malloc(sizeof(char) * 100);")
			v.add_decl("unw_getcontext(&uc);")
			v.add_decl("unw_init_local(&cursor, &uc);")
			v.add_decl("PRINT_ERROR(\"-------------------------------------------------\\n\");")
			v.add_decl("PRINT_ERROR(\"--   Stack Trace   ------------------------------\\n\");")
			v.add_decl("PRINT_ERROR(\"-------------------------------------------------\\n\");")
			v.add_decl("while (unw_step(&cursor) > 0) \{")
			v.add_decl("	unw_get_proc_name(&cursor, procname, 100, &ip);")
			v.add_decl("	const char* recv = get_nit_name(procname, strlen(procname));")
			v.add_decl("	if (recv != NULL)\{")
			v.add_decl("		PRINT_ERROR(\"` %s\\n\", recv);")
			v.add_decl("	\}else\{")
			v.add_decl("		PRINT_ERROR(\"` %s\\n\", procname);")
			v.add_decl("	\}")
			v.add_decl("\}")
			v.add_decl("PRINT_ERROR(\"-------------------------------------------------\\n\");")
			v.add_decl("free(procname);")
			v.add_decl("\}")
			v.add_decl("#endif /* NO_STACKTRACE */")
		end
		v.add_decl("\}")

		v.add_decl("void sig_handler(int signo)\{")
		v.add_decl "#ifdef _WIN32"
		v.add_decl "PRINT_ERROR(\"Caught signal : %s\\n\", signo);"
		v.add_decl "#else"
		v.add_decl("PRINT_ERROR(\"Caught signal : %s\\n\", strsignal(signo));")
		v.add_decl "#endif"
		v.add_decl("show_backtrace();")
		# rethrows
		v.add_decl("signal(signo, SIG_DFL);")
		v.add_decl "#ifndef _WIN32"
		v.add_decl("kill(getpid(), signo);")
		v.add_decl "#endif"
		v.add_decl("\}")

		v.add_decl("void fatal_exit(int status) \{")
		v.add_decl("show_backtrace();")
		v.add_decl("exit(status);")
		v.add_decl("\}")

		compile_before_main(v)

		if no_main then
			v.add_decl("int nit_main(int argc, char** argv) \{")
		else
			v.add_decl("int main(int argc, char** argv) \{")
		end

		compile_begin_main(v)

		v.add "#if !defined(__ANDROID__) && !defined(TARGET_OS_IPHONE)"
		v.add("signal(SIGABRT, sig_handler);")
		v.add("signal(SIGFPE, sig_handler);")
		v.add("signal(SIGILL, sig_handler);")
		v.add("signal(SIGINT, sig_handler);")
		v.add("signal(SIGTERM, sig_handler);")
		v.add("signal(SIGSEGV, sig_handler);")
		v.add "#endif"
		v.add "#ifndef _WIN32"
		v.add("signal(SIGPIPE, SIG_IGN);")
		v.add "#endif"

		v.add("glob_argc = argc; glob_argv = argv;")
		v.add("initialize_gc_option();")

		v.add "initialize_nitni_global_refs();"

		var main_type = mainmodule.sys_type
		if main_type != null then
			var mainmodule = v.compiler.mainmodule
			var glob_sys = v.init_instance(main_type)
			v.add("glob_sys = {glob_sys};")
			var main_init = mainmodule.try_get_primitive_method("init", main_type.mclass)
			if main_init != null then
				v.send(main_init, [glob_sys])
			end
			var main_method = mainmodule.try_get_primitive_method("run", main_type.mclass) or else
				mainmodule.try_get_primitive_method("main", main_type.mclass)
			if main_method != null then
				v.send(main_method, [glob_sys])
			end
		end

		if self.modelbuilder.toolcontext.opt_typing_test_metrics.value then
			v.add_decl("long count_type_test_resolved_total = 0;")
			v.add_decl("long count_type_test_unresolved_total = 0;")
			v.add_decl("long count_type_test_skipped_total = 0;")
			v.add_decl("long count_type_test_total_total = 0;")
			for tag in count_type_test_tags do
				v.add_decl("long count_type_test_total_{tag};")
				v.add("count_type_test_total_{tag} = count_type_test_resolved_{tag} + count_type_test_unresolved_{tag} + count_type_test_skipped_{tag};")
				v.add("count_type_test_resolved_total += count_type_test_resolved_{tag};")
				v.add("count_type_test_unresolved_total += count_type_test_unresolved_{tag};")
				v.add("count_type_test_skipped_total += count_type_test_skipped_{tag};")
				v.add("count_type_test_total_total += count_type_test_total_{tag};")
			end
			v.add("printf(\"# dynamic count_type_test: total %l\\n\");")
			v.add("printf(\"\\tresolved\\tunresolved\\tskipped\\ttotal\\n\");")
			var tags = count_type_test_tags.to_a
			tags.add("total")
			for tag in tags do
				v.add("printf(\"{tag}\");")
				v.add("printf(\"\\t%ld (%.2f%%)\", count_type_test_resolved_{tag}, 100.0*count_type_test_resolved_{tag}/count_type_test_total_total);")
				v.add("printf(\"\\t%ld (%.2f%%)\", count_type_test_unresolved_{tag}, 100.0*count_type_test_unresolved_{tag}/count_type_test_total_total);")
				v.add("printf(\"\\t%ld (%.2f%%)\", count_type_test_skipped_{tag}, 100.0*count_type_test_skipped_{tag}/count_type_test_total_total);")
				v.add("printf(\"\\t%ld (%.2f%%)\\n\", count_type_test_total_{tag}, 100.0*count_type_test_total_{tag}/count_type_test_total_total);")
			end
		end

		if self.modelbuilder.toolcontext.opt_invocation_metrics.value then
			v.add_decl("long count_invoke_total;")
			v.add("count_invoke_total = count_invoke_by_tables + count_invoke_by_direct + count_invoke_by_inline;")
			v.add("printf(\"# dynamic count_invocation: total %ld\\n\", count_invoke_total);")
			v.add("printf(\"by table: %ld (%.2f%%)\\n\", count_invoke_by_tables, 100.0*count_invoke_by_tables/count_invoke_total);")
			v.add("printf(\"direct:   %ld (%.2f%%)\\n\", count_invoke_by_direct, 100.0*count_invoke_by_direct/count_invoke_total);")
			v.add("printf(\"inlined:  %ld (%.2f%%)\\n\", count_invoke_by_inline, 100.0*count_invoke_by_inline/count_invoke_total);")
		end

		if self.modelbuilder.toolcontext.opt_isset_checks_metrics.value then
			v.add("printf(\"# dynamic attribute reads: %ld\\n\", count_attr_reads);")
			v.add("printf(\"# dynamic isset checks: %ld\\n\", count_isset_checks);")
		end

		v.add("return 0;")
		v.add("\}")

		for m in mainmodule.in_importation.greaters do
			var f = "FILE_"+m.c_name
			v.add "const char {f}[] = \"{m.location.file.filename.escape_to_c}\";"
			provide_declaration(f, "extern const char {f}[];")
		end
	end

	# Copile all C functions related to the [incr|decr]_ref features of the FFI
	fun compile_nitni_global_ref_functions
	do
		var v = self.new_visitor
		v.add """
struct nitni_global_ref_list_t *nitni_global_ref_list;
void initialize_nitni_global_refs() {
	nitni_global_ref_list = (struct nitni_global_ref_list_t*)nit_alloc(sizeof(struct nitni_global_ref_list_t));
	nitni_global_ref_list->head = NULL;
	nitni_global_ref_list->tail = NULL;
}

void nitni_global_ref_add( struct nitni_ref *ref ) {
	if ( nitni_global_ref_list->head == NULL ) {
		nitni_global_ref_list->head = ref;
		ref->prev = NULL;
	} else {
		nitni_global_ref_list->tail->next = ref;
		ref->prev = nitni_global_ref_list->tail;
	}
	nitni_global_ref_list->tail = ref;

	ref->next = NULL;
}

void nitni_global_ref_remove( struct nitni_ref *ref ) {
	if ( ref->prev == NULL ) {
		nitni_global_ref_list->head = ref->next;
	} else {
		ref->prev->next = ref->next;
	}

	if ( ref->next == NULL ) {
		nitni_global_ref_list->tail = ref->prev;
	} else {
		ref->next->prev = ref->prev;
	}
}

extern void nitni_global_ref_incr( struct nitni_ref *ref ) {
	if ( ref->count == 0 ) /* not registered */
	{
		/* add to list */
		nitni_global_ref_add( ref );
	}

	ref->count ++;
}

extern void nitni_global_ref_decr( struct nitni_ref *ref ) {
	if ( ref->count == 1 ) /* was last reference */
	{
		/* remove from list */
		nitni_global_ref_remove( ref );
	}

	ref->count --;
}
"""
	end

	# List of additional files required to compile (FFI)
	var extern_bodies = new Array[ExternFile]

	# List of source files to copy over to the compile dir
	var files_to_copy = new Array[String]

	# This is used to avoid adding an extern file more than once
	private var seen_extern = new ArraySet[String]

	# Generate code that initialize the attributes on a new instance
	fun generate_init_attr(v: VISITOR, recv: RuntimeVariable, mtype: MClassType)
	do
		var cds = mtype.collect_mclassdefs(self.mainmodule).to_a
		self.mainmodule.linearize_mclassdefs(cds)
		for cd in cds do
			for npropdef in modelbuilder.collect_attr_propdef(cd) do
				npropdef.init_expr(v, recv)
			end
		end
	end

	# Generate code that check if an attribute is correctly initialized
	fun generate_check_attr(v: VISITOR, recv: RuntimeVariable, mtype: MClassType)
	do
		var cds = mtype.collect_mclassdefs(self.mainmodule).to_a
		self.mainmodule.linearize_mclassdefs(cds)
		for cd in cds do
			for npropdef in modelbuilder.collect_attr_propdef(cd) do
				npropdef.check_expr(v, recv)
			end
		end
	end

	# stats

	var count_type_test_tags: Array[String] = ["isa", "as", "auto", "covariance", "erasure"]
	var count_type_test_resolved: HashMap[String, Int] = init_count_type_test_tags
	var count_type_test_unresolved: HashMap[String, Int] = init_count_type_test_tags
	var count_type_test_skipped: HashMap[String, Int] = init_count_type_test_tags

	protected fun init_count_type_test_tags: HashMap[String, Int]
	do
		var res = new HashMap[String, Int]
		for tag in count_type_test_tags do
			res[tag] = 0
		end
		return res
	end

	# Display stats about compilation process
	#
	# Metrics used:
	#
	# * type tests against resolved types (`x isa Collection[Animal]`)
	# * type tests against unresolved types (`x isa Collection[E]`)
	# * type tests skipped
	# * type tests total
	fun display_stats
	do
		if self.modelbuilder.toolcontext.opt_typing_test_metrics.value then
			print "# static count_type_test"
			print "\tresolved:\tunresolved\tskipped\ttotal"
			var count_type_test_total = init_count_type_test_tags
			count_type_test_resolved["total"] = 0
			count_type_test_unresolved["total"] = 0
			count_type_test_skipped["total"] = 0
			count_type_test_total["total"] = 0
			for tag in count_type_test_tags do
				count_type_test_total[tag] = count_type_test_resolved[tag] + count_type_test_unresolved[tag] + count_type_test_skipped[tag]
				count_type_test_resolved["total"] += count_type_test_resolved[tag]
				count_type_test_unresolved["total"] += count_type_test_unresolved[tag]
				count_type_test_skipped["total"] += count_type_test_skipped[tag]
				count_type_test_total["total"] += count_type_test_total[tag]
			end
			var count_type_test = count_type_test_total["total"]
			var tags = count_type_test_tags.to_a
			tags.add("total")
			for tag in tags do
				printn tag
				printn "\t{count_type_test_resolved[tag]} ({div(count_type_test_resolved[tag],count_type_test)}%)"
				printn "\t{count_type_test_unresolved[tag]} ({div(count_type_test_unresolved[tag],count_type_test)}%)"
				printn "\t{count_type_test_skipped[tag]} ({div(count_type_test_skipped[tag],count_type_test)}%)"
				printn "\t{count_type_test_total[tag]} ({div(count_type_test_total[tag],count_type_test)}%)"
				print ""
			end
		end
	end

	fun finalize_ffi_for_module(mmodule: MModule) do mmodule.finalize_ffi(self)
end

# C code file generated from the `writers` and the `required_declarations`
#
# A file unit aims to be autonomous and is made or one or more `CodeWriter`s.
class CodeFile
	# Basename of the file, will be appended by `.h` and `.c`
	var name: String

	# `CodeWriter` used in sequence to fill the top of the body, then the bottom
	var writers = new Array[CodeWriter]

	# Required declarations keys
	#
	# See: `provide_declaration`
	var required_declarations = new HashSet[String]
end

# Store generated lines
#
# Instances are added to `file.writers` at construction.
class CodeWriter
	# Parent `CodeFile`
	var file: CodeFile

	# Main lines of code (written at the bottom of the body)
	var lines = new Array[String]

	# Lines of code for declarations (written at the top of the body)
	var decl_lines = new Array[String]

	# Add a line in the main lines of code (to `lines`)
	fun add(s: String) do self.lines.add(s)

	# Add a declaration line (to `decl_lines`)
	#
	# Used for local and global declaration.
	fun add_decl(s: String) do self.decl_lines.add(s)

	init
	do
		file.writers.add(self)
	end
end

# A visitor on the AST of property definition that generate the C code.
abstract class AbstractCompilerVisitor

	type COMPILER: AbstractCompiler

	# The associated compiler
	var compiler: COMPILER

	# The current visited AST node
	var current_node: nullable ANode = null is writable

	# The current `StaticFrame`
	var frame: nullable StaticFrame = null is writable

	# Alias for self.compiler.mainmodule.object_type
	fun object_type: MClassType do return self.compiler.mainmodule.object_type

	# Alias for self.compiler.mainmodule.bool_type
	fun bool_type: MClassType do return self.compiler.mainmodule.bool_type

	var writer: CodeWriter is noinit

	init
	do
		self.writer = new CodeWriter(compiler.files.last)
	end

	# Force to get the primitive property named `name` in the instance `recv` or abort
	fun get_property(name: String, recv: MType): MMethod
	do
		assert recv isa MClassType
		return self.compiler.modelbuilder.force_get_primitive_method(self.current_node, name, recv.mclass, self.compiler.mainmodule)
	end

	fun compile_callsite(callsite: CallSite, arguments: Array[RuntimeVariable]): nullable RuntimeVariable
	do
		if callsite.is_broken then return null
		return self.send(callsite.mproperty, arguments)
	end

	fun native_array_instance(elttype: MType, length: RuntimeVariable): RuntimeVariable is abstract

	fun native_array_def(pname: String, ret_type: nullable MType, arguments: Array[RuntimeVariable]): Bool do return false

	# Return an element of a native array.
	# The method is unsafe and is just a direct wrapper for the specific implementation of native arrays
	fun native_array_get(native_array: RuntimeVariable, index: Int): RuntimeVariable is abstract

	# Store an element in a native array.
	# The method is unsafe and is just a direct wrapper for the specific implementation of native arrays
	fun native_array_set(native_array: RuntimeVariable, index: Int, value: RuntimeVariable) is abstract

	# Instantiate a new routine pointer
	fun routine_ref_instance(routine_mclass_type: MClassType, recv: RuntimeVariable, callsite: CallSite): RuntimeVariable is abstract

	# Call the underlying referenced function
	fun routine_ref_call(mmethoddef: MMethodDef, args: Array[RuntimeVariable]) is abstract

	# Allocate `size` bytes with the low_level `nit_alloc` C function
	#
	# This method can be redefined to inject statistic or tracing code.
	#
	# `tag` if any, is used to mark the class of the allocated object.
	fun nit_alloc(size: String, tag: nullable String): String
	do
		return "nit_alloc({size})"
	end

	# Evaluate `args` as expressions in the call of `mpropdef` on `recv`.
	# This method is used to manage varargs in signatures and returns the real array
	# of runtime variables to use in the call.
	fun varargize(mpropdef: MMethodDef, map: nullable SignatureMap, recv: RuntimeVariable, args: SequenceRead[AExpr]): Array[RuntimeVariable]
	do
		var msignature = mpropdef.msignature.as(not null)
		var res = new Array[RuntimeVariable]
		res.add(recv)

		if msignature.arity == 0 then return res

		if map == null then
			assert args.length == msignature.arity
			for ne in args do
				res.add self.expr(ne, null)
			end
			return res
		end

		# Eval in order of arguments, not parameters
		var exprs = new Array[RuntimeVariable].with_capacity(args.length)
		for ne in args do
			exprs.add self.expr(ne, null)
		end

		# Fill `res` with the result of the evaluation according to the mapping
		for i in [0..msignature.arity[ do
			var param = msignature.mparameters[i]
			var j = map.map.get_or_null(i)
			if j == null then
				# default value
				res.add(null_instance)
				continue
			end
			if param.is_vararg and args[i].vararg_decl > 0 then
				var vararg = exprs.sub(j, args[i].vararg_decl)
				var elttype = param.mtype
				var arg = self.vararg_instance(mpropdef, recv, vararg, elttype)
				res.add(arg)
				continue
			end
			res.add exprs[j]
		end
		return res
	end

	# Type handling

	# Anchor a type to the main module and the current receiver
	fun anchor(mtype: MType): MType
	do
		if not mtype.need_anchor then return mtype
		return mtype.anchor_to(self.compiler.mainmodule, self.frame.receiver)
	end

	fun resolve_for(mtype: MType, recv: RuntimeVariable): MType
	do
		if not mtype.need_anchor then return mtype
		return mtype.resolve_for(recv.mcasttype, self.frame.receiver, self.compiler.mainmodule, true)
	end

	# Unsafely cast a value to a new type
	# ie the result share the same C variable but my have a different mcasttype
	# NOTE: if the adaptation is useless then `value` is returned as it.
	# ENSURE: `result.name == value.name`
	fun autoadapt(value: RuntimeVariable, mtype: MType): RuntimeVariable
	do
		mtype = self.anchor(mtype)
		var valmtype = value.mcasttype

		# CPrimitive is the best you can do
		if valmtype.is_c_primitive then
			return value
		end

		# Do nothing if useless autocast
		if valmtype.is_subtype(self.compiler.mainmodule, null, mtype) then
			return value
		end

		# Just as_not_null if the target is not nullable.
		#
		# eg `nullable PreciseType` adapted to `Object` gives precisetype.
		if valmtype isa MNullableType and valmtype.mtype.is_subtype(self.compiler.mainmodule, null, mtype) then
			mtype = valmtype.mtype
		end

		var res = new RuntimeVariable(value.name, value.mtype, mtype)
		return res
	end

	# Generate a super call from a method definition
	fun supercall(m: MMethodDef, recvtype: MClassType, args: Array[RuntimeVariable]): nullable RuntimeVariable is abstract

	# Adapt the arguments of a method according to targetted `MMethodDef`
	fun adapt_signature(m: MMethodDef, args: Array[RuntimeVariable]) is abstract

	# Unbox all the arguments of a method when implemented `extern` or `intern`
	fun unbox_signature_extern(m: MMethodDef, args: Array[RuntimeVariable]) is abstract

	# Box or unbox a value to another type iff a C type conversion is needed
	# ENSURE: `result.mtype.ctype == mtype.ctype`
	fun autobox(value: RuntimeVariable, mtype: MType): RuntimeVariable is abstract

	# Box extern classes to be used in the generated code
	fun box_extern(value: RuntimeVariable, mtype: MType): RuntimeVariable is abstract

	# Unbox extern classes to be used in extern code (legacy NI and FFI)
	fun unbox_extern(value: RuntimeVariable, mtype: MType): RuntimeVariable is abstract

	#  Generate a polymorphic subtype test
	fun type_test(value: RuntimeVariable, mtype: MType, tag: String): RuntimeVariable is abstract

	#  Generate the code required to dynamically check if 2 objects share the same runtime type
	fun is_same_type_test(value1, value2: RuntimeVariable): RuntimeVariable is abstract

	#  Generate a Nit "is" for two runtime_variables
	fun equal_test(value1, value2: RuntimeVariable): RuntimeVariable is abstract

	# Sends

	#  Generate a static call on a method definition
	fun call(m: MMethodDef, recvtype: MClassType, args: Array[RuntimeVariable]): nullable RuntimeVariable is abstract

	#  Generate a polymorphic send for the method `m` and the arguments `args`
	fun send(m: MMethod, args: Array[RuntimeVariable]): nullable RuntimeVariable is abstract

	# Generate a monomorphic send for the method `m`, the type `t` and the arguments `args`
	fun monomorphic_send(m: MMethod, t: MType, args: Array[RuntimeVariable]): nullable RuntimeVariable
	do
		assert t isa MClassType
		var propdef = m.lookup_first_definition(self.compiler.mainmodule, t)
		return self.call(propdef, t, args)
	end

	# Generate a monomorphic super send from the method `m`, the type `t` and the arguments `args`
	fun monomorphic_super_send(m: MMethodDef, t: MType, args: Array[RuntimeVariable]): nullable RuntimeVariable
	do
		assert t isa MClassType
		m = m.lookup_next_definition(self.compiler.mainmodule, t)
		return self.call(m, t, args)
	end

	# Attributes handling

	# Generate a polymorphic attribute is_set test
	fun isset_attribute(a: MAttribute, recv: RuntimeVariable): RuntimeVariable is abstract

	# Generate a polymorphic attribute read
	fun read_attribute(a: MAttribute, recv: RuntimeVariable): RuntimeVariable is abstract

	# Generate a polymorphic attribute write
	fun write_attribute(a: MAttribute, recv: RuntimeVariable, value: RuntimeVariable) is abstract

	# Checks

	# Can value be null? (according to current knowledge)
	fun maybe_null(value: RuntimeVariable): Bool
	do
		return value.mcasttype isa MNullableType or value.mcasttype isa MNullType
	end

	# Add a check and an abort for a null receiver if needed
	fun check_recv_notnull(recv: RuntimeVariable)
	do
		if self.compiler.modelbuilder.toolcontext.opt_no_check_null.value then return

		if maybe_null(recv) then
			self.add("if (unlikely({recv} == NULL)) \{")
			self.add_abort("Receiver is null")
			self.add("\}")
		end
	end

	# Names handling

	private var names = new HashSet[String]
	private var last: Int = 0

	# Return a new name based on `s` and unique in the visitor
	fun get_name(s: String): String
	do
		if not self.names.has(s) then
			self.names.add(s)
			return s
		end
		var i = self.last + 1
		loop
			var s2 = s + i.to_s
			if not self.names.has(s2) then
				self.last = i
				self.names.add(s2)
				return s2
			end
			i = i + 1
		end
	end

	# Return an unique and stable identifier associated with an escapemark
	fun escapemark_name(e: nullable EscapeMark): String
	do
		assert e != null
		if frame.escapemark_names.has_key(e) then return frame.escapemark_names[e]
		var name = e.name
		if name == null then name = "label"
		name = get_name(name)
		frame.escapemark_names[e] = name
		return name
	end

	# Insert a C label for associated with an escapemark
	fun add_escape_label(e: nullable EscapeMark)
	do
		if e == null then return
		if e.escapes.is_empty then return
		add("BREAK_{escapemark_name(e)}: (void)0;")
	end

	# Return a "const char*" variable associated to the classname of the dynamic type of an object
	# NOTE: we do not return a `RuntimeVariable` "CString" as the class may not exist in the module/program
	fun class_name_string(value: RuntimeVariable): String is abstract

	# Variables handling

	protected var variables = new HashMap[Variable, RuntimeVariable]

	# Return the local runtime_variable associated to a Nit local variable
	fun variable(variable: Variable): RuntimeVariable
	do
		if self.variables.has_key(variable) then
			return self.variables[variable]
		else
			var name = self.get_name("var_{variable.name}")
			var mtype = variable.declared_type.as(not null)
			mtype = self.anchor(mtype)
			var res = new RuntimeVariable(name, mtype, mtype)
			self.add_decl("{mtype.ctype} {name} /* var {variable}: {mtype} */;")
			self.variables[variable] = res
			return res
		end
	end

	# Return a new uninitialized local runtime_variable
	fun new_var(mtype: MType): RuntimeVariable
	do
		mtype = self.anchor(mtype)
		var name = self.get_name("var")
		var res = new RuntimeVariable(name, mtype, mtype)
		self.add_decl("{mtype.ctype} {name} /* : {mtype} */;")
		return res
	end

	# The difference with `new_var` is the C static type of the local variable
	fun new_var_extern(mtype: MType): RuntimeVariable
	do
		mtype = self.anchor(mtype)
		var name = self.get_name("var")
		var res = new RuntimeVariable(name, mtype, mtype)
		self.add_decl("{mtype.ctype_extern} {name} /* : {mtype} for extern */;")
		return res
	end

	# Return a new uninitialized named runtime_variable
	fun new_named_var(mtype: MType, name: String): RuntimeVariable
	do
		mtype = self.anchor(mtype)
		var res = new RuntimeVariable(name, mtype, mtype)
		self.add_decl("{mtype.ctype} {name} /* : {mtype} */;")
		return res
	end

	# Correctly assign a left and a right value
	# Boxing and unboxing is performed if required
	fun assign(left, right: RuntimeVariable)
	do
		right = self.autobox(right, left.mtype)
		self.add("{left} = {right};")
	end

	# Generate instances

	# Generate a alloc-instance + init-attributes
	fun init_instance(mtype: MClassType): RuntimeVariable is abstract

	# Allocate and init attributes of an instance of a standard or extern class
	#
	# Does not support universals and the pseudo-internal `NativeArray` class.
	fun init_instance_or_extern(mtype: MClassType): RuntimeVariable
	do
		var recv
		var ctype = mtype.ctype
		assert mtype.mclass.name != "NativeArray"
		if not mtype.is_c_primitive then
			recv = init_instance(mtype)
		else if ctype == "char*" then
			recv = new_expr("NULL/*special!*/", mtype)
		else
			recv = new_expr("({ctype})0/*special!*/", mtype)
		end
		return recv
	end

	# Set a GC finalizer on `recv`, only if `recv` isa Finalizable
	fun set_finalizer(recv: RuntimeVariable)
	do
		var mtype = recv.mtype
		var finalizable_type = compiler.mainmodule.finalizable_type
		if finalizable_type != null and not mtype.need_anchor and
				mtype.is_subtype(compiler.mainmodule, null, finalizable_type) then
			add "gc_register_finalizer({recv});"
		end
	end

	# The currently processed module
	#
	# alias for `compiler.mainmodule`
	fun mmodule: MModule do return compiler.mainmodule

	# Generate an integer value
	fun int_instance(value: Int): RuntimeVariable
	do
		var t = mmodule.int_type
		var res = new RuntimeVariable("{value.to_s}l", t, t)
		return res
	end

	# Generate a byte value
	fun byte_instance(value: Byte): RuntimeVariable
	do
		var t = mmodule.byte_type
		var res = new RuntimeVariable("((unsigned char){value.to_s})", t, t)
		return res
	end

	# Generate an int8 value
	fun int8_instance(value: Int8): RuntimeVariable
	do
		var t = mmodule.int8_type
		var res = new RuntimeVariable("INT8_C({value.to_s})", t, t)
		return res
	end

	# Generate an int16 value
	fun int16_instance(value: Int16): RuntimeVariable
	do
		var t = mmodule.int16_type
		var res = new RuntimeVariable("INT16_C({value.to_s})", t, t)
		return res
	end

	# Generate a uint16 value
	fun uint16_instance(value: UInt16): RuntimeVariable
	do
		var t = mmodule.uint16_type
		var res = new RuntimeVariable("UINT16_C({value.to_s})", t, t)
		return res
	end

	# Generate an int32 value
	fun int32_instance(value: Int32): RuntimeVariable
	do
		var t = mmodule.int32_type
		var res = new RuntimeVariable("INT32_C({value.to_s})", t, t)
		return res
	end

	# Generate a uint32 value
	fun uint32_instance(value: UInt32): RuntimeVariable
	do
		var t = mmodule.uint32_type
		var res = new RuntimeVariable("UINT32_C({value.to_s})", t, t)
		return res
	end

	# Generate a char value
	fun char_instance(value: Char): RuntimeVariable
	do
		var t = mmodule.char_type

		if value.code_point < 128 then
			return new RuntimeVariable("'{value.to_s.escape_to_c}'", t, t)
		else
			return new RuntimeVariable("{value.code_point}", t, t)
		end
	end

	# Generate a float value
	#
	# FIXME pass a Float, not a string
	fun float_instance(value: Float): RuntimeVariable
	do
		var t = mmodule.float_type
		var res = new RuntimeVariable("{value.to_hexa_exponential_notation}", t, t)
		return res
	end

	# Generate an integer value
	fun bool_instance(value: Bool): RuntimeVariable
	do
		var s = if value then "1" else "0"
		var res = new RuntimeVariable(s, bool_type, bool_type)
		return res
	end

	# Generate the `null` value
	fun null_instance: RuntimeVariable
	do
		var t = compiler.mainmodule.model.null_type
		var res = new RuntimeVariable("((val*)NULL)", t, t)
		return res
	end

	# Generates a CString instance fully escaped in C-style \xHH fashion
	fun c_string_instance(ns: CString, len: Int): RuntimeVariable do
		var mtype = mmodule.c_string_type
		var nat = new_var(mtype)
		var byte_esc = new Buffer.with_cap(len * 4)
		for i in [0 .. len[ do
			byte_esc.append("\\x{ns[i].to_hex}")
		end
		self.add("{nat} = \"{byte_esc}\";")
		return nat
	end

	# Generate a string value
	fun string_instance(string: String): RuntimeVariable
	do
		var mtype = mmodule.string_type
		var name = self.get_name("varonce")
		self.add_decl("static {mtype.ctype} {name};")
		var res = self.new_var(mtype)
		self.add("if (likely({name}!=NULL)) \{")
		self.add("{res} = {name};")
		self.add("\} else \{")
		var native_mtype = mmodule.c_string_type
		var nat = self.new_var(native_mtype)
		self.add("{nat} = \"{string.escape_to_c}\";")
		var byte_length = self.int_instance(string.byte_length)
		var unilen = self.int_instance(string.length)
		self.add("{res} = {self.send(self.get_property("to_s_unsafe", native_mtype), [nat, byte_length, unilen, value_instance(false), value_instance(false)]).as(not null)};")
		self.add("{name} = {res};")
		self.add("\}")
		return res
	end

	fun value_instance(object: Object): RuntimeVariable
	do
		if object isa Int then
			return int_instance(object)
		else if object isa Bool then
			return bool_instance(object)
		else if object isa String then
			return string_instance(object)
		else
			abort
		end
	end

	# Generate an array value
	fun array_instance(array: Array[RuntimeVariable], elttype: MType): RuntimeVariable is abstract

	# Get an instance of a array for a vararg
	fun vararg_instance(mpropdef: MPropDef, recv: RuntimeVariable, varargs: Array[RuntimeVariable], elttype: MType): RuntimeVariable is abstract

	# Code generation

	# Add a line in the main part of the generated C
	fun add(s: String) do self.writer.lines.add(s)

	# Add a line in the
	# (used for local or global declaration)
	fun add_decl(s: String) do self.writer.decl_lines.add(s)

	# Request the presence of a global declaration
	fun require_declaration(key: String)
	do
		var reqs = self.writer.file.required_declarations
		if reqs.has(key) then return
		reqs.add(key)
		var node = current_node
		if node != null then compiler.requirers_of_declarations[key] = node
	end

	# Add a declaration in the local-header
	# The declaration is ensured to be present once
	fun declare_once(s: String)
	do
		self.compiler.provide_declaration(s, s)
		self.require_declaration(s)
	end

	# Look for a needed .h and .c file for a given module
	# This is used for the legacy FFI
	fun add_extern(mmodule: MModule)
	do
		var file = mmodule.filepath
		file = file.strip_extension(".nit")
		var tryfile = file + ".nit.h"
		if tryfile.file_exists then
			self.declare_once("#include \"{tryfile.basename}\"")
			self.compiler.files_to_copy.add(tryfile)
		end
		tryfile = file + "_nit.h"
		if tryfile.file_exists then
			self.declare_once("#include \"{tryfile.basename}\"")
			self.compiler.files_to_copy.add(tryfile)
		end

		if self.compiler.seen_extern.has(file) then return
		self.compiler.seen_extern.add(file)
		tryfile = file + ".nit.c"
		if not tryfile.file_exists then
			tryfile = file + "_nit.c"
			if not tryfile.file_exists then return
		end
		var f = new ExternCFile(tryfile.basename, "")
		self.compiler.extern_bodies.add(f)
		self.compiler.files_to_copy.add(tryfile)
	end

	# Return a new local runtime_variable initialized with the C expression `cexpr`.
	fun new_expr(cexpr: String, mtype: MType): RuntimeVariable
	do
		var res = new_var(mtype)
		self.add("{res} = {cexpr};")
		return res
	end

	# Generate generic abort
	# used by aborts, asserts, casts, etc.
	fun add_abort(message: String)
	do
		add_raw_throw
		self.add("PRINT_ERROR(\"Runtime error: %s\", \"{message.escape_to_c}\");")
		add_raw_abort
	end

	# Generate a long jump if there is a catch block.
	#
	# This method should be called before the error messages and before a `add_raw_abort`.
	fun add_raw_throw
	do
		self.add("\{")
		self.add("struct catch_stack_t *catchStack = getCatchStack();")
		self.add("if(catchStack->cursor >= 0)\{")
		self.add("	longjmp(catchStack->envs[catchStack->cursor], 1);")
		self.add("\}")
		self.add("\}")
	end

	# Generate abort without a message.
	#
	# Used when one need a more complex message.
	# Do not forget to call `add_raw_abort` before the display of a custom user message.
	fun add_raw_abort
	do
		var current_node = self.current_node
		if current_node != null and current_node.location.file != null and
				current_node.location.file.mmodule != null then
			var f = "FILE_{self.current_node.location.file.mmodule.c_name}"
			self.require_declaration(f)
			self.add("PRINT_ERROR(\" (%s:%d)\\n\", {f}, {current_node.location.line_start});")
		else
			self.add("PRINT_ERROR(\"\\n\");")
		end
		self.add("fatal_exit(1);")
	end

	# Add a dynamic cast
	fun add_cast(value: RuntimeVariable, mtype: MType, tag: String)
	do
		var res = self.type_test(value, mtype, tag)
		self.add("if (unlikely(!{res})) \{")
		self.add_raw_throw
		var cn = self.class_name_string(value)
		self.add("PRINT_ERROR(\"Runtime error: Cast failed. Expected `%s`, got `%s`\", \"{mtype.to_s.escape_to_c}\", {cn});")
		self.add_raw_abort
		self.add("\}")
	end

	# Generate a return with the value `s`
	fun ret(s: RuntimeVariable)
	do
		self.assign(self.frame.returnvar.as(not null), s)
		self.add("goto {self.frame.returnlabel.as(not null)};")
	end

	# Compile a statement (if any)
	fun stmt(nexpr: nullable AExpr)
	do
		if nexpr == null then return
		if nexpr.is_broken then
			# Untyped expression.
			# Might mean dead code or invalid code
			# so aborts
			add_abort("FATAL: bad statement executed.")
			return
		end

		var narray = nexpr.comprehension
		if narray != null then
			var recv = frame.comprehension.as(not null)
			var val = expr(nexpr, narray.element_mtype)
			compile_callsite(narray.push_callsite.as(not null), [recv, val])
			return
		end

		var old = self.current_node
		self.current_node = nexpr
		nexpr.stmt(self)
		self.current_node = old
	end

	# Compile an expression an return its result
	# `mtype` is the expected return type, pass null if no specific type is expected.
	fun expr(nexpr: AExpr, mtype: nullable MType): RuntimeVariable
	do
		var old = self.current_node
		self.current_node = nexpr

		var res = null
		if nexpr.mtype != null then
			res = nexpr.expr(self)
		end

		if res == null then
			# Untyped expression.
			# Might mean dead code or invalid code.
			# so aborts
			add_abort("FATAL: bad expression executed.")
			# and return a placebo result to please the C compiler
			if mtype == null then mtype = compiler.mainmodule.object_type
			res = new_var(mtype)

			self.current_node = old
			return res
		end

		if mtype != null then
			mtype = self.anchor(mtype)
			res = self.autobox(res, mtype)
		end
		res = autoadapt(res, nexpr.mtype.as(not null))
		var implicit_cast_to = nexpr.implicit_cast_to
		if implicit_cast_to != null and not self.compiler.modelbuilder.toolcontext.opt_no_check_autocast.value then
			add_cast(res, implicit_cast_to, "auto")
			res = autoadapt(res, implicit_cast_to)
		end
		self.current_node = old
		return res
	end

	# Alias for `self.expr(nexpr, self.bool_type)`
	fun expr_bool(nexpr: AExpr): RuntimeVariable do return expr(nexpr, bool_type)

	# Safely show a debug message on the current node and repeat the message in the C code as a comment
	fun debug(message: String)
	do
		var node = self.current_node
		if node == null then
			print "?: {message}"
		else
			node.debug(message)
		end
		self.add("/* DEBUG: {message} */")
	end
end

# A C function associated to a Nit method
# This is the base class for all runtime representation of a nit method.
# It implements the Template Design Pattern whose steps are :
#       1. create the receiver `RuntimeVariable` (selfvar)
#       2. create a `StaticFrame`
#       3. resolve the return type.
#       4. write the function signature
#       5. Declare the function signature (for C header files)
#       6. writer the function body
#       7. post-compiler hook (optional)
# Each step is called in `AbstractRuntimeFunction::compile_to_c`. A default
# body is provided foreach step except for compilation hooks. Subclasses may
# redefine any of the above mentioned steps. However, it's not recommanded
# to override `compile_to_c` since there's an ordering of the compilation steps.
# Any information between steps must be saved in the visitor. Currently most
# of the future runtime info are stored in the `StaticFrame` of the visitor,
# e.g. the receiver (selfvar), the arguments, etc.
#
# Moreover, any subclass may redefine : the receiver type, the return type and
# the signature. This allow for a better customization for the final implementation.
# Because of customization, a given Nit method can be compile more that once.
abstract class AbstractRuntimeFunction

	type COMPILER: AbstractCompiler
	type VISITOR: AbstractCompilerVisitor

	# The associated Nit method
	var mmethoddef: MMethodDef

	protected var return_mtype: nullable MType = null

	# The mangled c name of the runtime_function
	# Subclasses should redefine `build_c_name` instead
	fun c_name: String
	do
		var res = self.c_name_cache
		if res != null then return res
		res = self.build_c_name
		self.c_name_cache = res
		return res
	end

	fun c_ref: String do return "&{c_name}"

	# Non cached version of `c_name`
	protected fun build_c_name: String is abstract

	protected var c_name_cache: nullable String = null is writable

	# Implements a call of the runtime_function
	# May inline the body or generate a C function call
	fun call(v: VISITOR, arguments: Array[RuntimeVariable]): nullable RuntimeVariable is abstract

	# Returns `true` if the associated `mmethoddef`'s return type isn't null,
	# otherwise `false`.
	fun has_return: Bool
	do
		return mmethoddef.msignature.return_mtype != null
	end

	# The current msignature to use when compiling : `signature_to_c` and `body_to_c`.
	# This method is useful since most concrete implementation doesn't use the
	# mmethoddef's signature. By providing a definition in the abstract class,
	# subclasses can use any msignature.
	fun msignature: MSignature
	do
		return mmethoddef.msignature.as(not null)
	end

	# The current receiver type to compile : `signature_to_c` and `body_to_c`.
	# See `msignature` method for more information.
	protected fun recv_mtype: MType
	do
		return mmethoddef.mclassdef.bound_mtype
	end

	# Prepare the `self` runtime variable to be used by the rest of
	# compilation steps.
	# Step 1
	protected fun resolve_receiver(v: VISITOR): RuntimeVariable
	do
		var casttype = mmethoddef.mclassdef.bound_mtype
		return new RuntimeVariable("self", recv_mtype, casttype)
	end

	# Builds the static frame for current runtime method
	# Step 2
	protected fun build_frame(v: VISITOR, arguments: Array[RuntimeVariable]): StaticFrame
	do
		return new StaticFrame(v, mmethoddef, recv_mtype.as(MClassType), arguments)
	end

	# Step 3 : Returns the return type used by the runtime function.
	protected fun resolve_return_mtype(v: VISITOR)
	do
		return_mtype = msignature.return_mtype
	end

	# Fills the argument array inside v.frame.arguments, calling `resolve_ith_parameter`
	# for each parameter.
	private fun fill_parameters(v: VISITOR)
	do
		assert v.frame != null
		for i in [0..msignature.arity[ do
			var arg = resolve_ith_parameter(v, i)
			v.frame.arguments.add(arg)
		end
	end

	# Step 4 : Creates `RuntimeVariable` for each method argument.
	protected fun resolve_ith_parameter(v: VISITOR, i: Int): RuntimeVariable
	do
		var mp = msignature.mparameters[i]
		var mtype = mp.mtype
		if mp.is_vararg then
			mtype = v.mmodule.array_type(mtype)
		end
		return new RuntimeVariable("p{i}", mtype, mtype)
	end

	# Generate the code for the signature with an open curly brace
	#
	# Returns the generated signature without a semicolon and curly brace,
	# e.g `RES f(T0 p0, T1 p1, ..., TN pN)`
	# Step 5
	protected fun signature_to_c(v: VISITOR): String
	do
		assert v.frame != null
		var arguments = v.frame.arguments
		var comment = new FlatBuffer
		var selfvar = v.frame.selfvar
		var c_ret = "void"
		if has_return then
			c_ret = "{return_mtype.ctype}"
		end
		var sig = new FlatBuffer
		sig.append("{c_ret} {c_name}({recv_mtype.ctype} self")
		comment.append("({selfvar}: {selfvar.mtype}")

		for i in [0..arguments.length-1[ do
			# Skip the receiver
			var arg = arguments[i+1]
			comment.append(", {arg.mtype}")
			sig.append(", {arg.mtype.ctype} p{i}")
		end
		sig.append(")")
		comment.append(")")
		if has_return then
			comment.append(": {return_mtype.as(not null)}")
		end
		v.add_decl("/* method {self} for {comment} */")
		v.add_decl("{sig} \{")
		return sig.to_s
	end

	# How the concrete compiler will declare the method, e.g inside a global header file,
	# extern signature, etc.
	# Step 6
	protected fun declare_signature(v: VISITOR, signature: String) is abstract

	# Generate the code for the body without return statement at the end and
	# no curly brace.
	# Step 7
	protected fun body_to_c(v: VISITOR)
	do
		mmethoddef.compile_inside_to_c(v, v.frame.arguments)
	end

	# Hook called at the end of `compile_to_c` function. This function
	# is useful if you need to register any function compiled to c.
	# Step 8 (optional).
	protected fun end_compile_to_c(v: VISITOR)
	do
		# Nothing to do by default
	end

	# Generate the code
	fun compile_to_c(compiler: COMPILER)
	do
		var v = compiler.new_visitor
		var selfvar = resolve_receiver(v)
		var arguments = [selfvar]
		var frame = build_frame(v, arguments)
		v.frame = frame

		resolve_return_mtype(v)
		fill_parameters(v)

		# WARNING: the signature must be declared before creating
		# any returnlabel and returnvar (`StaticFrame`). Otherwise,
		# you could end up with variable outside the function.
		var sig = signature_to_c(v)
		declare_signature(v, sig)

		frame.returnlabel = v.get_name("RET_LABEL")
		if has_return then
			var ret_mtype = return_mtype
			assert ret_mtype != null
			frame.returnvar = v.new_var(ret_mtype)
		end

		body_to_c(v)
		v.add("{frame.returnlabel.as(not null)}:;")
		if has_return then
			v.add("return {frame.returnvar.as(not null)};")
		end
		v.add "\}"
		end_compile_to_c(v)
	end
end

# Base class for all thunk-like function. A thunk is a function whose purpose
# is to call another function. Like a class wrapper or decorator, a thunk is used
# to computer things (conversions, log, etc) before or after a function call. It's
# an intermediary between the caller and the callee.
#
# The most basic use of a thunk is to unbox its argument before invoking the real callee.
# Virtual functions are a use case of thunk function:
#
# ~~~~nitish
# redef class Object
#       fun toto(x: Int): Int do return 1 + x
# end
# redef class Int
#       redef fun toto(x) do return x + self
# end
#
# ```generated C code
# long Object__toto(val* self, long x) { return 1 + x }
# long Int__toto(long self, long x) { return x + self }
# long THUNK_Int__toto(val* self, long x) {
#       long self2 = (long)(self)>>2    // Unboxing from Object to Int
#       return Int_toto(self2, x)
# }
#
# ```
# ~~~~
#
# A thunk has its OWN SIGNATURE and is considered like any other `AbstractRuntimeFunction`.
# Thus, one might need to be careful when overriding parent's method. Since most usage of
# thunks in Nit is to unbox and box things between a caller and a callee, the default
# implementation is doing just that. In other words, a thunk takes a signature and a method
# and tries to cast its signature to the underlying method's signature.
#
# A virtual function has the same signature as its `mmethoddef` field, except for
# its receiver is of type `Object`.
# In the same vibe, a call reference has all of its argument boxed as `Object`.
abstract class ThunkFunction
	super AbstractRuntimeFunction

	# Determines if the callsite should be polymorphic or static.
	var polymorph_call_flag = false is writable

	# The type expected by the callee. Used to resolve `mmethoddef`'s formal
	# parameters and virtual type. This type must NOT need anchor.
	fun target_recv: MType is abstract

	redef fun body_to_c(v)
	do
		assert not target_recv.need_anchor
		var frame = v.frame
		assert frame != null
		var selfvar = frame.selfvar
		var arguments = frame.arguments
		var arguments2 = new Array[RuntimeVariable]
		arguments2.push(v.autobox(selfvar, target_recv))
		var resolved_sig = msignature.resolve_for(target_recv, target_recv.as(MClassType), v.mmodule, true)
		for i in [0..resolved_sig.arity[ do
		var param = resolved_sig.mparameters[i]
			var mtype = param.mtype
			if param.is_vararg then
				mtype = v.mmodule.array_type(mtype)
			end
			var temp = v.autobox(arguments[i+1], mtype)
			arguments2.push(temp)
		end
		v.add("/* {mmethoddef}, {recv_mtype.ctype} */")
		var subret: nullable RuntimeVariable = null
		if polymorph_call_flag then
			subret = v.send(mmethoddef.mproperty, arguments2)
		else
			subret = v.call(mmethoddef, arguments2[0].mcasttype.as(MClassType), arguments2)
		end
		if has_return then
			assert subret != null
			var subret2 = v.autobox(subret, return_mtype.as(not null))
			v.assign(frame.returnvar.as(not null), subret2)
		end

	end

end

# A runtime variable hold a runtime value in C.
# Runtime variables are associated to Nit local variables and intermediate results in Nit expressions.
#
# The tricky point is that a single C variable can be associated to more than one `RuntimeVariable` because the static knowledge of the type of an expression can vary in the C code.
class RuntimeVariable
	# The name of the variable in the C code
	var name: String

	# The static type of the variable (as declard in C)
	var mtype: MType

	# The current casted type of the variable (as known in Nit)
	var mcasttype: MType is writable

	# If the variable exaclty a mcasttype?
	# false (usual value) means that the variable is a mcasttype or a subtype.
	var is_exact: Bool = false is writable

	init
	do
		assert not mtype.need_anchor
		assert not mcasttype.need_anchor
	end

	redef fun to_s do return name

	redef fun inspect
	do
		var exact_str
		if self.is_exact then
			exact_str = " exact"
		else
			exact_str = ""
		end
		var type_str
		if self.mtype == self.mcasttype then
			type_str = "{mtype}{exact_str}"
		else
			type_str = "{mtype}({mcasttype}{exact_str})"
		end
		return "<{name}:{type_str}>"
	end
end

# The static context of a visited property in a `AbstractCompilerVisitor`
class StaticFrame

	type VISITOR: AbstractCompilerVisitor

	# The associated visitor
	var visitor: VISITOR

	# The executed property.
	# A Method in case of a call, an attribute in case of a default initialization.
	var mpropdef: MPropDef

	# The static type of the receiver
	var receiver: MClassType

	# Arguments of the method (the first is the receiver)
	var arguments: Array[RuntimeVariable]

	# The runtime_variable associated to the return (in a function)
	var returnvar: nullable RuntimeVariable = null is writable

	# The label at the end of the property
	var returnlabel: nullable String = null is writable

	# Labels associated to a each escapemarks.
	# Because of inlinings, escape-marks must be associated to their context (the frame)
	private var escapemark_names = new HashMap[EscapeMark, String]

	# The array comprehension currently filled, if any
	private var comprehension: nullable RuntimeVariable = null

	# Returns the first argument (the receiver) of a frame.
	# REQUIRE: arguments.length >= 1
	fun selfvar: RuntimeVariable
	do
		assert arguments.length >= 1
		return arguments.first
	end
end

redef class MType
	# Return the C type associated to a given Nit static type
	fun ctype: String do return "val*"

	# C type outside of the compiler code and in boxes
	fun ctype_extern: String do return "val*"

	# Short name of the `ctype` to use in unions
	fun ctypename: String do return "val"

	# Is the associated C type a primitive one?
	#
	# ENSURE `result == (ctype != "val*")`
	fun is_c_primitive: Bool do return false
end

redef class MClassType

	redef var ctype is lazy do
		if mclass.name == "Int" then
			return "long"
		else if mclass.name == "Bool" then
			return "short int"
		else if mclass.name == "Char" then
			return "uint32_t"
		else if mclass.name == "Float" then
			return "double"
		else if mclass.name == "Int8" then
			return "int8_t"
		else if mclass.name == "Byte" then
			return "unsigned char"
		else if mclass.name == "Int16" then
			return "int16_t"
		else if mclass.name == "UInt16" then
			return "uint16_t"
		else if mclass.name == "Int32" then
			return "int32_t"
		else if mclass.name == "UInt32" then
			return "uint32_t"
		else if mclass.name == "CString" then
			return "char*"
		else if mclass.name == "NativeArray" then
			return "val*"
		else
			return "val*"
		end
	end

	redef var is_c_primitive is lazy do return ctype != "val*"

	redef fun ctype_extern: String
	do
		if mclass.kind == extern_kind then
			return "void*"
		else
			return ctype
		end
	end

	redef fun ctypename: String
	do
		if mclass.name == "Int" then
			return "l"
		else if mclass.name == "Bool" then
			return "s"
		else if mclass.name == "Char" then
			return "c"
		else if mclass.name == "Float" then
			return "d"
		else if mclass.name == "Int8" then
			return "i8"
		else if mclass.name == "Byte" then
			return "b"
		else if mclass.name == "Int16" then
			return "i16"
		else if mclass.name == "UInt16" then
			return "u16"
		else if mclass.name == "Int32" then
			return "i32"
		else if mclass.name == "UInt32" then
			return "u32"
		else if mclass.name == "CString" then
			return "str"
		else if mclass.name == "NativeArray" then
			#return "{self.arguments.first.ctype}*"
			return "val"
		else
			return "val"
		end
	end
end

redef class MPropDef
	type VISITOR: AbstractCompilerVisitor
end

redef class MMethodDef
	# Can the body be inlined?
	fun can_inline(v: VISITOR): Bool
	do
		if is_abstract then return true
		if constant_value != null then return true
		var modelbuilder = v.compiler.modelbuilder
		var node = modelbuilder.mpropdef2node(self)
		if node isa APropdef then
			return node.can_inline
		else if node isa AClassdef then
			# Automatic free init is always inlined since it is empty or contains only attribtes assigments
			return true
		else if node == null then
			return true
		else
			abort
		end
	end

	# Inline the body in another visitor
	fun compile_inside_to_c(v: VISITOR, arguments: Array[RuntimeVariable]): nullable RuntimeVariable
	do
		var modelbuilder = v.compiler.modelbuilder
		var val = constant_value
		var node = modelbuilder.mpropdef2node(self)

		if is_abstract then
			v.add_raw_throw
			var cn = v.class_name_string(arguments.first)
			v.current_node = node
			v.add("PRINT_ERROR(\"Runtime error: Abstract method `%s` called on `%s`\", \"{mproperty.name.escape_to_c}\", {cn});")
			v.add_raw_abort
			return null
		end

		if node isa APropdef then
			var oldnode = v.current_node
			v.current_node = node
			self.compile_parameter_check(v, arguments)
			node.compile_to_c(v, self, arguments)
			v.current_node = oldnode
		else if node isa AClassdef then
			var oldnode = v.current_node
			v.current_node = node
			self.compile_parameter_check(v, arguments)
			node.compile_to_c(v, self, arguments)
			v.current_node = oldnode
		else if val != null then
			v.ret(v.value_instance(val))
		else
			abort
		end
		return null
	end

	# Generate type checks in the C code to check covariant parameters
	fun compile_parameter_check(v: VISITOR, arguments: Array[RuntimeVariable])
	do
		if v.compiler.modelbuilder.toolcontext.opt_no_check_covariance.value then return

		var msignature = self.msignature.as(not null)

		for i in [0..msignature.arity[ do
			var mp = msignature.mparameters[i]
			# skip test for vararg since the array is instantiated with the correct polymorphic type
			if mp.is_vararg then continue

			# skip if the cast is not required
			var origmtype =  self.mproperty.intro.msignature.mparameters[i].mtype
			if not origmtype.need_anchor then continue

			# get the parameter type
			var mtype = mp.mtype

			# generate the cast
			# note that v decides if and how to implements the cast
			v.add("/* Covariant cast for argument {i} ({mp.name}) {arguments[i+1].inspect} isa {mtype} */")
			v.add_cast(arguments[i+1], mtype, "covariance")
		end
	end
end

# Node visit

redef class APropdef
	fun compile_to_c(v: AbstractCompilerVisitor, mpropdef: MMethodDef, arguments: Array[RuntimeVariable])
	do
		v.add("PRINT_ERROR(\"NOT YET IMPLEMENTED {class_name} {mpropdef} at {location.to_s}\\n\");")
		debug("Not yet implemented")
	end

	fun can_inline: Bool do return true
end

redef class AMethPropdef
	redef fun compile_to_c(v, mpropdef, arguments)
	do
		# Call the implicit super-init
		var auto_super_inits = self.auto_super_inits
		if auto_super_inits != null then
			var args = [arguments.first]
			for auto_super_init in auto_super_inits do
				assert auto_super_init.mproperty != mpropdef.mproperty
				args.clear
				for i in [0..auto_super_init.msignature.arity+1[ do
					args.add(arguments[i])
				end
				assert auto_super_init.mproperty != mpropdef.mproperty
				v.compile_callsite(auto_super_init, args)
			end
		end
		if auto_super_call then
			v.supercall(mpropdef, arguments.first.mtype.as(MClassType), arguments)
		end

		# Try special compilation
		if mpropdef.is_intern then
			if compile_intern_to_c(v, mpropdef, arguments) then return
		end
		if mpropdef.is_extern then
			if mpropdef.mproperty.is_init then
				if compile_externinit_to_c(v, mpropdef, arguments) then return
			else
				if compile_externmeth_to_c(v, mpropdef, arguments) then return
			end
		end

		# Compile block if any
		var n_block = n_block
		if n_block != null then
			for i in [0..mpropdef.msignature.arity[ do
				var variable = self.n_signature.n_params[i].variable.as(not null)
				v.assign(v.variable(variable), arguments[i+1])
			end
			v.stmt(n_block)
			return
		end

		# We have a problem
		v.add_raw_throw
		var cn = v.class_name_string(arguments.first)
		v.add("PRINT_ERROR(\"Runtime error: uncompiled method `%s` called on `%s`. NOT YET IMPLEMENTED\", \"{mpropdef.mproperty.name.escape_to_c}\", {cn});")
		v.add_raw_abort
	end

	redef fun can_inline
	do
		if self.auto_super_inits != null then return false
		var nblock = self.n_block
		if nblock == null then return true
		if (mpropdef.mproperty.name == "==" or mpropdef.mproperty.name == "!=") and mpropdef.mclassdef.mclass.name == "Object" then return true
		if nblock isa ABlockExpr and nblock.n_expr.length == 0 then return true
		return false
	end

	fun compile_intern_to_c(v: AbstractCompilerVisitor, mpropdef: MMethodDef, arguments: Array[RuntimeVariable]): Bool
	do
		var pname = mpropdef.mproperty.name
		var cname = mpropdef.mclassdef.mclass.name
		var ret = mpropdef.msignature.return_mtype
		var compiler = v.compiler

		# WARNING: we must not resolve the return type when it's a functional type.
		# Otherwise, we get a compile error exactly here. Moreover, `routine_ref_call`
		# already handles the return type. NOTE: this warning only apply when compiling
		# in `semi-global`.
		if ret != null and not compiler.all_routine_types_name.has(cname) then
			ret = v.resolve_for(ret, arguments.first)
		end

		if pname != "==" and pname != "!=" then
			v.adapt_signature(mpropdef, arguments)
			v.unbox_signature_extern(mpropdef, arguments)
		end
		if cname == "Int" then
			if pname == "output" then
				v.add("printf(\"%ld\\n\", {arguments.first});")
				return true
			else if pname == "object_id" then
				v.ret(arguments.first)
				return true
			else if pname == "+" then
				v.ret(v.new_expr("{arguments[0]} + {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "-" then
				v.ret(v.new_expr("{arguments[0]} - {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "unary -" then
				v.ret(v.new_expr("-{arguments[0]}", ret.as(not null)))
				return true
			else if pname == "unary +" then
				v.ret(arguments[0])
				return true
			else if pname == "*" then
				v.ret(v.new_expr("{arguments[0]} * {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "/" then
				v.ret(v.new_expr("{arguments[0]} / {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "%" then
				v.ret(v.new_expr("{arguments[0]} % {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "==" then
				v.ret(v.equal_test(arguments[0], arguments[1]))
				return true
			else if pname == "!=" then
				var res = v.equal_test(arguments[0], arguments[1])
				v.ret(v.new_expr("!{res}", ret.as(not null)))
				return true
			else if pname == "<" then
				v.ret(v.new_expr("{arguments[0]} < {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">" then
				v.ret(v.new_expr("{arguments[0]} > {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "<=" then
				v.ret(v.new_expr("{arguments[0]} <= {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">=" then
				v.ret(v.new_expr("{arguments[0]} >= {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "to_i8" then
				v.ret(v.new_expr("(int8_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_i16" then
				v.ret(v.new_expr("(int16_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_u16" then
				v.ret(v.new_expr("(uint16_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_i32" then
				v.ret(v.new_expr("(int32_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_u32" then
				v.ret(v.new_expr("(uint32_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_f" then
				v.ret(v.new_expr("(double){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_b" then
				v.ret(v.new_expr("(unsigned char){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "code_point" then
				v.ret(v.new_expr("(uint32_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "&" then
				v.ret(v.new_expr("{arguments[0]} & {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "|" then
				v.ret(v.new_expr("{arguments[0]} | {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">>" then
				v.ret(v.new_expr("{arguments[0]} >> {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "<<" then
				v.ret(v.new_expr("{arguments[0]} << {arguments[1]}", ret.as(not null)))
				return true
			end
		else if cname == "Char" then
			if pname == "object_id" then
				v.ret(v.new_expr("(long){arguments.first}", ret.as(not null)))
				return true
			else if pname == "successor" then
				v.ret(v.new_expr("{arguments[0]} + {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "predecessor" then
				v.ret(v.new_expr("{arguments[0]} - {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "==" then
				v.ret(v.equal_test(arguments[0], arguments[1]))
				return true
			else if pname == "!=" then
				var res = v.equal_test(arguments[0], arguments[1])
				v.ret(v.new_expr("!{res}", ret.as(not null)))
				return true
			else if pname == "<" then
				v.ret(v.new_expr("{arguments[0]} < {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">" then
				v.ret(v.new_expr("{arguments[0]} > {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "<=" then
				v.ret(v.new_expr("{arguments[0]} <= {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">=" then
				v.ret(v.new_expr("{arguments[0]} >= {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "to_i" then
				v.ret(v.new_expr("{arguments[0]}-'0'", ret.as(not null)))
				return true
			else if pname == "code_point" then
				v.ret(v.new_expr("(long){arguments[0]}", ret.as(not null)))
				return true
			end
		else if cname == "Byte" then
			if pname == "output" then
				v.add("printf(\"%x\\n\", {arguments.first});")
				return true
			else if pname == "object_id" then
				v.ret(v.new_expr("(long){arguments.first}", ret.as(not null)))
				return true
			else if pname == "+" then
				v.ret(v.new_expr("{arguments[0]} + {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "-" then
				v.ret(v.new_expr("{arguments[0]} - {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "unary -" then
				v.ret(v.new_expr("-{arguments[0]}", ret.as(not null)))
				return true
			else if pname == "unary +" then
				v.ret(arguments[0])
				return true
			else if pname == "*" then
				v.ret(v.new_expr("{arguments[0]} * {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "/" then
				v.ret(v.new_expr("{arguments[0]} / {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "%" then
				v.ret(v.new_expr("{arguments[0]} % {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "==" then
				v.ret(v.equal_test(arguments[0], arguments[1]))
				return true
			else if pname == "!=" then
				var res = v.equal_test(arguments[0], arguments[1])
				v.ret(v.new_expr("!{res}", ret.as(not null)))
				return true
			else if pname == "<" then
				v.ret(v.new_expr("{arguments[0]} < {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">" then
				v.ret(v.new_expr("{arguments[0]} > {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "<=" then
				v.ret(v.new_expr("{arguments[0]} <= {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">=" then
				v.ret(v.new_expr("{arguments[0]} >= {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">>" then
				v.ret(v.new_expr("{arguments[0]} >> {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "<<" then
				v.ret(v.new_expr("{arguments[0]} << {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "&" then
				v.ret(v.new_expr("{arguments[0]} & {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "to_i" then
				v.ret(v.new_expr("(long){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_f" then
				v.ret(v.new_expr("(double){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_i8" then
				v.ret(v.new_expr("(int8_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_i16" then
				v.ret(v.new_expr("(int16_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_u16" then
				v.ret(v.new_expr("(uint16_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_i32" then
				v.ret(v.new_expr("(int32_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_u32" then
				v.ret(v.new_expr("(uint32_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "ascii" then
				v.ret(v.new_expr("(uint32_t){arguments[0]}", ret.as(not null)))
				return true
			end
		else if cname == "Bool" then
			if pname == "output" then
				v.add("printf({arguments.first}?\"true\\n\":\"false\\n\");")
				return true
			else if pname == "object_id" then
				v.ret(v.new_expr("(long){arguments.first}", ret.as(not null)))
				return true
			else if pname == "==" then
				v.ret(v.equal_test(arguments[0], arguments[1]))
				return true
			else if pname == "!=" then
				var res = v.equal_test(arguments[0], arguments[1])
				v.ret(v.new_expr("!{res}", ret.as(not null)))
				return true
			end
		else if cname == "Float" then
			if pname == "output" then
				v.add("printf(\"%f\\n\", {arguments.first});")
				return true
			else if pname == "object_id" then
				v.ret(v.new_expr("(double){arguments.first}", ret.as(not null)))
				return true
			else if pname == "+" then
				v.ret(v.new_expr("{arguments[0]} + {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "-" then
				v.ret(v.new_expr("{arguments[0]} - {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "unary -" then
				v.ret(v.new_expr("-{arguments[0]}", ret.as(not null)))
				return true
			else if pname == "unary +" then
				v.ret(arguments[0])
				return true
			else if pname == "succ" then
				v.ret(v.new_expr("{arguments[0]}+1", ret.as(not null)))
				return true
			else if pname == "prec" then
				v.ret(v.new_expr("{arguments[0]}-1", ret.as(not null)))
				return true
			else if pname == "*" then
				v.ret(v.new_expr("{arguments[0]} * {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "/" then
				v.ret(v.new_expr("{arguments[0]} / {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "==" then
				v.ret(v.equal_test(arguments[0], arguments[1]))
				return true
			else if pname == "!=" then
				var res = v.equal_test(arguments[0], arguments[1])
				v.ret(v.new_expr("!{res}", ret.as(not null)))
				return true
			else if pname == "<" then
				v.ret(v.new_expr("{arguments[0]} < {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">" then
				v.ret(v.new_expr("{arguments[0]} > {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "<=" then
				v.ret(v.new_expr("{arguments[0]} <= {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">=" then
				v.ret(v.new_expr("{arguments[0]} >= {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "to_i" then
				v.ret(v.new_expr("(long){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_b" then
				v.ret(v.new_expr("(unsigned char){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_i8" then
				v.ret(v.new_expr("(int8_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_i16" then
				v.ret(v.new_expr("(int16_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_u16" then
				v.ret(v.new_expr("(uint16_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_i32" then
				v.ret(v.new_expr("(int32_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_u32" then
				v.ret(v.new_expr("(uint32_t){arguments[0]}", ret.as(not null)))
				return true
			end
		else if cname == "CString" then
			if pname == "[]" then
				v.ret(v.new_expr("(unsigned char)((int){arguments[0]}[{arguments[1]}])", ret.as(not null)))
				return true
			else if pname == "[]=" then
				v.add("{arguments[0]}[{arguments[1]}]=(unsigned char){arguments[2]};")
				return true
			else if pname == "copy_to" then
				v.add("memmove({arguments[1]}+{arguments[4]},{arguments[0]}+{arguments[3]},{arguments[2]});")
				return true
			else if pname == "atoi" then
				v.ret(v.new_expr("atoi({arguments[0]});", ret.as(not null)))
				return true
			else if pname == "fast_cstring" then
				v.ret(v.new_expr("{arguments[0]} + {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "==" then
				v.ret(v.equal_test(arguments[0], arguments[1]))
				return true
			else if pname == "!=" then
				var res = v.equal_test(arguments[0], arguments[1])
				v.ret(v.new_expr("!{res}", ret.as(not null)))
				return true
			else if pname == "new" then
				var alloc = v.nit_alloc(arguments[1].to_s, "CString")
				v.ret(v.new_expr("(char*){alloc}", ret.as(not null)))
				return true
			else if pname == "fetch_4_chars" then
				v.ret(v.new_expr("*((uint32_t*)({arguments[0]} + {arguments[1]}))", ret.as(not null)))
				return true
			else if pname == "fetch_4_hchars" then
				v.ret(v.new_expr("(uint32_t)be32toh(*((uint32_t*)({arguments[0]} + {arguments[1]})))", ret.as(not null)))
				return true
			end
		else if cname == "NativeArray" then
			return v.native_array_def(pname, ret, arguments)
		else if cname == "Int8" then
			if pname == "output" then
				v.add("printf(\"%\"PRIi8 \"\\n\", {arguments.first});")
				return true
			else if pname == "object_id" then
				v.ret(v.new_expr("(long){arguments.first}", ret.as(not null)))
				return true
			else if pname == "+" then
				v.ret(v.new_expr("{arguments[0]} + {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "-" then
				v.ret(v.new_expr("{arguments[0]} - {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "unary -" then
				v.ret(v.new_expr("-{arguments[0]}", ret.as(not null)))
				return true
			else if pname == "unary +" then
				v.ret(arguments[0])
				return true
			else if pname == "*" then
				v.ret(v.new_expr("{arguments[0]} * {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "/" then
				v.ret(v.new_expr("{arguments[0]} / {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "%" then
				v.ret(v.new_expr("{arguments[0]} % {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "<<" then
				v.ret(v.new_expr("{arguments[0]} << {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">>" then
				v.ret(v.new_expr("{arguments[0]} >> {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "==" then
				v.ret(v.equal_test(arguments[0], arguments[1]))
				return true
			else if pname == "!=" then
				var res = v.equal_test(arguments[0], arguments[1])
				v.ret(v.new_expr("!{res}", ret.as(not null)))
				return true
			else if pname == "<" then
				v.ret(v.new_expr("{arguments[0]} < {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">" then
				v.ret(v.new_expr("{arguments[0]} > {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "<=" then
				v.ret(v.new_expr("{arguments[0]} <= {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">=" then
				v.ret(v.new_expr("{arguments[0]} >= {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "to_i" then
				v.ret(v.new_expr("(long){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_b" then
				v.ret(v.new_expr("(unsigned char){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_i16" then
				v.ret(v.new_expr("(int16_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_u16" then
				v.ret(v.new_expr("(uint16_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_i32" then
				v.ret(v.new_expr("(int32_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_u32" then
				v.ret(v.new_expr("(uint32_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_f" then
				v.ret(v.new_expr("(double){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "&" then
				v.ret(v.new_expr("{arguments[0]} & {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "|" then
				v.ret(v.new_expr("{arguments[0]} | {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "^" then
				v.ret(v.new_expr("{arguments[0]} ^ {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "unary ~" then
				v.ret(v.new_expr("~{arguments[0]}", ret.as(not null)))
				return true
			end
		else if cname == "Int16" then
			if pname == "output" then
				v.add("printf(\"%\"PRIi16 \"\\n\", {arguments.first});")
				return true
			else if pname == "object_id" then
				v.ret(v.new_expr("(long){arguments.first}", ret.as(not null)))
				return true
			else if pname == "+" then
				v.ret(v.new_expr("{arguments[0]} + {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "-" then
				v.ret(v.new_expr("{arguments[0]} - {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "unary -" then
				v.ret(v.new_expr("-{arguments[0]}", ret.as(not null)))
				return true
			else if pname == "unary +" then
				v.ret(arguments[0])
				return true
			else if pname == "*" then
				v.ret(v.new_expr("{arguments[0]} * {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "/" then
				v.ret(v.new_expr("{arguments[0]} / {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "%" then
				v.ret(v.new_expr("{arguments[0]} % {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "<<" then
				v.ret(v.new_expr("{arguments[0]} << {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">>" then
				v.ret(v.new_expr("{arguments[0]} >> {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "==" then
				v.ret(v.equal_test(arguments[0], arguments[1]))
				return true
			else if pname == "!=" then
				var res = v.equal_test(arguments[0], arguments[1])
				v.ret(v.new_expr("!{res}", ret.as(not null)))
				return true
			else if pname == "<" then
				v.ret(v.new_expr("{arguments[0]} < {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">" then
				v.ret(v.new_expr("{arguments[0]} > {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "<=" then
				v.ret(v.new_expr("{arguments[0]} <= {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">=" then
				v.ret(v.new_expr("{arguments[0]} >= {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "to_i" then
				v.ret(v.new_expr("(long){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_b" then
				v.ret(v.new_expr("(unsigned char){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_i8" then
				v.ret(v.new_expr("(int8_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_u16" then
				v.ret(v.new_expr("(uint16_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_i32" then
				v.ret(v.new_expr("(int32_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_u32" then
				v.ret(v.new_expr("(uint32_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_f" then
				v.ret(v.new_expr("(double){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "&" then
				v.ret(v.new_expr("{arguments[0]} & {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "|" then
				v.ret(v.new_expr("{arguments[0]} | {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "^" then
				v.ret(v.new_expr("{arguments[0]} ^ {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "unary ~" then
				v.ret(v.new_expr("~{arguments[0]}", ret.as(not null)))
				return true
			end
		else if cname == "UInt16" then
			if pname == "output" then
				v.add("printf(\"%\"PRIu16 \"\\n\", {arguments.first});")
				return true
			else if pname == "object_id" then
				v.ret(v.new_expr("(long){arguments.first}", ret.as(not null)))
				return true
			else if pname == "+" then
				v.ret(v.new_expr("{arguments[0]} + {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "-" then
				v.ret(v.new_expr("{arguments[0]} - {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "unary -" then
				v.ret(v.new_expr("-{arguments[0]}", ret.as(not null)))
				return true
			else if pname == "unary +" then
				v.ret(arguments[0])
				return true
			else if pname == "*" then
				v.ret(v.new_expr("{arguments[0]} * {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "/" then
				v.ret(v.new_expr("{arguments[0]} / {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "%" then
				v.ret(v.new_expr("{arguments[0]} % {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "<<" then
				v.ret(v.new_expr("{arguments[0]} << {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">>" then
				v.ret(v.new_expr("{arguments[0]} >> {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "==" then
				v.ret(v.equal_test(arguments[0], arguments[1]))
				return true
			else if pname == "!=" then
				var res = v.equal_test(arguments[0], arguments[1])
				v.ret(v.new_expr("!{res}", ret.as(not null)))
				return true
			else if pname == "<" then
				v.ret(v.new_expr("{arguments[0]} < {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">" then
				v.ret(v.new_expr("{arguments[0]} > {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "<=" then
				v.ret(v.new_expr("{arguments[0]} <= {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">=" then
				v.ret(v.new_expr("{arguments[0]} >= {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "to_i" then
				v.ret(v.new_expr("(long){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_b" then
				v.ret(v.new_expr("(unsigned char){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_i8" then
				v.ret(v.new_expr("(int8_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_i16" then
				v.ret(v.new_expr("(int16_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_i32" then
				v.ret(v.new_expr("(int32_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_u32" then
				v.ret(v.new_expr("(uint32_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_f" then
				v.ret(v.new_expr("(double){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "&" then
				v.ret(v.new_expr("{arguments[0]} & {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "|" then
				v.ret(v.new_expr("{arguments[0]} | {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "^" then
				v.ret(v.new_expr("{arguments[0]} ^ {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "unary ~" then
				v.ret(v.new_expr("~{arguments[0]}", ret.as(not null)))
				return true
			end
		else if cname == "Int32" then
			if pname == "output" then
				v.add("printf(\"%\"PRIi32 \"\\n\", {arguments.first});")
				return true
			else if pname == "object_id" then
				v.ret(v.new_expr("(long){arguments.first}", ret.as(not null)))
				return true
			else if pname == "+" then
				v.ret(v.new_expr("{arguments[0]} + {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "-" then
				v.ret(v.new_expr("{arguments[0]} - {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "unary -" then
				v.ret(v.new_expr("-{arguments[0]}", ret.as(not null)))
				return true
			else if pname == "unary +" then
				v.ret(arguments[0])
				return true
			else if pname == "*" then
				v.ret(v.new_expr("{arguments[0]} * {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "/" then
				v.ret(v.new_expr("{arguments[0]} / {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "%" then
				v.ret(v.new_expr("{arguments[0]} % {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "<<" then
				v.ret(v.new_expr("{arguments[0]} << {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">>" then
				v.ret(v.new_expr("{arguments[0]} >> {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "==" then
				v.ret(v.equal_test(arguments[0], arguments[1]))
				return true
			else if pname == "!=" then
				var res = v.equal_test(arguments[0], arguments[1])
				v.ret(v.new_expr("!{res}", ret.as(not null)))
				return true
			else if pname == "<" then
				v.ret(v.new_expr("{arguments[0]} < {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">" then
				v.ret(v.new_expr("{arguments[0]} > {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "<=" then
				v.ret(v.new_expr("{arguments[0]} <= {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">=" then
				v.ret(v.new_expr("{arguments[0]} >= {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "to_i" then
				v.ret(v.new_expr("(long){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_b" then
				v.ret(v.new_expr("(unsigned char){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_i8" then
				v.ret(v.new_expr("(int8_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_i16" then
				v.ret(v.new_expr("(int16_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_u16" then
				v.ret(v.new_expr("(uint16_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_u32" then
				v.ret(v.new_expr("(uint32_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_f" then
				v.ret(v.new_expr("(double){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "&" then
				v.ret(v.new_expr("{arguments[0]} & {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "|" then
				v.ret(v.new_expr("{arguments[0]} | {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "^" then
				v.ret(v.new_expr("{arguments[0]} ^ {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "unary ~" then
				v.ret(v.new_expr("~{arguments[0]}", ret.as(not null)))
				return true
			end
		else if cname == "UInt32" then
			if pname == "output" then
				v.add("printf(\"%\"PRIu32 \"\\n\", {arguments.first});")
				return true
			else if pname == "object_id" then
				v.ret(v.new_expr("(long){arguments.first}", ret.as(not null)))
				return true
			else if pname == "+" then
				v.ret(v.new_expr("{arguments[0]} + {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "-" then
				v.ret(v.new_expr("{arguments[0]} - {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "unary -" then
				v.ret(v.new_expr("-{arguments[0]}", ret.as(not null)))
				return true
			else if pname == "unary +" then
				v.ret(arguments[0])
				return true
			else if pname == "*" then
				v.ret(v.new_expr("{arguments[0]} * {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "/" then
				v.ret(v.new_expr("{arguments[0]} / {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "%" then
				v.ret(v.new_expr("{arguments[0]} % {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "<<" then
				v.ret(v.new_expr("{arguments[0]} << {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">>" then
				v.ret(v.new_expr("{arguments[0]} >> {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "==" then
				v.ret(v.equal_test(arguments[0], arguments[1]))
				return true
			else if pname == "!=" then
				var res = v.equal_test(arguments[0], arguments[1])
				v.ret(v.new_expr("!{res}", ret.as(not null)))
				return true
			else if pname == "<" then
				v.ret(v.new_expr("{arguments[0]} < {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">" then
				v.ret(v.new_expr("{arguments[0]} > {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "<=" then
				v.ret(v.new_expr("{arguments[0]} <= {arguments[1]}", ret.as(not null)))
				return true
			else if pname == ">=" then
				v.ret(v.new_expr("{arguments[0]} >= {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "to_i" then
				v.ret(v.new_expr("(long){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_b" then
				v.ret(v.new_expr("(unsigned char){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_i8" then
				v.ret(v.new_expr("(int8_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_i16" then
				v.ret(v.new_expr("(int16_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_u16" then
				v.ret(v.new_expr("(uint16_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_i32" then
				v.ret(v.new_expr("(int32_t){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "to_f" then
				v.ret(v.new_expr("(double){arguments[0]}", ret.as(not null)))
				return true
			else if pname == "&" then
				v.ret(v.new_expr("{arguments[0]} & {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "|" then
				v.ret(v.new_expr("{arguments[0]} | {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "^" then
				v.ret(v.new_expr("{arguments[0]} ^ {arguments[1]}", ret.as(not null)))
				return true
			else if pname == "unary ~" then
				v.ret(v.new_expr("~{arguments[0]}", ret.as(not null)))
				return true
			end
		else if compiler.all_routine_types_name.has(cname) then
			v.routine_ref_call(mpropdef, arguments)
			return true
		end
		if pname == "exit" then
			v.add("exit((int){arguments[1]});")
			return true
		else if pname == "sys" then
			v.ret(v.new_expr("glob_sys", ret.as(not null)))
			return true
		else if pname == "object_id" then
			v.ret(v.new_expr("(long){arguments.first}", ret.as(not null)))
			return true
		else if pname == "is_same_type" then
			v.ret(v.is_same_type_test(arguments[0], arguments[1]))
			return true
		else if pname == "is_same_instance" then
			v.ret(v.equal_test(arguments[0], arguments[1]))
			return true
		else if pname == "output_class_name" then
			var nat = v.class_name_string(arguments.first)
			v.add("printf(\"%s\\n\", {nat});")
			return true
		else if pname == "native_class_name" then
			var nat = v.class_name_string(arguments.first)
			v.ret(v.new_expr("(char*){nat}", ret.as(not null)))
			return true
		else if pname == "force_garbage_collection" then
			v.add("nit_gcollect();")
			return true
		else if pname == "native_argc" then
			v.ret(v.new_expr("glob_argc", ret.as(not null)))
			return true
		else if pname == "native_argv" then
			v.ret(v.new_expr("glob_argv[{arguments[1]}]", ret.as(not null)))
			return true
		end
		return false
	end

	# Compile an extern method
	# Return `true` if the compilation was successful, `false` if a fall-back is needed
	fun compile_externmeth_to_c(v: AbstractCompilerVisitor, mpropdef: MMethodDef, arguments: Array[RuntimeVariable]): Bool
	do
		var externname
		var at = self.get_single_annotation("extern", v.compiler.modelbuilder)
		if at != null and at.n_args.length == 1 then
			externname = at.arg_as_string(v.compiler.modelbuilder)
			if externname == null then return false
		else
			return false
		end
		v.add_extern(mpropdef.mclassdef.mmodule)
		var res: nullable RuntimeVariable = null
		var ret = mpropdef.msignature.return_mtype
		if ret != null then
			ret = v.resolve_for(ret, arguments.first)
			res = v.new_var_extern(ret)
		end
		v.adapt_signature(mpropdef, arguments)
		v.unbox_signature_extern(mpropdef, arguments)

		if res == null then
			v.add("{externname}({arguments.join(", ")});")
		else
			v.add("{res} = {externname}({arguments.join(", ")});")
			res = v.box_extern(res, ret.as(not null))
			v.ret(res)
		end
		return true
	end

	# Compile an extern factory
	# Return `true` if the compilation was successful, `false` if a fall-back is needed
	fun compile_externinit_to_c(v: AbstractCompilerVisitor, mpropdef: MMethodDef, arguments: Array[RuntimeVariable]): Bool
	do
		var externname
		var at = self.get_single_annotation("extern", v.compiler.modelbuilder)
		if at != null then
			externname = at.arg_as_string(v.compiler.modelbuilder)
			if externname == null then return false
		else
			return false
		end
		v.add_extern(mpropdef.mclassdef.mmodule)
		v.adapt_signature(mpropdef, arguments)
		v.unbox_signature_extern(mpropdef, arguments)
		var ret = arguments.first.mtype
		var res = v.new_var_extern(ret)

		arguments.shift

		v.add("{res} = {externname}({arguments.join(", ")});")
		res = v.box_extern(res, ret)
		v.ret(res)
		return true
	end
end

redef class AAttrPropdef
	redef fun can_inline: Bool do return not is_lazy

	redef fun compile_to_c(v, mpropdef, arguments)
	do
		if mpropdef == mreadpropdef then
			assert arguments.length == 1
			var recv = arguments.first
			var res
			if is_lazy then
				var set
				var ret = self.mtype
				var useiset = not ret.is_c_primitive and not ret isa MNullableType
				var guard = self.mlazypropdef.mproperty
				if useiset then
					set = v.isset_attribute(self.mpropdef.mproperty, recv)
				else
					set = v.read_attribute(guard, recv)
				end
				v.add("if(likely({set})) \{")
				res = v.read_attribute(self.mpropdef.mproperty, recv)
				v.add("\} else \{")

				var value = evaluate_expr(v, recv)

				v.assign(res, value)
				if not useiset then
					var true_v = v.bool_instance(true)
					v.write_attribute(guard, arguments.first, true_v)
				end
				v.add("\}")
			else
				res = v.read_attribute(self.mpropdef.mproperty, arguments.first)
			end
			v.assign(v.frame.returnvar.as(not null), res)
		else if mpropdef == mwritepropdef then
			assert arguments.length == 2
			var recv = arguments.first
			var arg = arguments[1]
			if is_optional and v.maybe_null(arg) then
				var value = v.new_var(self.mpropdef.static_mtype.as(not null))
				v.add("if ({arg} == NULL) \{")
				v.assign(value, evaluate_expr(v, recv))
				v.add("\} else \{")
				v.assign(value, arg)
				v.add("\}")
				arg = value
			end
			v.write_attribute(self.mpropdef.mproperty, arguments.first, arg)
			if is_lazy then
				var ret = self.mtype
				var useiset = not ret.is_c_primitive and not ret isa MNullableType
				if not useiset then
					v.write_attribute(self.mlazypropdef.mproperty, arguments.first, v.bool_instance(true))
				end
			end
		else
			abort
		end
	end

	fun init_expr(v: AbstractCompilerVisitor, recv: RuntimeVariable)
	do
		if has_value and not is_lazy and not is_optional and not n_expr isa ANullExpr then evaluate_expr(v, recv)
	end

	# Evaluate, store and return the default value of the attribute
	private fun evaluate_expr(v: AbstractCompilerVisitor, recv: RuntimeVariable): RuntimeVariable
	do
		var oldnode = v.current_node
		v.current_node = self
		var old_frame = v.frame
		var frame = new StaticFrame(v, self.mreadpropdef.as(not null), recv.mcasttype.undecorate.as(MClassType), [recv])
		v.frame = frame

		var value
		var mtype = self.mtype
		assert mtype != null

		var nexpr = self.n_expr
		var nblock = self.n_block
		if nexpr != null then
			value = v.expr(nexpr, mtype)
		else if nblock != null then
			value = v.new_var(mtype)
			frame.returnvar = value
			frame.returnlabel = v.get_name("RET_LABEL")
			v.add("\{")
			v.stmt(nblock)
			v.add("{frame.returnlabel.as(not null)}:(void)0;")
			v.add("\}")
		else
			abort
		end

		v.write_attribute(self.mpropdef.mproperty, recv, value)

		v.frame = old_frame
		v.current_node = oldnode

		return value
	end

	fun check_expr(v: AbstractCompilerVisitor, recv: RuntimeVariable)
	do
		var nexpr = self.n_expr
		if nexpr != null then return

		var oldnode = v.current_node
		v.current_node = self
		var old_frame = v.frame
		var frame = new StaticFrame(v, self.mpropdef.as(not null), recv.mtype.as(MClassType), [recv])
		v.frame = frame
		# Force read to check the initialization
		v.read_attribute(self.mpropdef.mproperty, recv)
		v.frame = old_frame
		v.current_node = oldnode
	end
end

redef class AClassdef
	private fun compile_to_c(v: AbstractCompilerVisitor, mpropdef: MMethodDef, arguments: Array[RuntimeVariable])
	do
		if mpropdef.mproperty.is_root_init then
			assert arguments.length == 1
			if not mpropdef.is_intro then
				v.supercall(mpropdef, arguments.first.mtype.as(MClassType), arguments)
			end
			return
		else if mclassdef.default_init == mpropdef then
			var recv = arguments.first
			var initializers = mpropdef.initializers
			var no_init = false
			if not initializers.is_empty and not mpropdef.is_old_style_init then
				var i = 1
				for p in initializers do
					if p isa MMethod then
						var args = [recv]
						for x in p.intro.msignature.mparameters do
							args.add arguments[i]
							i += 1
						end
						v.send(p, args)
						if p.intro.is_calling_init then no_init = true
					else if p isa MAttribute then
						v.write_attribute(p, recv, arguments[i])
						i += 1
					else abort
				end
				assert i == arguments.length

			end
			if not no_init then v.send(mclass.the_root_init_mmethod.as(not null), [recv])
			return
		else
			abort
		end
	end
end

redef class AExpr
	# Try to compile self as an expression
	# Do not call this method directly, use `v.expr` instead
	private fun expr(v: AbstractCompilerVisitor): nullable RuntimeVariable
	do
		v.add("PRINT_ERROR(\"NOT YET IMPLEMENTED {class_name}:{location.to_s}\\n\");")
		var mtype = self.mtype
		if mtype == null then
			return null
		else
			var res = v.new_var(mtype)
			v.add("/* {res} = NOT YET {class_name} */")
			return res
		end
	end

	# Try to compile self as a statement
	# Do not call this method directly, use `v.stmt` instead
	private fun stmt(v: AbstractCompilerVisitor)
	do
		expr(v)
	end
end

redef class ABlockExpr
	redef fun stmt(v)
	do
		for e in self.n_expr do v.stmt(e)
	end
	redef fun expr(v)
	do
		var last = self.n_expr.last
		for e in self.n_expr do
			if e == last then break
			v.stmt(e)
		end
		return v.expr(last, null)
	end
end

redef class AVardeclExpr
	redef fun stmt(v)
	do
		var variable = self.variable.as(not null)
		var ne = self.n_expr
		if ne != null then
			var i = v.expr(ne, variable.declared_type)
			v.assign(v.variable(variable), i)
		end
	end
end

redef class AVarExpr
	redef fun expr(v)
	do
		var res = v.variable(self.variable.as(not null))
		var mtype = self.mtype.as(not null)
		return v.autoadapt(res, mtype)
	end
end

redef class AVarAssignExpr
	redef fun expr(v)
	do
		var variable = self.variable.as(not null)
		var i = v.expr(self.n_value, variable.declared_type)
		v.assign(v.variable(variable), i)
		return i
	end
end

redef class AVarReassignExpr
	redef fun stmt(v)
	do
		var variable = self.variable.as(not null)
		var vari = v.variable(variable)
		var value = v.expr(self.n_value, variable.declared_type)
		var res = v.compile_callsite(self.reassign_callsite.as(not null), [vari, value])
		assert res != null
		v.assign(v.variable(variable), res)
	end
end

redef class ASelfExpr
	redef fun expr(v) do return v.frame.arguments.first
end

redef class AImplicitSelfExpr
	redef fun expr(v) do
		if not is_sys then return super
		return v.new_expr("glob_sys", mtype.as(not null))
	end
end

redef class AEscapeExpr
	redef fun stmt(v) do v.add("goto BREAK_{v.escapemark_name(self.escapemark)};")
end

redef class AReturnExpr
	redef fun stmt(v)
	do
		var nexpr = self.n_expr
		if nexpr != null then
			var returnvar = v.frame.returnvar.as(not null)
			var i = v.expr(nexpr, returnvar.mtype)
			v.assign(returnvar, i)
		end
		v.add("goto {v.frame.returnlabel.as(not null)};")
	end
end

redef class AAbortExpr
	redef fun stmt(v) do v.add_abort("Aborted")
end

redef class AIfExpr
	redef fun stmt(v)
	do
		var cond = v.expr_bool(self.n_expr)
		v.add("if ({cond})\{")
		v.stmt(self.n_then)
		v.add("\} else \{")
		v.stmt(self.n_else)
		v.add("\}")
	end

	redef fun expr(v)
	do
		var res = v.new_var(self.mtype.as(not null))
		var cond = v.expr_bool(self.n_expr)
		v.add("if ({cond})\{")
		v.assign(res, v.expr(self.n_then.as(not null), null))
		v.add("\} else \{")
		v.assign(res, v.expr(self.n_else.as(not null), null))
		v.add("\}")
		return res
	end
end

redef class AIfexprExpr
	redef fun expr(v)
	do
		var res = v.new_var(self.mtype.as(not null))
		var cond = v.expr_bool(self.n_expr)
		v.add("if ({cond})\{")
		v.assign(res, v.expr(self.n_then, null))
		v.add("\} else \{")
		v.assign(res, v.expr(self.n_else, null))
		v.add("\}")
		return res
	end
end

redef class ADoExpr
	redef fun stmt(v)
	do
		if self.n_catch != null then
			v.add("\{")
			v.add("struct catch_stack_t *catchStack = getCatchStack();")
			v.add("if(catchStack->currentSize == 0) \{")
			v.add("		catchStack->cursor = -1;")
			v.add("		catchStack->currentSize = 100;")
			v.add("		catchStack->envs = malloc(sizeof(jmp_buf)*100);")
			v.add("\} else if(catchStack->cursor == catchStack->currentSize - 1) \{")
			v.add("		catchStack->currentSize *= 2;")
			v.add("		catchStack->envs = realloc(catchStack->envs, sizeof(jmp_buf)*catchStack->currentSize);")
			v.add("\}")
			v.add("catchStack->cursor += 1;")
			v.add("if(!setjmp(catchStack->envs[catchStack->cursor]))\{")
			v.stmt(self.n_block)
			v.add("catchStack->cursor -= 1;")
			v.add("\}else \{")
			v.add("catchStack->cursor -= 1;")
			v.stmt(self.n_catch)
			v.add("\}")
			v.add("\}")
		else
			v.stmt(self.n_block)
		end
			v.add_escape_label(break_mark)
	end
end

redef class AWhileExpr
	redef fun stmt(v)
	do
		v.add("for(;;) \{")
		var cond = v.expr_bool(self.n_expr)
		v.add("if (!{cond}) break;")
		v.stmt(self.n_block)
		v.add_escape_label(continue_mark)
		v.add("\}")
		v.add_escape_label(break_mark)
	end
end

redef class ALoopExpr
	redef fun stmt(v)
	do
		v.add("for(;;) \{")
		v.stmt(self.n_block)
		v.add_escape_label(continue_mark)
		v.add("\}")
		v.add_escape_label(break_mark)
	end
end

redef class AForExpr
	redef fun stmt(v)
	do
		for g in n_groups do
			var cl = v.expr(g.n_expr, null)
			var it_meth = g.method_iterator
			assert it_meth != null
			var it = v.compile_callsite(it_meth, [cl])
			assert it != null
			g.it = it
		end
		v.add("for(;;) \{")
		for g in n_groups do
			var it = g.it
			var isok_meth = g.method_is_ok
			assert isok_meth != null
			var ok = v.compile_callsite(isok_meth, [it])
			assert ok != null
			v.add("if(!{ok}) break;")
			if g.variables.length == 1 then
				var item_meth = g.method_item
				assert item_meth != null
				var i = v.compile_callsite(item_meth, [it])
				assert i != null
				v.assign(v.variable(g.variables.first), i)
			else if g.variables.length == 2 then
				var key_meth = g.method_key
				assert key_meth != null
				var i = v.compile_callsite(key_meth, [it])
				assert i != null
				v.assign(v.variable(g.variables[0]), i)
				var item_meth = g.method_item
				assert item_meth != null
				i = v.compile_callsite(item_meth, [it])
				assert i != null
				v.assign(v.variable(g.variables[1]), i)
			else
				abort
			end
		end
		v.stmt(self.n_block)
		v.add_escape_label(continue_mark)
		for g in n_groups do
			var next_meth = g.method_next
			assert next_meth != null
			v.compile_callsite(next_meth, [g.it])
		end
		v.add("\}")
		v.add_escape_label(break_mark)

		for g in n_groups do
			var method_finish = g.method_finish
			if method_finish != null then
				# TODO: Find a way to call this also in long escape (e.g. return)
				v.compile_callsite(method_finish, [g.it])
			end
		end
	end
end

redef class AForGroup
	# C variable representing the iterator
	private var it: RuntimeVariable is noinit
end

redef class AAssertExpr
	redef fun stmt(v)
	do
		if v.compiler.modelbuilder.toolcontext.opt_no_check_assert.value then return

		var cond = v.expr_bool(self.n_expr)
		v.add("if (unlikely(!{cond})) \{")
		v.stmt(self.n_else)

		explain_assert v

		var nid = self.n_id
		if nid != null then
			v.add_abort("Assert '{nid.text}' failed")
		else
			v.add_abort("Assert failed")
		end
		v.add("\}")
	end

	# Explain assert if it fails
	private fun explain_assert(v: AbstractCompilerVisitor)
	do
		var explain_assert_str = explain_assert_str
		if explain_assert_str == null then return

		var nas = v.compiler.modelbuilder.model.get_mclasses_by_name("NativeArray")
		if nas == null then return

		nas = v.compiler.modelbuilder.model.get_mclasses_by_name("Array")
		if nas == null or nas.is_empty then return

		var expr = explain_assert_str.expr(v)
		if expr == null then return

		var cstr = v.send(v.get_property("to_cstring", expr.mtype), [expr])
		if cstr == null then return

		v.add "PRINT_ERROR(\"Runtime assert: %s\\n\", {cstr});"
	end
end

redef class AOrExpr
	redef fun expr(v)
	do
		var res = v.new_var(self.mtype.as(not null))
		var i1 = v.expr_bool(self.n_expr)
		v.add("if ({i1}) \{")
		v.add("{res} = 1;")
		v.add("\} else \{")
		var i2 = v.expr_bool(self.n_expr2)
		v.add("{res} = {i2};")
		v.add("\}")
		return res
	end
end

redef class AImpliesExpr
	redef fun expr(v)
	do
		var res = v.new_var(self.mtype.as(not null))
		var i1 = v.expr_bool(self.n_expr)
		v.add("if (!{i1}) \{")
		v.add("{res} = 1;")
		v.add("\} else \{")
		var i2 = v.expr_bool(self.n_expr2)
		v.add("{res} = {i2};")
		v.add("\}")
		return res
	end
end

redef class AAndExpr
	redef fun expr(v)
	do
		var res = v.new_var(self.mtype.as(not null))
		var i1 = v.expr_bool(self.n_expr)
		v.add("if (!{i1}) \{")
		v.add("{res} = 0;")
		v.add("\} else \{")
		var i2 = v.expr_bool(self.n_expr2)
		v.add("{res} = {i2};")
		v.add("\}")
		return res
	end
end

redef class ANotExpr
	redef fun expr(v)
	do
		var cond = v.expr_bool(self.n_expr)
		return v.new_expr("!{cond}", self.mtype.as(not null))
	end
end

redef class AOrElseExpr
	redef fun expr(v)
	do
		var res = v.new_var(self.mtype.as(not null))
		var i1 = v.expr(self.n_expr, null)

		if not v.maybe_null(i1) then return i1

		v.add("if ({i1}!=NULL) \{")
		v.assign(res, i1)
		v.add("\} else \{")
		var i2 = v.expr(self.n_expr2, null)
		v.assign(res, i2)
		v.add("\}")
		return res
	end
end

redef class AIntegerExpr
	redef fun expr(v) do
		if value isa Int then return v.int_instance(value.as(Int))
		if value isa Byte then return v.byte_instance(value.as(Byte))
		if value isa Int8 then return v.int8_instance(value.as(Int8))
		if value isa Int16 then return v.int16_instance(value.as(Int16))
		if value isa UInt16 then return v.uint16_instance(value.as(UInt16))
		if value isa Int32 then return v.int32_instance(value.as(Int32))
		if value isa UInt32 then return v.uint32_instance(value.as(UInt32))
		# Should never happen
		abort
	end
end

redef class AFloatExpr
	redef fun expr(v) do return v.float_instance(self.value.as(Float))
end

redef class ACharExpr
	redef fun expr(v) do
		if is_code_point then
			return v.int_instance(value.as(not null).code_point)
		end
		return v.char_instance(self.value.as(not null))
	end
end

redef class AArrayExpr
	redef fun expr(v)
	do
		var mtype = self.element_mtype.as(not null)
		var array = new Array[RuntimeVariable]
		var res = v.array_instance(array, mtype)

		var old_comprehension = v.frame.comprehension
		v.frame.comprehension = res
		for nexpr in self.n_exprs do
			v.stmt(nexpr)
		end
		v.frame.comprehension = old_comprehension

		return res
	end
end

redef class AugmentedStringFormExpr
	# Factorize the making of a `Regex` object from a literal prefixed string
	protected fun make_re(v: AbstractCompilerVisitor, rs: RuntimeVariable): nullable RuntimeVariable do
		var re = to_re
		assert re != null
		var res = v.compile_callsite(re, [rs])
		if res == null then
			print "Cannot call property `to_re` on {self}"
			abort
		end
		for i in suffix.chars do
			if i == 'i' then
				var ign = ignore_case
				assert ign != null
				v.compile_callsite(ign, [res, v.bool_instance(true)])
				continue
			end
			if i == 'm' then
				var nl = newline
				assert nl != null
				v.compile_callsite(nl, [res, v.bool_instance(true)])
				continue
			end
			if i == 'b' then
				var ext = extended
				assert ext != null
				v.compile_callsite(ext, [res, v.bool_instance(false)])
				continue
			end
			# Should not happen, this needs to be updated
			# along with the addition of new suffixes
			abort
		end
		return res
	end
end

redef class AStringFormExpr
	redef fun expr(v) do return v.string_instance(value)
end

redef class AStringExpr
	redef fun expr(v) do
		var s = v.string_instance(value)
		if is_string then return s
		if is_bytestring then
			var ns = v.c_string_instance(bytes.items, bytes.length)
			var ln = v.int_instance(bytes.length)
			var cs = to_bytes_with_copy
			assert cs != null
			var res = v.compile_callsite(cs, [ns, ln])
			assert res != null
			s = res
		else if is_re then
			var res = make_re(v, s)
			assert res != null
			s = res
		else
			print "Unimplemented prefix or suffix for {self}"
			abort
		end
		return s
	end
end

redef class ASuperstringExpr
	redef fun expr(v)
	do
		var type_string = v.mmodule.string_type

		# Collect elements of the superstring
		var array = new Array[AExpr]
		for ne in self.n_exprs do
			# Drop literal empty string.
			# They appears in things like "{a}" that is ["", a, ""]
			if ne isa AStringFormExpr and ne.value == "" then continue # skip empty sub-strings
			array.add(ne)
		end

		# Store the allocated native array in a static variable
		# For reusing later
		var varonce = v.get_name("varonce")
		v.add("if (unlikely({varonce}==NULL)) \{")

		# The native array that will contains the elements to_s-ized.
		# For fast concatenation.
		var a = v.native_array_instance(type_string, v.int_instance(array.length))

		v.add_decl("static {a.mtype.ctype} {varonce};")

		# Pre-fill the array with the literal string parts.
		# So they do not need to be filled again when reused
		for i in [0..array.length[ do
			var ne = array[i]
			if not ne isa AStringFormExpr then continue
			var e = v.expr(ne, null)
			v.native_array_set(a, i, e)
		end

		v.add("\} else \{")
		# Take the native-array from the store.
		# The point is to prevent that some recursive execution use (and corrupt) the same native array
		# WARNING: not thread safe! (FIXME?)
		v.add("{a} = {varonce};")
		v.add("{varonce} = NULL;")
		v.add("\}")

		# Stringify the elements and put them in the native array
		var to_s_method = v.get_property("to_s", v.object_type)
		for i in [0..array.length[ do
			var ne = array[i]
			if ne isa AStringFormExpr then continue
			var e = v.expr(ne, null)
			# Skip the `to_s` if the element is already a String
			if not e.mcasttype.is_subtype(v.compiler.mainmodule, null, type_string) then
				e = v.send(to_s_method, [e]).as(not null)
			end
			v.native_array_set(a, i, e)
		end

		# Fast join the C string to get the result
		var res = v.send(v.get_property("native_to_s", a.mtype), [a])
		assert res != null

		if is_re then res = make_re(v, res)

		# We finish to work with the native array,
		# so store it so that it can be reused
		v.add("{varonce} = {a};")

		return res
	end
end

redef class ACrangeExpr
	redef fun expr(v)
	do
		var i1 = v.expr(self.n_expr, null)
		var i2 = v.expr(self.n_expr2, null)
		var mtype = self.mtype.as(MClassType)
		var res = v.init_instance(mtype)
		v.compile_callsite(init_callsite.as(not null), [res, i1, i2])
		return res
	end
end

redef class AOrangeExpr
	redef fun expr(v)
	do
		var i1 = v.expr(self.n_expr, null)
		var i2 = v.expr(self.n_expr2, null)
		var mtype = self.mtype.as(MClassType)
		var res = v.init_instance(mtype)
		v.compile_callsite(init_callsite.as(not null), [res, i1, i2])
		return res
	end
end

redef class ATrueExpr
	redef fun expr(v) do return v.bool_instance(true)
end

redef class AFalseExpr
	redef fun expr(v) do return v.bool_instance(false)
end

redef class ANullExpr
	redef fun expr(v) do return v.null_instance
end

redef class AIsaExpr
	redef fun expr(v)
	do
		var i = v.expr(self.n_expr, null)
		var cast_type = self.cast_type
		if cast_type == null then return null # no-no on broken node
		return v.type_test(i, cast_type, "isa")
	end
end

redef class AAsCastExpr
	redef fun expr(v)
	do
		var i = v.expr(self.n_expr, null)
		if v.compiler.modelbuilder.toolcontext.opt_no_check_assert.value then return i

		v.add_cast(i, self.mtype.as(not null), "as")
		return i
	end
end

redef class AAsNotnullExpr
	redef fun expr(v)
	do
		var i = v.expr(self.n_expr, null)
		if v.compiler.modelbuilder.toolcontext.opt_no_check_assert.value then return i

		if not v.maybe_null(i) then return i

		v.add("if (unlikely({i} == NULL)) \{")
		v.add_abort("Cast failed")
		v.add("\}")
		return i
	end
end

redef class AParExpr
	redef fun expr(v) do return v.expr(self.n_expr, null)
end

redef class AOnceExpr
	redef fun expr(v)
	do
		var mtype = self.mtype.as(not null)
		var name = v.get_name("varonce")
		var guard = v.get_name(name + "_guard")
		v.add_decl("static {mtype.ctype} {name};")
		v.add_decl("static int {guard};")
		var res = v.new_var(mtype)
		v.add("if (likely({guard})) \{")
		v.add("{res} = {name};")
		v.add("\} else \{")
		var i = v.expr(self.n_expr, mtype)
		v.add("{res} = {i};")
		v.add("{name} = {res};")
		v.add("{guard} = 1;")
		v.add("\}")
		return res
	end
end

redef class ASendExpr
	redef fun expr(v)
	do
		var recv = v.expr(self.n_expr, null)
		if is_safe then
			v.add "if ({recv}!=NULL) \{"
		end
		var callsite = self.callsite.as(not null)
		if callsite.is_broken then return null
		var args = v.varargize(callsite.mpropdef, callsite.signaturemap, recv, self.raw_arguments)
		var res = v.compile_callsite(callsite, args)
		if is_safe then
			if res != null then
				# `callsite.mpropdef` may reference a method whose
				# return type is a primitive type in C. If it is
				# the case, we must convert the primitive type to
				# a `val*` to support nullable assignment.
				# Autobox's job is to convert primitive type to
				# nullable type, eg from `Int` to `nullable `Int`.
				# The target type reside in `self.mtype`.
				var original_res = v.autobox(res, self.mtype.as(not null))

				# Here we must create a new_var in case the original
				# type is not nullable. We can't call `autobox` to
				# convert a complex type to its nullable version.
				# eg if we have a type `A`, calling autobox like
				# `autobox(A, nullable A)` will return `A` since
				# `A` and `nullable A` have the same primitive
				# type. The nullable qualifier is only used at
				# compile time to add appropriate null checks.
				res = v.new_var(self.mtype.as(not null))
				v.add("{res} = {original_res};")
				v.add("\} else \{")
				v.add("{res} = NULL;")
			end
			v.add("\}")
		end
		return res
	end
end

redef class ACallrefExpr
	redef fun expr(v)
	do
		var recv = v.expr(self.n_expr, null)
		var res = v.routine_ref_instance(mtype.as(MClassType), recv, callsite.as(not null))
		return res
	end
end

redef class ASendReassignFormExpr
	redef fun stmt(v)
	do
		var recv = v.expr(self.n_expr, null)
		var callsite = self.callsite.as(not null)
		if callsite.is_broken then return
		var args = v.varargize(callsite.mpropdef, callsite.signaturemap, recv, self.raw_arguments)

		var value = v.expr(self.n_value, null)

		var left = v.compile_callsite(callsite, args)
		assert left != null

		var res = v.compile_callsite(self.reassign_callsite.as(not null), [left, value])
		assert res != null

		args.add(res)
		v.compile_callsite(self.write_callsite.as(not null), args)
	end
end

redef class ASuperExpr
	redef fun expr(v)
	do
		var frame = v.frame.as(not null)
		var recv = frame.arguments.first

		var callsite = self.callsite
		if callsite != null then
			if callsite.is_broken then return null
			var args

			if self.n_args.n_exprs.is_empty then
				# Add automatic arguments for the super init call
				args = [recv]
				for i in [0..callsite.msignature.arity[ do
					args.add(frame.arguments[i+1])
				end
			else
				args = v.varargize(callsite.mpropdef, callsite.signaturemap, recv, self.n_args.n_exprs)
			end

			# Super init call
			var res = v.compile_callsite(callsite, args)
			return res
		end

		var mpropdef = self.mpropdef.as(not null)

		var args
		if self.n_args.n_exprs.is_empty then
			args = frame.arguments
		else
			args = v.varargize(mpropdef, signaturemap, recv, self.n_args.n_exprs)
		end

		# Standard call-next-method
		return v.supercall(mpropdef, recv.mtype.as(MClassType), args)
	end
end

redef class ANewExpr
	redef fun expr(v)
	do
		var mtype = self.recvtype
		assert mtype != null

		if mtype.mclass.name == "NativeArray" then
			assert self.n_args.n_exprs.length == 1
			var l = v.expr(self.n_args.n_exprs.first, null)
			assert mtype isa MGenericType
			var elttype = mtype.arguments.first
			return v.native_array_instance(elttype, l)
		end

		var callsite = self.callsite
		if callsite == null then return v.init_instance_or_extern(mtype)
		if callsite.is_broken then return null

		var recv
		# new factories are badly implemented.
		# They assume a stub temporary receiver exists.
		# This temporary receiver is required because it
		# currently holds the method and the formal types.
		#
		# However, this object could be reused if the formal types are the same.
		# Therefore, the following code will `once` it in these case
		if callsite.mproperty.is_new and not mtype.need_anchor then
			var name = v.get_name("varoncenew")
			var guard = v.get_name(name + "_guard")
			v.add_decl("static {mtype.ctype} {name};")
			v.add_decl("static int {guard};")
			recv = v.new_var(mtype)
			v.add("if (likely({guard})) \{")
			v.add("{recv} = {name};")
			v.add("\} else \{")
			var i = v.init_instance_or_extern(mtype)
			v.add("{recv} = {i};")
			v.add("{name} = {recv};")
			v.add("{guard} = 1;")
			v.add("\}")
		else
			recv = v.init_instance_or_extern(mtype)
		end

		var args = v.varargize(callsite.mpropdef, callsite.signaturemap, recv, self.n_args.n_exprs)
		var res2 = v.compile_callsite(callsite, args)
		if res2 != null then
			#self.debug("got {res2} from {mproperty}. drop {recv}")
			return res2
		end
		return recv
	end
end

redef class AAttrExpr
	redef fun expr(v)
	do
		var recv = v.expr(self.n_expr, null)
		var mproperty = self.mproperty.as(not null)
		return v.read_attribute(mproperty, recv)
	end
end

redef class AAttrAssignExpr
	redef fun expr(v)
	do
		var recv = v.expr(self.n_expr, null)
		var i = v.expr(self.n_value, null)
		var mproperty = self.mproperty.as(not null)
		v.write_attribute(mproperty, recv, i)
		return i
	end
end

redef class AAttrReassignExpr
	redef fun stmt(v)
	do
		var recv = v.expr(self.n_expr, null)
		var value = v.expr(self.n_value, null)
		var mproperty = self.mproperty.as(not null)
		var attr = v.read_attribute(mproperty, recv)
		var res = v.compile_callsite(self.reassign_callsite.as(not null), [attr, value])
		assert res != null
		v.write_attribute(mproperty, recv, res)
	end
end

redef class AIssetAttrExpr
	redef fun expr(v)
	do
		var recv = v.expr(self.n_expr, null)
		var mproperty = self.mproperty.as(not null)
		return v.isset_attribute(mproperty, recv)
	end
end

redef class AVarargExpr
	redef fun expr(v)
	do
		return v.expr(self.n_expr, null)
	end
end

redef class ASafeExpr
	redef fun expr(v)
	do
		return v.expr(self.n_expr, null)
	end
end

redef class ANamedargExpr
	redef fun expr(v)
	do
		return v.expr(self.n_expr, null)
	end
end

redef class ADebugTypeExpr
	redef fun stmt(v)
	do
		# do nothing
	end
end

# Utils

redef class Array[E]
	# Return a new `Array` with the elements only contened in self and not in `o`
	fun -(o: Array[E]): Array[E] do
		var res = new Array[E]
		for e in self do if not o.has(e) then res.add(e)
		return res
	end
end

redef class MModule
	# All `MProperty` associated to all `MClassDef` of `mclass`
	fun properties(mclass: MClass): Set[MProperty] do
		if not self.properties_cache.has_key(mclass) then
			var properties = new HashSet[MProperty]
			var parents = new Array[MClass]
			if self.flatten_mclass_hierarchy.has(mclass) then
				parents.add_all(mclass.in_hierarchy(self).direct_greaters)
			end
			for parent in parents do
				properties.add_all(self.properties(parent))
			end
			for mclassdef in mclass.mclassdefs do
				if not self.in_importation <= mclassdef.mmodule then continue
				for mprop in mclassdef.intro_mproperties do
					properties.add(mprop)
				end
			end
			self.properties_cache[mclass] = properties
		end
		return properties_cache[mclass]
	end
	private var properties_cache: Map[MClass, Set[MProperty]] = new HashMap[MClass, Set[MProperty]]

	# Write FFI and nitni results to file
	fun finalize_ffi(c: AbstractCompiler) do end

	# Give requided addinional system libraries (as given to LD_LIBS)
	# Note: can return null instead of an empty set
	fun collect_linker_libs: nullable Array[String] do return null
end

# Create a tool context to handle options and paths
var toolcontext = new ToolContext

toolcontext.tooldescription = "Usage: nitc [OPTION]... file.nit...\nCompiles Nit programs."

# We do not add other options, so process them now!
toolcontext.process_options(args)

# We need a model to collect stufs
var model = new Model
# An a model builder to parse files
var modelbuilder = new ModelBuilder(model, toolcontext)

var arguments = toolcontext.option_context.rest
if toolcontext.opt_run.value then
	# When --run, only the first is the program, the rest is the run arguments
	arguments = [toolcontext.option_context.rest.shift]
end
if arguments.length > 1 and toolcontext.opt_output.value != null then
	print "Option Error: --output needs a single source file. Do you prefer --dir?"
	exit 1
end

# Here we load an process all modules passed on the command line
var mmodules = modelbuilder.parse(arguments)

if mmodules.is_empty then toolcontext.quit

modelbuilder.run_phases

for mmodule in mmodules do
	toolcontext.info("*** PROCESS {mmodule} ***", 1)
	var ms = [mmodule]
	toolcontext.run_global_phases(ms)
end
