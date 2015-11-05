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

# Computes importation and class hierarchy lists.
module doc_hierarchies

import doc_structure
import doc_poset

# Insert inheritance / importation lists in the page.
class InheritanceListsPhase
	super DocPhase

	# Used to sort list by name.
	var name_sorter = new MEntityNameSorter

	redef fun apply do
		for page in doc.pages.values do
			if page isa MEntityPage then page.build_inh_list(self, doc)
		end
	end
end

redef class MEntityPage

	# Build importation / inheritance list for this page.
	fun build_inh_list(v: InheritanceListsPhase, doc: DocModel) do end
end

redef class MModulePage
	redef fun build_inh_list(v, doc) do
		var id = mentity.nitdoc_id
		var section = new TabbedGroup("{id}.importation", "Dependencies")
		var group = new PanelGroup("list.group", "List")
		var imports = self.imports.to_a
		v.name_sorter.sort(imports)
		group.add_child new MEntitiesListArticle("{id}.imports", "Imports", imports)
		var clients = self.clients.to_a
		v.name_sorter.sort(clients)
		group.add_child new MEntitiesListArticle("{id}.clients", "Clients", clients)
		section.add_child group
		section.parent = root.children.first
		root.children.first.children.insert(section, 1)
	end
end

redef class MClassPage
	redef fun build_inh_list(v, doc) do
		var id = mentity.nitdoc_id
		var section = new TabbedGroup("{id}.inheritance", "Inheritance")
		var group = new PanelGroup("list.group", "List")
		var parents = self.parents.to_a
		v.name_sorter.sort(parents)
		group.add_child new MEntitiesListArticle("{id}.parents", "Parents", parents)
		var ancestors = self.ancestors.to_a
		v.name_sorter.sort(ancestors)
		group.add_child new MEntitiesListArticle("{id}.ancestors", "Ancestors", ancestors)
		var children = self.children.to_a
		v.name_sorter.sort(children)
		group.add_child new MEntitiesListArticle("{id}.children", "Children", children)
		var descendants = self.descendants.to_a
		v.name_sorter.sort(descendants)
		group.add_child new MEntitiesListArticle("{id}.descendants", "Descendants", descendants)
		section.add_child group
		section.parent = root.children.first
		root.children.first.children.insert(section, 1)
	end
end
