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

# Modelisation of a Nit package
module mpackage

import model_base
private import more_collections
import poset
import mdoc

# A Nit package, that encompass a product
class MPackage
	super MConcern

	# The name of the package
	redef var name: String

	redef fun full_name do return name

	redef var c_name = name.to_cmangle is lazy

	# The model of the package
	redef var model: Model

	# The root of the group tree
	var root: nullable MGroup = null is writable

	# The group tree, as a POSet
	var mgroups = new POSet[MGroup]

	redef fun to_s do return name

	init
	do
		model.mpackages.add(self)
		model.mpackage_by_name.add_one(name, self)
	end

	# MPackage are always roots of the concerns hierarchy
	redef fun parent_concern do return null

	redef fun mdoc_or_fallback
	do
		if mdoc != null then return mdoc
		return root.mdoc_or_fallback
	end
end

# A group of modules in a package
class MGroup
	super MConcern

	# The name of the group
	# empty name for a default group in a single-module package
	redef var name: String

	# The enclosing package
	var mpackage: MPackage

	# The parent group if any
	# see `in_nesting` for more
	var parent: nullable MGroup

	# Fully qualified name.
	# It includes each parent group separated by `/`
	redef fun full_name
	do
		var p = parent
		if p == null then return name
		return "{p.full_name}/{name}"
	end

	# The group is the group tree on the package (`mpackage.mgroups`)
	# nested groups (children) are smaller
	# nesting group (see `parent`) is bigger
	var in_nesting: POSetElement[MGroup] is noinit

	# Is `self` the root of its package?
	fun is_root: Bool do return mpackage.root == self

	# The filepath (usually a directory) of the group, if any
	var filepath: nullable String = null is writable

	init
	do
		var tree = mpackage.mgroups
		self.in_nesting = tree.add_node(self)
		var parent = self.parent
		if parent != null then
			tree.add_edge(self, parent)
		end
	end

	redef fun model do return mpackage.model

	redef fun parent_concern do
		if not is_root then return parent
		return mpackage
	end

	redef fun to_s do return name
end

redef class Model
	# packages of the model
	var mpackages = new Array[MPackage]

	# Collections of package grouped by their names
	private var mpackage_by_name = new MultiHashMap[String, MPackage]

	# Return all package named `name`
	# If such a package is not yet loaded, null is returned (instead of an empty array)
	fun get_mpackages_by_name(name: String): nullable Array[MPackage]
	do
		if mpackage_by_name.has_key(name) then
			return mpackage_by_name[name]
		else
			return null
		end
	end
end
