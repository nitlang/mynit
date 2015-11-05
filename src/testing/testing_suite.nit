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

# Testing from external files.
module testing_suite

import testing_base
import html
private import annotation

redef class ToolContext
	# -- target-file
	var opt_file = new OptionString("Specify test suite location", "-t", "--target-file")
	# --pattern
	var opt_pattern = new OptionString("Only run test case with name that match pattern", "-p", "--pattern")
end

# Used to test nitunit test files.
class NitUnitTester

	# `ModelBuilder` used to parse test files.
	var mbuilder: ModelBuilder

	# Parse a file and return the contained `MModule`.
	private fun parse_module_unit(file: String): nullable MModule do
		var mmodule = mbuilder.parse([file]).first
		if mbuilder.get_mmodule_annotation("test_suite", mmodule) == null then return null
		mbuilder.run_phases
		return mmodule
	end

	# Compile and execute the test suite for a NitUnit `file`.
	fun test_module_unit(file: String): nullable TestSuite do
		var toolcontext = mbuilder.toolcontext
		var mmodule = parse_module_unit(file)
		# is the module a test_suite?
		if mmodule == null then return null
		var suite = new TestSuite(mmodule, toolcontext)
		# method to execute before all tests in the module
		var before_module = mmodule.before_test
		if before_module != null then
			toolcontext.modelbuilder.total_tests += 1
			suite.before_module = new TestCase(suite, before_module, toolcontext)
		end
		# generate all test cases
		for mclassdef in mmodule.mclassdefs do
			if not mclassdef.is_test then continue
			if not suite_match_pattern(mclassdef) then continue
			toolcontext.modelbuilder.total_classes += 1
			var before_test = mclassdef.before_test
			var after_test = mclassdef.after_test
			for mpropdef in mclassdef.mpropdefs do
				if not mpropdef isa MMethodDef or not mpropdef.is_test then continue
				if not case_match_pattern(mpropdef) then continue
				toolcontext.modelbuilder.total_tests += 1
				var test = new TestCase(suite, mpropdef, toolcontext)
				test.before_test = before_test
				test.after_test = after_test
				suite.add_test test
			end
		end
		# method to execute after all tests in the module
		var after_module = mmodule.after_test
		if after_module != null then
			toolcontext.modelbuilder.total_tests += 1
			suite.after_module = new TestCase(suite, after_module, toolcontext)
		end
		suite.run
		return suite
	end

	# Is the test suite name match the pattern option?
	private fun suite_match_pattern(suite: MClassDef): Bool do
		var pattern = mbuilder.toolcontext.opt_pattern.value
		if pattern == null then return true
		var ps = pattern.split_with("::")
		var p = ps.first
		if ps.length == 1 and p.first.is_lower then return true
		if ps.length == 2 and p.first.is_lower then return false
		if p.has_suffix("*") then
			p = p.substring(0, p.length - 1)
			if suite.name.has_prefix(p) then return true
		else
			if suite.name == p then return true
		end
		return false
	end

	# Is the test case name match the pattern option?
	private fun case_match_pattern(case: MPropDef): Bool do
		var pattern = mbuilder.toolcontext.opt_pattern.value
		if pattern == null then return true
		var ps = pattern.split_with("::")
		var p = ps.last
		if ps.length == 1 and p.first.is_upper then return true
		if ps.length == 2 and p.first.is_upper then return false
		if p.has_suffix("*") then
			p = p.substring(0, p.length - 1)
			if case.name.has_prefix(p) then return true
		else
			if case.name == p then return true
		end
		return false
	end
end

