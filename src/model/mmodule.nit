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

# modules and module hierarchies in the metamodel
module mmodule

import poset
import location
import model_base
private import more_collections

# The container class of a Nit object-oriented model.
# A model knows modules, classes and properties and can retrieve them.
redef class Model
	# All known modules
	var mmodules: Array[MModule] = new Array[MModule]

	# Module nesting hierarchy.
	# where mainmodule < mainmodule::nestedmodule
	var mmodule_nesting_hierarchy: POSet[MModule] = new POSet[MModule]

	# Full module importation hierarchy including private or nested links.
	var mmodule_importation_hierarchy: POSet[MModule] = new POSet[MModule]

	# Collections of modules grouped by their short names
	private var mmodules_by_name: MultiHashMap[String, MModule] = new MultiHashMap[String, MModule]

	# Return all module named `name`
	# If such a module does not exist, null is returned (instead of an empty array)
	#
	# Visibility or modules are not considered
	fun get_mmodules_by_name(name: String): nullable Array[MModule]
	do
		if mmodules_by_name.has_key(name) then
			return mmodules_by_name[name]
		else
			return null
		end
	end
end

# A Nit module is usually associated with a Nit source file.
# Modules can be nested (see `direct_owner`, `public_owner`, and `in_nesting`)
class MModule
	# The model considered
	var model: Model

	# The direct nesting module, return null if self is not nested (ie. is a top-level module)
	var direct_owner: nullable MModule

	# The short name of the module
	var name: String

	# The origin of the definition
	var location: Location

	# Alias for `name`
	redef fun to_s do return self.name

	# The view of the module in the `model.mmodule_nesting_hierarchy`
	var in_nesting: POSetElement[MModule]

	# The view of the module in the `model.mmodule_importation_hierarchy`
	var in_importation: POSetElement[MModule]

	# The canonical name of the module
	# Example: `"owner::name"`
	fun full_name: String
	do
		var owner = self.public_owner
		if owner == null then
			return self.name
		else
			return "{owner.full_name}::{self.name}"
		end
	end

	# Create a new empty module and register it to a model
	# `direct_owner` is the direct owner (null if top-level module)
	init(model: Model, direct_owner: nullable MModule, name: String, location: Location)
	do
		self.model = model
		self.name = name
		self.location = location
		model.mmodules_by_name.add_one(name, self)
		model.mmodules.add(self)
		self.in_nesting = model.mmodule_nesting_hierarchy.add_node(self)
		self.direct_owner = direct_owner
		if direct_owner != null then
			model.mmodule_nesting_hierarchy.add_edge(direct_owner, self)
		end
		self.in_importation = model.mmodule_importation_hierarchy.add_node(self)
	end

	# Register the imported modules (ie "import some_module")
	# This function can only invoked once by mmodule.
	# The visibility must be set with `set_visibility_for`.
	fun set_imported_mmodules(imported_mmodules: Array[MModule])
	do
		assert unique_invocation: self.in_importation.direct_greaters.is_empty
		for m in imported_mmodules do
			self.model.mmodule_importation_hierarchy.add_edge(self, m)
		end
	end

	private var intrude_mmodules: HashSet[MModule] = new HashSet[MModule]
	private var public_mmodules: HashSet[MModule] = new HashSet[MModule]
	private var private_mmodules: HashSet[MModule] = new HashSet[MModule]

	# Return the visibility level of an imported module `m`
	fun visibility_for(m: MModule): MVisibility
	do
		if m == self then return intrude_visibility
		if self.intrude_mmodules.has(m) then return intrude_visibility
		if self.public_mmodules.has(m) then return public_visibility
		if self.private_mmodules.has(m) then return private_visibility
		return none_visibility
	end

	# Set the visibility of an imported module
	# REQUIRE: the visibility of the modules imported by `m` are already set for `m`
	fun set_visibility_for(m: MModule, v: MVisibility)
	do
		if v == intrude_visibility then
			self.intrude_mmodules.add(m)
			self.intrude_mmodules.add_all(m.intrude_mmodules)
			self.public_mmodules.add_all(m.public_mmodules)
			self.private_mmodules.add_all(m.private_mmodules)
		else if v == public_visibility then
			self.public_mmodules.add(m)
			self.public_mmodules.add_all(m.intrude_mmodules)
			self.public_mmodules.add_all(m.public_mmodules)
		else if v == private_visibility then
			self.private_mmodules.add(m)
			self.private_mmodules.add_all(m.intrude_mmodules)
			self.private_mmodules.add_all(m.public_mmodules)
		else
			print "{self} visibility for {m} = {v}"
			abort # invalid visibility
		end
	end

	# The first module in the nesting hierarchy to export self as public
	# This function is used to determine the canonical name of modules, classes and properties.
	# REQUIRE: the visibility of all nesting modules is already set.
	fun public_owner: nullable MModule
	do
		var res = self.direct_owner
		var last = res
		while last != null do
			if last.visibility_for(self) >= public_visibility then res = last
			last = last.direct_owner
		end
		return res
	end

	# Return true if a class or a property introduced in `intro_mmodule` with a visibility of `visibility` is visible in self.
	fun is_visible(intro_mmodule: MModule, visibility: MVisibility): Bool
	do
		var v = visibility_for(intro_mmodule)
		if v == intrude_visibility then
			return visibility >= private_visibility
		else if v == public_visibility then
			return visibility > private_visibility
		else if v == private_visibility then
			return visibility > private_visibility
		else if v == none_visibility then
			return false
		else
			abort
		end
	end
end
