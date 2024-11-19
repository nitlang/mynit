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

# Verify that local variables are initialized before their usage
# Require that the scope and the flow analysis are already performed
module local_var_init

import flow

redef class ToolContext
	# Run `APropdef::do_local_var_init` on each propdef
	var local_var_init_phase: Phase = new LocalVarInitPhase(self, [flow_phase])
end

private class LocalVarInitPhase
	super Phase

	redef fun process_npropdef(npropdef) do npropdef.do_local_var_init(toolcontext)
end

redef class APropdef
	# Entry point of the whole local variable initialization verifier
	fun do_local_var_init(toolcontext: ToolContext)
	do
		var v = new LocalVarInitVisitor(toolcontext)
		v.enter_visit(self)
	end
end

private class LocalVarInitVisitor
	super Visitor

	var toolcontext: ToolContext

	# Local variables that are possibly unset (ie local variable without an initial value)
	var maybe_unset_vars: Set[Variable] = new HashSet[Variable]

	fun mark_is_unset(node: AExpr, variable: nullable Variable)
	do
		assert variable != null
		self.maybe_unset_vars.add(variable)
	end

	fun mark_is_set(node: AExpr, variable: nullable Variable)
	do
		assert variable != null
		if not maybe_unset_vars.has(variable) then return

		var flow = node.after_flow_context
		if flow != null then flow.set_vars.add(variable)
	end

	fun check_is_set(node: AExpr, variable: nullable Variable)
	do
		assert variable != null
		if not maybe_unset_vars.has(variable) then return

		var flow = node.after_flow_context
		if flow != null and not flow.is_variable_set(variable) then
			self.toolcontext.error(node.hot_location, "Error: possibly unset variable `{variable}`.")
			# Remove the variable to avoid repeating errors
			self.maybe_unset_vars.remove(variable)
		end
	end

	redef fun visit(n)
	do
		n.accept_local_var_visitor(self)
	end
end

redef class FlowContext
	private var set_vars: Set[Variable] = new HashSet[Variable]

	private fun is_variable_set(variable: Variable): Bool
	do
		if self.set_vars.has(variable) then return true
		var previous = self.previous
		if previous.length == 0 then return false
		if previous.length == 1 then return previous.first.is_variable_set(variable)
		for p in self.previous do
			if not p.is_variable_set(variable) then
				return false
			end
		end
		# Cache the result
		self.set_vars.add(variable)
		return true
	end
end

redef class ANode
	private fun accept_local_var_visitor(v: LocalVarInitVisitor) do self.visit_all(v)
end

redef class AVardeclExpr
	redef fun accept_local_var_visitor(v)
	do
		super
		# The variable is unset only if there is no initial value.

		# Note: loops in initial value are not a problem
		# Example:
		#
		#     var foo = foo + 1 #-> Error during typing: "self.foo" unknown
		#
		#     var foo
		#     foo = foo + 1 #-> Error here because 'foo' is possibly unset
		if self.n_expr == null then
			v.mark_is_unset(self, self.variable)
		end
	end
end

redef class AVarExpr
	redef fun accept_local_var_visitor(v)
	do
		super
		v.check_is_set(self, self.variable)
	end
end

redef class AVarAssignExpr
	redef fun accept_local_var_visitor(v)
	do
		super
		v.mark_is_set(self, self.variable)
	end
end

redef class AVarReassignExpr
	redef fun accept_local_var_visitor(v)
	do
		super
		v.check_is_set(self, self.variable)
	end
end
