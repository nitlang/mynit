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

# Extract data mentities of Model that will be documented.
#
# ExtractionPhase populates the DocModel that is the base for all other phases.
# No DocPages are created at this level.
#
# TODO build a model instead?
module doc_extract

import doc_base

redef class ToolContext

	# Do not generate documentation for attributes.
	var opt_no_attributes = new OptionBool(
		"do not generate documentation for attributes", "--no-attributes")

	# Do not generate documentation for properties.
	var opt_no_properties = new OptionBool(
		"do not generate documentation for properties", "--no-properties")

	# Do not generate documentation for classes and properties.
	var opt_no_classes = new OptionBool(
		"do not generate documentation for classes (and properties)", "--no-classes")

	# Do not generate documentation for redefinitions.
	var opt_no_redefs = new OptionBool(
		"do not generate documentation for redefinitions", "--no-redefs")

	# Do not generate documentation for mentities with no MDoc.
	var opt_no_empty_doc = new OptionBool(
		"do not generate documentation for entities with empty nitdoc comments", "--no-empty-doc")

	# Generate documentation for private properties.
	var opt_private = new OptionBool("Also generate private API", "--private")

	redef init do
		super
		option_context.add_option(
			opt_no_attributes, opt_no_properties, opt_no_classes,
			opt_no_redefs, opt_no_empty_doc, opt_private)
	end

	# Minimum visibility displayed.
	#
	# See `opt_private`.
	var min_visibility: MVisibility is lazy do
		if opt_private.value then return none_visibility
		return protected_visibility
	end

	# Should we exclude this `mentity` from the documentation?
	fun ignore_mentity(mentity: MEntity): Bool do
		if mentity isa MModule then
			return mentity.is_fictive or mentity.is_test_suite
		else if mentity isa MClass then
			if opt_no_classes.value then return true
			return mentity.visibility < min_visibility
		else if mentity isa MClassDef then
			if opt_no_redefs.value and not mentity.is_intro then return true
			if opt_no_classes.value then return true
			return ignore_mentity(mentity.mclass)
		else if mentity isa MProperty then
			if opt_no_classes.value or opt_no_properties.value then return true
			return ignore_mentity(mentity.intro_mclassdef) or
				mentity.visibility < min_visibility or
				(opt_no_attributes.value and mentity isa MAttribute) or
				mentity isa MInnerClass
		else if mentity isa MPropDef then
			if opt_no_redefs.value and not mentity.is_intro then return true
			if opt_no_classes.value or opt_no_properties.value then return true
			return ignore_mentity(mentity.mclassdef) or
				ignore_mentity(mentity.mproperty)
		end
		var mdoc = mentity.mdoc
		if opt_no_empty_doc.value and (mdoc == null or mdoc.content.is_empty) then return true
		return false
	end
end

# ExtractionPhase populates the DocModel.
class ExtractionPhase
	super DocPhase

	private var new_model: Model is noinit

	# Populates the given DocModel.
	redef fun apply do doc.populate(self)
end

