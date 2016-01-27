# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Documentation generator for the nit language.
#
# Generate API documentation in HTML format from nit source code.
module nitdoc

import modelbuilder
import doc

redef class ToolContext
	# Nitdoc generation phase.
	var docphase: Phase = new Nitdoc(self, null)

	# Do not generate documentation for attributes.
	var opt_no_attributes = new OptionBool("Ignore the attributes", "--no-attributes")

	# Do not generate documentation for private properties.
	var opt_private = new OptionBool("Also generate private API", "--private")

	redef init do
		super
		option_context.add_option(opt_no_attributes, opt_private)
	end
end

# Nitdoc phase explores the model and generate pages for each mentities found
private class Nitdoc
	super Phase
	redef fun process_mainmodule(mainmodule, mmodules)
	do
		var doc = new DocModel(mainmodule.model, mainmodule)
		if not toolcontext.opt_private.value then doc.min_visibility = protected_visibility
		if not toolcontext.opt_no_attributes.value then doc.include_attribute = false

		var phases = [
			new IndexingPhase(toolcontext, doc),
			new MakePagePhase(toolcontext, doc),
			new POSetPhase(toolcontext, doc),
			new ConcernsPhase(toolcontext, doc),
			new StructurePhase(toolcontext, doc),
			new InheritanceListsPhase(toolcontext, doc),
			new IntroRedefListPhase(toolcontext, doc),
			new LinListPhase(toolcontext, doc),
			new GraphPhase(toolcontext, doc),
			new CodePhase(toolcontext, doc),
			new ReadmePhase(toolcontext, doc),
			new RenderHTMLPhase(toolcontext, doc),
			new DocTestPhase(toolcontext, doc): DocPhase]

		for phase in phases do
			toolcontext.info("# {phase.class_name}", 1)
			phase.apply
		end
	end
end

# build toolcontext
var toolcontext = new ToolContext
var tpl = new Template
tpl.add "Usage: nitdoc [OPTION]... <file.nit>...\n"
tpl.add "Generates HTML pages of API documentation from Nit source files."
toolcontext.tooldescription = tpl.write_to_string

# process options
toolcontext.process_options(args)
var arguments = toolcontext.option_context.rest

# build model
var model = new Model
var mbuilder = new ModelBuilder(model, toolcontext)
var mmodules = mbuilder.parse_full(arguments)

# process
if mmodules.is_empty then return
mbuilder.run_phases
toolcontext.run_global_phases(mmodules)
