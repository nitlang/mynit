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

# Semantic analysis of a sablecc grammar file
# User to validate the file and generate the grammar and the nfa
#
# TODO: split in submodules
module nitcc_semantic

import nitcc_parser
import grammar
import re2nfa

# Main visitor for the semantic analysis
#
# TODO clean-up the visitors
class CollectNameVisitor
	super Visitor

	var nprods = new Array[Nprod]

	# Symbol table to associate things (prods and exprs) with their name
	var names = new HashMap[String, Node]

	# The associated grammar object
	# Read the result of the visit here
	var gram = new Gram

	# The associated NFA object
	# Read the result of the visit here
	var nfa = new Automaton.empty

	# Run the semantic analysis of the grammar
	fun start(n: Node)
	do
		# First visit to collect names
		enter_visit(n)

		# Second visit to use collectec names and build rhings
		var v2 = new CheckNameVisitor(self)
		v2.enter_visit(n)

		# Inline all the ?
		gram.inline(v2.quesizes.values)
		# Inlile all the prods sufixed by '_imline' #TODO use a real keyword
		for p in gram.prods do
			if not p.name.has_suffix("_inline") then continue
			print "inline {p}"
			gram.inline([p])
		end

		# Build the NFA automaton
		for t in gram.tokens do
			var nfa2 = t.build_nfa
			nfa2.tag_accept(t)
			nfa.absorb(nfa2)
		end

		if not v2.ignoreds.is_empty then
			var ign = new Token("Ignored")
			var nfa2 = new Automaton.empty
			for t in v2.ignoreds do
				assert t isa Token
				var nfa3 = t.build_nfa
				nfa2.alternate(nfa3)
			end
			nfa2.tag_accept(ign)
			nfa.absorb(nfa2)
		end

	end

	redef fun visit(n) do n.accept_collect_prod(self)
end

private class CheckNameVisitor
	super Visitor

	# The collected altname, for the alternative
	var altname: nullable String = null

	# The collected elements, for the alternative
	var elems = new Array[Element]

	# The collected element names, for the alternative
	var elems_names = new Array[nullable String]

	# The collected elementname, for the nelem
	var elemname: nullable String = null

	# Is the alternative transformed, for the alternative
	var trans = false

	# Known ignored tokens
	var ignoreds = new Array[Element]

	# Known rejected tokens
	var rejecteds = new Array[Element]

	# Pool of elements that are modified with + (reuse them!)
	private var plusizes = new HashMap[Element, Production]

	# Create a + version of an element
	fun plusize(e: Element): Production
	do
		if plusizes.has_key(e) then return plusizes[e]
		var name = "{e}+"
		var prod = new Production(name)
		prod.acname = "Nodes[{e.acname}]"
		v1.gram.prods.add(prod)
		prod.new_alt("{name}_one", e)
		prod.new_alt("{name}_more", prod, e)
		plusizes[e] = prod
		return prod
	end

	# Pool of elements that are modified with ? (reuse them!)
	private var quesizes = new HashMap[Element, Production]

	# Create a ? version of an element
	fun quesize(e: Element): Production
	do
		if quesizes.has_key(e) then return quesizes[e]
		var name = "{e}?"
		var prod = new Production(name)
		prod.acname = "nullable {e.acname}"
		v1.gram.prods.add(prod)
		var a1 = prod.new_alt("{name}_one", e)
		a1.codes = [new CodePop]
		var a0 = prod.new_alt0("{name}_none")
		a0.codes = [new CodeNull]
		quesizes[e] = prod
		return prod
	end

	# The current nexpr, used to track dependency on named expressions (see `Nexpr::precs`)
	var nexpr: nullable Nexpr

	# The current production, used to initialize alternatives
	var prod: nullable Production

	# The main visitor, used to access the grammar of the symbol table
	var v1: CollectNameVisitor
	init(v1: CollectNameVisitor) do self.v1 = v1

	redef fun visit(n) do n.accept_check_name_visitor(self)
end

redef class Node
	private fun accept_collect_prod(v: CollectNameVisitor) do visit_children(v)
	private fun accept_check_name_visitor(v: CheckNameVisitor) do visit_children(v)
end