# A test suite contains all the test cases for a `MModule`.
class TestSuite

	# `MModule` under test
	var mmodule: MModule

	# `ToolContext` to use to display messages.
	var toolcontext: ToolContext

	# List of `TestCase` to be executed in this suite.
	var test_cases = new Array[TestCase]

	# Add a `TestCase` to the suite.
	fun add_test(case: TestCase) do test_cases.add case

	# Test to be executed before the whole test suite.
	var before_module: nullable TestCase = null

	# Test to be executed after the whole test suite.
	var after_module: nullable TestCase = null

	# Execute the test suite
	fun run do
		if not toolcontext.test_dir.file_exists then
			toolcontext.test_dir.mkdir
		end
		write_to_nit
		compile
		toolcontext.info("Execute test-suite {mmodule.name}", 1)
		var before_module = self.before_module
		if not before_module == null then before_module.run
		for case in test_cases do case.run
		var after_module = self.after_module
		if not after_module == null then after_module.run
	end

	# Write the test unit for `self` in a nit compilable file.
	fun write_to_nit do
		var file = new Template
		file.addn "intrude import test_suite"
		file.addn "import {mmodule.name}\n"
		file.addn "var name = args.first"
		for case in test_cases do
			case.write_to_nit(file)
		end
		file.write_to_file("{test_file}.nit")
	end

	# Return the test suite in XML format compatible with Jenkins.
	# Contents depends on the `run` execution.
	fun to_xml: HTMLTag do
		var n = new HTMLTag("testsuite")
		n.attr("package", mmodule.name)
		if failure != null then
			var f = new HTMLTag("failure")
			f.attr("message", failure.to_s)
			n.add f
		else
			for test in test_cases do n.add test.to_xml
		end
		return n
	end

	# Generated test file name.
	fun test_file: String do
		return toolcontext.test_dir / "gen_{mmodule.name.escape_to_c}"
	end

	# Compile all `test_cases` cases in one file.
	fun compile do
		# find nitc
		var nit_dir = toolcontext.nit_dir
		var nitc = nit_dir/"bin/nitc"
		if not nitc.file_exists then
			toolcontext.error(null, "Error: cannot find nitc. Set envvar NIT_DIR.")
			toolcontext.check_errors
		end
		# compile test suite
		var file = test_file
		var include_dir = mmodule.location.file.filename.dirname
		var cmd = "{nitc} --no-color '{file}.nit' -I {include_dir} -o '{file}.bin' > '{file}.out' 2>&1 </dev/null"
		var res = sys.system(cmd)
		var f = new FileReader.open("{file}.out")
		var msg = f.read_all
		f.close
		# set test case result
		var loc = mmodule.location
		if res != 0 then
			failure = msg
			toolcontext.warning(loc, "failure", "FAILURE: {mmodule.name} (in file {file}.nit): {msg}")
			toolcontext.modelbuilder.failed_tests += 1
		end
		toolcontext.check_errors
	end

	# Error occured during test-suite compilation.
	var failure: nullable String = null
end

# A test case is a unit test considering only a `MMethodDef`.
class TestCase

	# Test suite wich `self` belongs to.
	var test_suite: TestSuite

	# Test method to be compiled and tested.
	var test_method: MMethodDef

	# `ToolContext` to use to display messages and find `nitc` bin.
	var toolcontext: ToolContext

	# `MMethodDef` to call before the test case.
	var before_test: nullable MMethodDef = null

	# `MMethodDef` to call after the test case.
	var after_test: nullable MMethodDef = null

	# Generate the test unit for `self` in `file`.
	fun write_to_nit(file: Template) do
		var name = test_method.name
		file.addn "if name == \"{name}\" then"
		if test_method.mproperty.is_toplevel then
			file.addn "\t{name}"
		else
			file.addn "\tvar subject = new {test_method.mclassdef.name}.nitunit"
			if before_test != null then file.addn "\tsubject.{before_test.name}"
			file.addn "\tsubject.{name}"
			if after_test != null then file.addn "\tsubject.{after_test.name}"
		end
		file.addn "end"
	end

	# Execute the test case.
	fun run do
		toolcontext.info("Execute test-case {test_method.name}", 1)
		was_exec = true
		if toolcontext.opt_noact.value then return
		# execute
		var method_name = test_method.name
		var test_file = test_suite.test_file
		var res_name = "{test_file}_{method_name.escape_to_c}"
		var res = sys.system("{test_file}.bin {method_name} > '{res_name}.out1' 2>&1 </dev/null")
		var f = new FileReader.open("{res_name}.out1")
		var msg = f.read_all
		f.close
		# set test case result
		var loc = test_method.location
		if res != 0 then
			error = msg
			toolcontext.warning(loc, "failure",
			   "ERROR: {method_name} (in file {test_file}.nit): {msg}")
			toolcontext.modelbuilder.failed_tests += 1
		end
		toolcontext.check_errors
	end

	# Error occured during test-case execution.
	var error: nullable String = null

	# Was the test case executed at least one?
	var was_exec = false

	# Return the `TestCase` in XML format compatible with Jenkins.
	fun to_xml: HTMLTag do
		var mclassdef = test_method.mclassdef
		var tc = new HTMLTag("testcase")
		# NOTE: jenkins expects a '.' in the classname attr
		tc.attr("classname", "nitunit." + mclassdef.mmodule.full_name + "." + mclassdef.mclass.full_name)
		tc.attr("name", test_method.mproperty.full_name)
		if was_exec then
			tc.add  new HTMLTag("system-err")
			var n = new HTMLTag("system-out")
			n.append "out"
			tc.add n
			if error != null then
				n = new HTMLTag("error")
				n.attr("message", error.to_s)
				tc.add n
			end
		end
		return tc
	end
