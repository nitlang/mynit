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

# A program that collects various metrics on nit programs and libraries
module nitmetrics

import modelbuilder
import exprbuilder
import metrics

# Create a tool context to handle options and paths
var toolcontext = new ToolContext
# We do not add other options, so process them now!
toolcontext.process_options

# Get arguments
var arguments = toolcontext.option_context.rest
if arguments.is_empty or toolcontext.opt_help.value then
	toolcontext.option_context.usage
	return
end

# We need a model to collect stufs
var model = new Model
# An a model builder to parse files
var modelbuilder = new ModelBuilder(model, toolcontext)

# Here we load an process all modules passed on the command line
var mmodules = modelbuilder.parse_and_build(arguments)
modelbuilder.full_propdef_semantic_analysis

if mmodules.length == 0 then return

var mainmodule: MModule
if mmodules.length == 1 then
	mainmodule = mmodules.first
else
	# We need a main module, so we build it by importing all modules
	mainmodule = new MModule(model, null, "<main>", new Location(null, 0, 0, 0, 0))
	mainmodule.set_imported_mmodules(mmodules)
end

# Now, we just have to play with the model!
print "*** STATS ***"

print ""
compute_statistics(model)

# Self usage metrics
if toolcontext.opt_self.value then
	print ""
	compute_self_metrics(modelbuilder)
end

# Nullables metrics
if toolcontext.opt_nullables.value then
	print ""
	compute_nullables_metrics(modelbuilder)
end

# Static types metrics
if toolcontext.opt_static_types.value then
	print ""
	compute_static_types_metrics(modelbuilder)
end

# Tables metrics
if toolcontext.opt_tables.value then
	print ""
	compute_tables_metrics(mainmodule)
end

# RTA metrics
if toolcontext.opt_rta.value then
	print ""
	compute_rta_metrics(modelbuilder, mainmodule)
end

# Generate Hyperdoc
if toolcontext.opt_generate_hyperdoc.value then
	generate_module_hierarchy(toolcontext, model)
	generate_classdef_hierarchy(toolcontext, model)
	generate_class_hierarchy(toolcontext, mainmodule)
	generate_model_hyperdoc(toolcontext, model)
end