redef class Nexpr
	# The associated token
	var token: nullable Token

	# The associated name
	var name: nullable String

	# The required expression (Nexpr that are used inside)
	var precs = new ArraySet[Nexpr]

	redef fun accept_collect_prod(v) do
		var id = children.first.as(Nid)
		var name = id.text
		if v.names.has_key(name) then
			print "{id.position.to_s} Error {name} already defined."
			exit(1)
		end
		v.names[name] = self
		self.name = name
	end
	redef fun accept_check_name_visitor(v) do
		v.nexpr = self
		super
		v.nexpr = null
	end

	# Flag to track circular regular expression
	var is_building = false

	# The associated NFA (cached, see `build_nfa`)
	private var nfa: nullable Automaton

	# Build the NFA, possibily building the NFA of required expressions
	# Print an error if there is a circular dependency
	# The result is cached
	fun build_nfa: Automaton do
		var res = nfa
		if res != null then return res
		if is_building then
			print "Error: circular regular expression {name.to_s}."
			exit(1)
			abort
		end
		is_building = true
		for p in precs do
			p.build_nfa
		end
		is_building = false
		var nre = self.children[2]
		res = nre.make_rfa
		nfa = res
		return res
	end
end

redef class Nre_id
	# The named expression
	var nexpr: nullable Nexpr
	
	redef fun accept_check_name_visitor(v) do
		var id = children.first.as(Nid)
		var name = id.text
		if not v.v1.names.has_key(name) then
			print "{id.position.to_s} Error: unknown name {name}"
			exit(1)
			abort
		end
		var node = v.v1.names[name]
		if node isa Nprod then
			print "{id.position.to_s} Error: cannot use production {name} in a regular expression"
			exit(1)
			abort
		else if not node isa Nexpr then
			abort
		end
		nexpr = node
		v.nexpr.precs.add(node)
	end

	redef fun make_rfa
	do
		return nexpr.nfa.dup
	end
end

redef class Nign
	redef fun accept_check_name_visitor(v) do
		# Add elements to the ignored list
		v.elems = v.ignoreds
		super
		for e in v.elems do
			if e isa Production then
				print "Error: cannot ignore {e}, it is a production"
				exit(1)
				abort
			else if e isa Token then
				# The token was build and registered during the visit
				# So, unregister then, the bit Ignred token will be build later
				v.v1.gram.tokens.remove(e)
			else
				abort
			end
		end
	end
end

redef class Nrej
	redef fun accept_check_name_visitor(v) do
		# Add elements to the rejected list
		v.elems = v.rejecteds
		super
		for e in v.elems do
			if e isa Production then
				print "Error: cannot reject {e}, it is a production"
				exit(1)
				abort
			else if e isa Token then
				# The token was build and registered during the visit
			else
				abort
			end
		end
	end
end

redef class Nprod
	# The associated production
	var prod: nullable Production

	redef fun accept_collect_prod(v) do
		var id = children.first.as(Nid)
		var name = id.text
		if v.names.has_key(name) then
			print "{id.position.to_s} Error {name} already defined."
			exit(1)
		end
		v.names[name] = self
		v.nprods.add(self)
		prod = new Production(name)
		v.gram.prods.add(prod.as(not null))
	end
	redef fun accept_check_name_visitor(v) do
		v.prod = prod
		super
		v.prod = null
	end
end

redef class Nptrans
	redef fun accept_check_name_visitor(v) do
		var id = children[2].as(Nid)
		var name = id.text

		var node = v.v1.names[name]
		if node isa Nprod then
			v.prod.spe = node.prod.as(not null)
			if v.prod.spe.spe != null then
				print "Cannot transform into {name}, {name} is already transformed."
				exit(1)
				abort
			end
		else if node isa Nexpr then
			print "Cannot transform into {name}, {name} is a token."
		else
			abort
		end
	end
end

redef class Natrans
	redef fun accept_check_name_visitor(v) do
		v.trans = true
	end
end

redef class Alternative
	var short_name: nullable String
end

redef class Nalt
	# The associated alternative
	var alt: nullable Alternative

	redef fun accept_check_name_visitor(v)
	do
		v.altname = null
		v.trans = false
		v.elems = new Array[Element]
		v.elems_names = new Array[nullable String]
		super
		var prod = v.prod.as(not null)
		var prodabs = prod.spe
		if prodabs == null then prodabs = prod
		var name = v.altname
		if name == null then
			if v.trans then
				name = prod.name + "_" + prod.alts.length.to_s
			else if prod.spe == null and prod.alts.is_empty then
				name = prod.name
				prod.altone = true
			else
				if prodabs.altone then
					prodabs.altone = false
					prodabs.alts.first.name = prodabs.name + "_0"
				end
				name = prod.name + "_" + prod.alts.length.to_s
			end
		else
			if prodabs.altone then
				prodabs.altone = false
				prodabs.alts.first.name = prodabs.name + "_0"
			end
			name = prodabs.name + "_" + name
		end
		var alt = prod.new_alt2(name, v.elems)
		alt.short_name = v.altname
		alt.elems_names.add_all(v.elems_names)
		self.alt = alt
		if v.trans then
			alt.trans = true
			alt.codes = [new CodePop]
		end
	end