# TODO Should I rebuild a new Model from filtered data?
redef class DocModel

	# MPackages that will be documented.
	var mpackages = new HashSet[MPackage]

	# MGroups that will be documented.
	var mgroups = new HashSet[MGroup]

	# MModules that will be documented.
	var mmodules = new HashSet[MModule]

	# MClasses that will be documented.
	var mclasses = new HashSet[MClass]

	# MClassDefs that will be documented.
	var mclassdefs = new HashSet[MClassDef]

	# MProperties that will be documented.
	var mproperties = new HashSet[MProperty]

	# MPropdefs that will be documented.
	var mpropdefs = new HashSet[MPropDef]

	# Populate `self` from internal `model`.
	fun populate(v: ExtractionPhase) do
		populate_mpackages(v)
		if v.ctx.opt_no_classes.value then return
		populate_mclasses(v)
		if v.ctx.opt_no_properties.value then return
		populate_mproperties(v)
	end

	# Populates the `mpackages` set.
	private fun populate_mpackages(v: ExtractionPhase) do
		var ctx = v.ctx
		for mpackage in model.mpackages do
			if ctx.ignore_mentity(mpackage) then continue
			self.mpackages.add mpackage
			for mgroup in mpackage.mgroups do
				if ctx.ignore_mentity(mgroup) then continue
				self.mgroups.add mgroup
				for mmodule in mgroup.mmodules do
					if ctx.ignore_mentity(mmodule) then continue
					self.mmodules.add mmodule
				end
			end
		end
	end

	# Populates the `mclasses` set.
	private fun populate_mclasses(v: ExtractionPhase) do
		var ctx = v.ctx
		for mclass in model.mclasses do
			if ctx.ignore_mentity(mclass) then continue
			self.mclasses.add mclass
			for mclassdef in mclass.mclassdefs do
				if ctx.ignore_mentity(mclassdef) then continue
				self.mclassdefs.add mclassdef
			end
		end
	end

	# Populates the `mproperties` set.
	private fun populate_mproperties(v: ExtractionPhase) do
		var ctx = v.ctx
		for mproperty in model.mproperties do
			if ctx.ignore_mentity(mproperty) then continue
			self.mproperties.add mproperty
			for mpropdef in mproperty.mpropdefs do
				if ctx.ignore_mentity(mpropdef) then continue
				self.mpropdefs.add mpropdef
			end
		end
	end

	# Lists all MEntities in the model.
	#
	# FIXME invalidate cache if `self` is modified.
	var mentities: Collection[MEntity] is lazy do
		var res = new HashSet[MEntity]
		res.add_all mpackages
		res.add_all mgroups
		res.add_all mmodules
		res.add_all mclasses
		res.add_all mclassdefs
		res.add_all mproperties
		res.add_all mpropdefs
		return res
	end

	# Searches MEntities that match `name`.
	fun mentities_by_name(name: String): Array[MEntity] do
		var res = new Array[MEntity]
		for mentity in mentities do
			if mentity.name != name then continue
			res.add mentity
		end
		return res
	end

	# Looks up a MEntity by its `namespace`.
	#
	# Usefull when `mentities_by_name` by return conflicts.
	#
	# Path can be the shortest possible to disambiguise like `Class::property`.
	# In case of larger conflicts, a more complex namespace can be given like
	# `package::module::Class::prop`.
	fun mentities_by_namespace(namespace: String): Array[MEntity] do
		var res = new Array[MEntity]
		var parts = namespace.split_once_on("::")
		var name = parts.shift
		for mentity in mpackages do
			if mentity.name != name then continue
			if parts.is_empty then
				res.add mentity
			else
				mentity.mentities_by_namespace(parts.first, res)
			end
		end
		return res
	end
end

redef class MEntity
	# Looks up a MEntity by its `namespace` from `self`.
	private fun mentities_by_namespace(namespace: String, res: Array[MEntity]) do end

	private fun lookup_in(mentities: Collection[MEntity], namespace: String, res: Array[MEntity]) do
		var parts = namespace.split_once_on("::")
		var name = parts.shift
		for mentity in mentities do
			if mentity.name != name then continue
			if parts.is_empty then
				res.add mentity
			else
				mentity.mentities_by_namespace(parts.first, res)
			end
		end
	end
end

redef class MPackage
	redef fun mentities_by_namespace(namespace, res) do
		var root = self.root
		if root == null then return
		lookup_in([root], namespace, res)
	end
end

redef class MGroup
	redef fun mentities_by_namespace(namespace, res) do
		lookup_in(in_nesting.direct_smallers, namespace, res)
		lookup_in(mmodules, namespace, res)
	end
end

redef class MModule
	redef fun mentities_by_namespace(namespace, res) do lookup_in(mclassdefs, namespace, res)
end

redef class MClassDef
	redef fun mentities_by_namespace(namespace, res) do lookup_in(mpropdefs, namespace, res)
end