end

redef class MMethodDef
	# TODO use annotations?

	# Is the method a test_method?
	# i.e. begins with "test_"
	private fun is_test: Bool do return name.has_prefix("test_")

	# Is the method a "before_test"?
	private fun is_before: Bool do return name == "before_test"

	# Is the method a "after_test"?
	private fun is_after: Bool do return name == "after_test"

	# Is the method a "before_module"?
	private fun is_before_module: Bool do return mproperty.is_toplevel and name == "before_module"

	# Is the method a "after_module"?
	private fun is_after_module: Bool do return mproperty.is_toplevel and name == "after_module"
end

redef class MClassDef
	# Is the class a TestClass?
	# i.e. begins with "Test"
	private fun is_test: Bool do
		for sup in in_hierarchy.greaters do
			if sup.name == "TestSuite" then return true
		end
		return false
	end

	# "before_test" method for this classdef.
	private fun before_test: nullable MMethodDef do
		for mpropdef in mpropdefs do
			if mpropdef isa MMethodDef and mpropdef.is_before then return mpropdef
		end
		return null
	end

	# "after_test" method for this classdef.
	private fun after_test: nullable MMethodDef do
		for mpropdef in mpropdefs do
			if mpropdef isa MMethodDef and mpropdef.is_after then return mpropdef
		end
		return null
	end
end

redef class MModule
	# "before_module" method for this module.
	private fun before_test: nullable MMethodDef do
		for mclassdef in mclassdefs do
			if not mclassdef.name == "Object" then continue
			for mpropdef in mclassdef.mpropdefs do
				if mpropdef isa MMethodDef and mpropdef.is_before_module then return mpropdef
			end
		end
		return null
	end

	# "after_module" method for this module.
	private fun after_test: nullable MMethodDef do
		for mclassdef in mclassdefs do
			if not mclassdef.name == "Object" then continue
			for mpropdef in mclassdef.mpropdefs do
				if mpropdef isa MMethodDef and mpropdef.is_after_module then return mpropdef
			end
		end
		return null
	end
end

redef class ModelBuilder
	# Number of test classes generated.
	var total_classes = 0

	# Number of tests generated.
	var total_tests = 0

	# Number of failed tests.
	var failed_tests = 0

	# Run NitUnit test file for mmodule (if exists).
	fun test_unit(mmodule: MModule): HTMLTag do
		var ts = new HTMLTag("testsuite")
		toolcontext.info("nitunit: test-suite test_{mmodule}", 2)
		var f = toolcontext.opt_file.value
		var test_file = "test_{mmodule.name}.nit"
		if f != null then
			test_file = f
		else if not test_file.file_exists then
			var include_dir = mmodule.location.file.filename.dirname
			test_file = "{include_dir}/{test_file}"
		end
		if not test_file.file_exists then
			toolcontext.info("Skip test for {mmodule}, no file {test_file} found", 2)
			return ts
		end
		var tester = new NitUnitTester(self)
		var res = tester.test_module_unit(test_file)
		if res == null then
			toolcontext.info("Skip test for {mmodule}, no test suite found", 2)
			return ts
		end
		return res.to_xml
	end
end