end

redef class Naltid
	redef fun accept_check_name_visitor(v)
	do
		var id = children[1].as(Nid)
		var name = id.text
		v.altname = name
		var prod = v.prod.as(not null)
		var prodabs = prod.spe
		if prodabs == null then prodabs = prod
		for x in prodabs.alts do
			if x.short_name == name then
				print "{id.position.to_s} Error: already an alternative named {name}"
				exit(1)
			end
		end
	end
end

redef class Nelem
	# The associated element
	var elem: nullable Element

	# Set the element and check things
	private fun set_elem(v: CheckNameVisitor, pos: nullable Position, elem: Element)
	do
		assert self.elem == null
		self.elem = elem
		if elem isa Token then
			if v.ignoreds.has(elem) then
				if pos != null then
					print "{pos} Error: {elem.name} is already an ignored token."
				else
					print "Error: {elem.name} is already an ignored token."
				end
				exit(1)
			end
			if v.rejecteds.has(elem) then
				if pos != null then
					print "{pos} Error: {elem.name} is already a rejected token."
				else
					print "Error: {elem.name} is already a rejected token."
				end
				exit(1)
			end
		end
		v.elems.push(elem)
	end
end

redef class Token
	# The associated expression (if any, ie defined in the lexer part)
	var nexpr: nullable Nexpr
	# The associated text (if any, ie defined in the parser part)
	var text: nullable String

	# Build a NFA according to nexpr or text
	# Does not tag it!
	fun build_nfa: Automaton
	do
		var nexpr = self.nexpr
		if nexpr != null then
			assert self.text == null
			return nexpr.build_nfa
		end
		var text = self.text
		if text != null then
			var nfa = new Automaton.epsilon
			for c in text.chars do
				nfa.concat(new Automaton.atom(c.ascii))
			end
			return nfa
		end
		abort
	end
end

redef class Nnelem
	redef fun accept_check_name_visitor(v)
	do
		v.elemname = null
		super
		var elemname = v.elemname
		if elemname != null and v.elems_names.has(elemname) then
			var i = 2
			while v.elems_names.has(elemname+i.to_s) do i += 1
			elemname = elemname+i.to_s
		end
		v.elems_names.add elemname
	end
end

redef class Nelemid
	redef fun accept_check_name_visitor(v)
	do
		var id = children[1].as(Nid)
		var name = id.text
		for n2 in v.elems_names do
			if name == n2 then
				print "{id.position.to_s} Error: already an element named {name}."
				exit(1)
			end
		end
		v.elemname = name
	end
end

redef class Nelem_id
	redef fun accept_check_name_visitor(v) do
		var id = children.first.as(Nid)
		var name = id.text
		if not v.v1.names.has_key(name) then
			print "{id.position.to_s} Error: unknown name {name}"
			exit(1)
			abort
		end
		var node = v.v1.names[name]
		var elem: nullable Element
		if node isa Nprod then
			elem = node.prod
		else if node isa Nexpr then
			elem = node.token
			if elem == null then
				elem = new Token(name)
				elem.nexpr = node
				v.v1.gram.tokens.add(elem)
				node.token = elem
			end
		else
			abort
		end
		assert elem != null
		set_elem(v, id.position, elem)
		if v.elemname == null then v.elemname = name
	end
end

redef class Nelem_str
	redef fun accept_check_name_visitor(v) do
		var str = children.first.children.first.as(NToken)
		var text = str.value
		var name = str.text
		var elem: nullable Element
		if v.v1.names.has_key(name) then
			elem = v.v1.names[name].as(Nelem_str).elem
			assert elem != null
		else
			elem = new Token(name)
			elem.text = text
			v.v1.gram.tokens.add(elem)
			v.v1.names[name] = self
		end
		set_elem(v, str.position, elem)
	end
end

redef class Nelem_star
	redef fun accept_check_name_visitor(v) do
		super
		var elem = v.elems.pop
		elem = v.plusize(elem)
		elem = v.quesize(elem)
		set_elem(v, null, elem)
	end
end

redef class Nelem_ques
	redef fun accept_check_name_visitor(v) do
		super
		var elem = v.elems.pop
		elem = v.quesize(elem)
		set_elem(v, null, elem)
	end
end

redef class Nelem_plus
	redef fun accept_check_name_visitor(v) do
		super
		var elem = v.elems.pop
		elem = v.plusize(elem)
		set_elem(v, null, elem)
	end
end
