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

# A global Nit compiler
module nitg

import modelbuilder
import exprbuilder
import rapid_type_analysis
import global_compiler
import separate_erasure_compiler
import separate_compiler

# Create a tool context to handle options and paths
var toolcontext = new ToolContext
# We do not add other options, so process them now!
toolcontext.process_options

# We need a model to collect stufs
var model = new Model
# An a model builder to parse files
var modelbuilder = new ModelBuilder(model, toolcontext)

var arguments = toolcontext.option_context.rest
if arguments.is_empty then
	toolcontext.option_context.usage
	return
end
var progname = arguments.first

# Here we load an process all modules passed on the command line
var mmodules = modelbuilder.parse_and_build([progname])
if mmodules.is_empty then return
modelbuilder.full_propdef_semantic_analysis

if toolcontext.opt_only_metamodel.value then exit(0)

# Here we launch the interpreter on the main module
assert mmodules.length == 1
var mainmodule = mmodules.first
var analysis = modelbuilder.do_rapid_type_analysis(mainmodule)

if toolcontext.opt_erasure.value then
	modelbuilder.run_separate_erasure_compiler(mainmodule, analysis)
else if toolcontext.opt_separate.value then
	modelbuilder.run_separate_compiler(mainmodule, analysis)
else
	modelbuilder.run_global_compiler(mainmodule, analysis)
end
