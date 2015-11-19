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

# Computing of super-constructors that must be implicitly called at the begin of constructors.
# The current rules are a bit crazy but whatever.
module auto_super_init

import typing
private import annotation

redef class ToolContext
	# Phase that inject `super` in constructors that need it.
	var auto_super_init_phase: Phase = new AutoSuperInitPhase(self, [typing_phase])
end

private class AutoSuperInitPhase
	super Phase
	redef fun process_npropdef(npropdef) do if npropdef isa AMethPropdef then npropdef.do_auto_super_init(toolcontext.modelbuilder)
end

private class AutoSuperInitVisitor
	super Visitor
	redef fun visit(n)
	do
		n.accept_auto_super_init(self)
		n.visit_all(self)
	end

	var has_explicit_super_init: nullable ANode = null

	# The method is broken, so avoid to display additional errors
	var is_broken = false
end


redef class AMethPropdef
	# In case of introduced constructor, the list of implicit auto super init constructors invoked (if needed)
	var auto_super_inits: nullable Array[CallSite] = null

	# In case of redefined constructors, is an implicit call-to-super required?
	var auto_super_call = false

	# Collect initializers and build the auto-init
	fun do_auto_super_init(modelbuilder: ModelBuilder)
	do
		var mclassdef = self.parent.as(AClassdef).mclassdef
		if mclassdef == null or mclassdef.is_broken then return # skip error
		var mpropdef = self.mpropdef
		if mpropdef == null or mpropdef.is_broken then return # skip error
		var mmodule = mpropdef.mclassdef.mmodule
		var anchor = mclassdef.bound_mtype
		var recvtype = mclassdef.mclass.mclass_type

		# Get the annotation, but check its pertinence before returning
		var nosuper = get_single_annotation("nosuper", modelbuilder)

		# Collect only for constructors
		if not mpropdef.mproperty.is_init or mpropdef.mproperty.is_new then
			if nosuper != null then modelbuilder.error(nosuper, "Error: `nosuper` only allowed in `init`.")
			return
		end

		# Now we search for the absence of any explicit super-init invocation
		#  * via a "super"
		#  * via a call of an other init
		var nblock = self.n_block
		if nblock != null then
			var v = new AutoSuperInitVisitor
			v.enter_visit(nblock)
			var anode = v.has_explicit_super_init
			if anode != null then
				if nosuper != null then modelbuilder.error(anode, "Error: method is annotated `nosuper` but a super-constructor call is present.")
				return
			end
			if v.is_broken then return # skip
		end

		if nosuper != null then return

		# Still here? So it means that we must add an implicit super-call on redefinitions.
		if not mpropdef.is_intro then
			auto_super_call = true
			mpropdef.has_supercall = true
			modelbuilder.toolcontext.info("Auto-super call for {mpropdef}", 4)
			return
		end

		# Still here? So it means that we must determine what super inits need to be automatically invoked
		# The code that follow is required to deal with complex cases with old-style and new-style inits

		# Look for old-style super constructors
		var auto_super_inits = new Array[CallSite]
		for msupertype in mclassdef.supertypes do
			# FIXME: the order is quite arbitrary
			if not msupertype.mclass.kind.need_init then continue
			msupertype = msupertype.anchor_to(mmodule, mclassdef.bound_mtype)
			var candidate = modelbuilder.try_get_mproperty_by_name2(self, mmodule, msupertype, mpropdef.mproperty.name)
			if candidate == null then
				candidate = modelbuilder.try_get_mproperty_by_name2(self, mmodule, msupertype, "init")
			end
			if candidate == null then
				modelbuilder.error(self, "Error: cannot do an implicit constructor call in `{mpropdef}`; there is no constructor named `{mpropdef.mproperty.name}` in `{msupertype}`.")
				return
			end
			assert candidate isa MMethod

			# Skip new-style init
			if candidate.is_root_init then continue

			var candidatedefs = candidate.lookup_definitions(mmodule, anchor)
			if candidatedefs.is_empty then
				# skip broken
				is_broken = true
				return
			end
			var candidatedef = candidatedefs.first
			# TODO, we drop the others propdefs in the callsite, that is not great :(

			var msignature = candidatedef.new_msignature or else candidatedef.msignature
			msignature = msignature.resolve_for(recvtype, anchor, mmodule, true)

			var callsite = new CallSite(hot_location, recvtype, mmodule, anchor, true, candidate, candidatedef, msignature, false)
			auto_super_inits.add(callsite)
			modelbuilder.toolcontext.info("Old-style auto-super init for {mpropdef} to {candidate.full_name}", 4)
		end

		# No old style? The look for new-style super constructors (called from a old style constructor)
		var the_root_init_mmethod = modelbuilder.the_root_init_mmethod
		if the_root_init_mmethod != null and auto_super_inits.is_empty then
			var candidatedefs = the_root_init_mmethod.lookup_definitions(mmodule, anchor)
			if candidatedefs.is_empty then
				# skip broken
				is_broken = true
				return
			end

			# Search the longest-one and checks for conflict
			var candidatedef = candidatedefs.first
			if candidatedefs.length > 1 then
				# Check for conflict in the order of initializers
				# Each initializer list must me a prefix of the longest list
				# part 1. find the longest list
				for spd in candidatedefs do
					if spd.initializers.length > candidatedef.initializers.length then candidatedef = spd
				end
				# compare
				for spd in candidatedefs do
					var i = 0
					for p in spd.initializers do
						if p != candidatedef.initializers[i] then
							modelbuilder.error(self, "Error: cannot do an implicit constructor call to conflicting inherited inits `{spd}({spd.initializers.join(", ")}`) and `{candidatedef}({candidatedef.initializers.join(", ")}`). NOTE: Do not mix old-style and new-style init!")
							return
						end
						i += 1
					end
				end
			end

			var msignature = candidatedef.new_msignature or else candidatedef.msignature
			msignature = msignature.resolve_for(recvtype, anchor, mmodule, true)

			var callsite = new CallSite(hot_location, recvtype, mmodule, anchor, true, the_root_init_mmethod, candidatedef, msignature, false)
			auto_super_inits.add(callsite)
			modelbuilder.toolcontext.info("Auto-super init for {mpropdef} to {the_root_init_mmethod.full_name}", 4)
		end
		if auto_super_inits.is_empty then
			modelbuilder.error(self, "Error: no constructors to call implicitly in `{mpropdef}`. Call one explicitly.")
			return
		end

		# Can the super-constructors be called?
		for auto_super_init in auto_super_inits do
			var auto_super_init_def = auto_super_init.mpropdef
			var msig = mpropdef.msignature.as(not null)
			var supermsig = auto_super_init.msignature
			if supermsig.arity > msig.arity then
				modelbuilder.error(self, "Error: cannot do an implicit constructor call to `{auto_super_init_def}{supermsig}`. Expected at least `{supermsig.arity}` arguments, got `{msig.arity}`.")
				continue
			end
			var i = 0
			for sp in supermsig.mparameters do
				var p = msig.mparameters[i]
				var sub = p.mtype
				var sup = sp.mtype
				if not sub.is_subtype(mmodule, anchor, sup) then
					modelbuilder.error(self, "Error: cannot do an implicit constructor call to `{auto_super_init_def}{supermsig}`. Expected argument #{i} of type `{sp.mtype}`, got implicit argument `{p.name}` of type `{p.mtype}`.")
					break
				end
				i += 1
			end
		end
		self.auto_super_inits = auto_super_inits
	end

end

redef class ANode
	private fun accept_auto_super_init(v: AutoSuperInitVisitor) do end
end


redef class ASendExpr
	redef fun accept_auto_super_init(v)
	do
		var callsite = self.callsite
		if callsite == null then
			v.is_broken = true
			return
		end
		if callsite.mproperty.is_init then
			v.has_explicit_super_init = self
		end
	end
end

redef class ASuperExpr
	redef fun accept_auto_super_init(v)
	do
		# If the super is a standard call-next-method then there it is considered am explicit super init call
		# The the super is a "super int" then it is also an explicit super init call
		v.has_explicit_super_init = self
	end
end
