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

# Intraprocedural static flow.
module flow

import scope

redef class ToolContext
	# Run `APropdef::do_flow` on each propdef
	var flow_phase: Phase = new FlowPhase(self, [scope_phase])
end

private class FlowPhase
	super Phase

	redef fun process_npropdef(npropdef) do npropdef.do_flow(toolcontext)
end

# The visitor that determine flowcontext for nodes
private class FlowVisitor
	super Visitor

	var current_flow_context = new FlowContext

	var toolcontext: ToolContext

	init
	do
		flows.add(current_flow_context)
		current_flow_context.is_start = true
	end

	var first: nullable ANode = null

	redef fun visit(node)
	do
		if first == null then first = node

		if current_flow_context.node == null then current_flow_context.node = node
		node.accept_flow_visitor(self)
		if node isa AExpr then
			var flow = self.current_flow_context
			node.after_flow_context = flow
			# Force the creation of a specific merge after the analysis of the node.
			if flow.when_true != flow or flow.when_false != flow then
				self.make_sub_flow
				self.current_flow_context.name = "AUTOSUB"
			end
		end

		if first == node then
			#self.printflow
		end
	end

	fun visit_expr(node: AExpr): FlowContext
	do
		self.enter_visit(node)
		return node.after_flow_context.as(not null)
	end

	var flows = new Array[FlowContext]

	fun printflow
	do
		var file = new FileWriter.open("flow.dot")
		file.write("digraph \{\nnode[shape=box];")
		for f in flows do
			var s = ""
			if f.node isa AExpr then
				s = "\\nmain={f.node.as(AExpr).after_flow_context.object_id}"
			end
			file.write "F{f.object_id} [label=\"{f.object_id}\\n{f.node.location}\\n{f.node.class_name}\\n{f.name}{s}\"];\n"
			for p in f.previous do
				s = ""
				if f.when_true == p then s = "[label=TRUE, style=dotted]"
				if f.when_false == p then s = "[label=FALSE, style=dotted]"
				if f.when_true == p and f.when_false == p then s = "[label=TRUE_FALSE, style=dotted]"
				file.write "F{p.object_id} -> F{f.object_id}{s};\n"
			end
			for p in f.loops do
				file.write "F{p.object_id} -> F{f.object_id}[label=LOOP, style=dashed, constraint=false];\n"
			end
		end
		file.write("\}\n")
		file.close
	end


	fun make_sub_flow: FlowContext
	do
		var flow = new FlowContext
		flows.add(flow)
		flow.node = current_node
		flow.add_previous(self.current_flow_context)
		self.current_flow_context = flow
		return flow
	end

	fun make_merge_flow(flow1, flow2: FlowContext): FlowContext
	do
		var flow = new FlowContext
		flows.add(flow)
		flow.node = current_node
		flow.add_previous(flow1)
		flow.add_previous(flow2)
		self.current_flow_context = flow
		return flow
	end

	fun make_true_false_flow(true_flow, false_flow: FlowContext): FlowContext
	do
		var flow = new FlowContext
		flows.add(flow)
		flow.node = current_node
		flow.add_previous(true_flow)
		flow.add_previous(false_flow)
		flow.when_true = true_flow
		flow.when_false = false_flow
		self.current_flow_context = flow
		return flow
	end

	fun make_sub_true_false_flow: FlowContext
	do
		var orig_flow = self.current_flow_context
		var true_flow = new FlowContext
		flows.add(true_flow)
		true_flow.node = current_node
		true_flow.add_previous(orig_flow)
		true_flow.name = "TRUE"
		var false_flow = new FlowContext
		flows.add(false_flow)
		false_flow.node = current_node
		false_flow.add_previous(orig_flow)
		false_flow.name = "FALSE"
		return make_true_false_flow(true_flow, false_flow)
	end

	fun make_unreachable_flow: FlowContext
	do
		var flow = new FlowContext
		flows.add(flow)
		flow.node = current_node
		flow.add_previous(self.current_flow_context)
		flow.is_marked_unreachable = true
		self.current_flow_context = flow
		return flow
	end

	fun merge_continues_to(before_loop: FlowContext, escapemark: nullable EscapeMark)
	do
		if escapemark == null then return
		for b in escapemark.escapes do
			var before = b.before_flow_context
			if before == null then continue # Forward error
			before_loop.add_loop(before)
		end
	end

	fun merge_breaks(escapemark: nullable EscapeMark)
	do
		if escapemark == null then return
		for b in escapemark.escapes do
			var before = b.before_flow_context
			if before == null then continue # Forward error
			self.make_merge_flow(self.current_flow_context, before)
		end
	end
end

# A Node in the static flow graph.
# A same `FlowContext` can be shared by more than one `ANode`.
class FlowContext
	# The reachable previous flow
	var previous = new Array[FlowContext]

	# Additional reachable flow that loop up to self.
	# Loops appears in `loop`, `while`, `for`, and with `continue`
	var loops = new Array[FlowContext]

	private var is_marked_unreachable: Bool = false

	# Is the flow dead?
	fun is_unreachable: Bool
	do
		# Are we explicitly marked unreachable?
		if self.is_marked_unreachable then return true

		# Are we the starting flow context?
		if is_start then return false

		# De we have a reachable previous?
		if previous.length == 0 then return true
		return false
	end

	# Flag to avoid repeated errors
	var is_already_unreachable: Bool = false

	# Mark that self is the starting flow context.
	# Such a context is reachable even if there is no previous flow
	var is_start: Bool = false

	# The node that introduce the flow (for debugging)
	var node: nullable ANode = null

	# Additional information for the flow (for debugging)
	var name: String = ""

	# The sub-flow to use if the associated expr is true
	var when_true: FlowContext = self

	# The sub-flow to use if the associated expr is true
	var when_false: FlowContext = self

	# Add a previous flow (iff it is reachable)
	private fun add_previous(flow: FlowContext)
	do
		if not flow.is_unreachable and not previous.has(flow) then
			previous.add(flow)
		end
	end

	# Add a previous loop flow (iff it is reachable)
	private fun add_loop(flow: FlowContext)
	do
		if not flow.is_unreachable and not previous.has(flow) then
			loops.add(flow)
		end
	end

end

redef class ANode
	private fun accept_flow_visitor(v: FlowVisitor)
	do
		self.visit_all(v)
	end
end

redef class APropdef
	# The entry point of the whole flow analysis
	fun do_flow(toolcontext: ToolContext)
	do
		var v = new FlowVisitor(toolcontext)
		v.enter_visit(self)
	end


	# The starting flow
	var before_flow_context: nullable FlowContext is noautoinit

	# The ending flow
	var after_flow_context: nullable FlowContext is noautoinit

	redef fun accept_flow_visitor(v)
	do
		self.before_flow_context = v.current_flow_context
		super
		self.after_flow_context = v.current_flow_context
	end
end

redef class AExpr
	# The flow after the full evaluation of the expression/statement
	var after_flow_context: nullable FlowContext
end

redef class AVarAssignExpr
	redef fun accept_flow_visitor(v)
	do
		super
		self.after_flow_context = v.make_sub_flow
	end
end

redef class AReassignFormExpr
	redef fun accept_flow_visitor(v)
	do
		super
		self.after_flow_context = v.make_sub_flow
	end
end

redef class ABlockExpr
	redef fun accept_flow_visitor(v)
	do
		for e in n_expr do
			if not v.current_flow_context.is_unreachable then
				v.enter_visit(e)
			else if not v.current_flow_context.is_already_unreachable then
				v.current_flow_context.is_already_unreachable = true
				v.toolcontext.warning(e.hot_location, "unreachable", "Warning: unreachable statement.")
			end
		end
	end
end

redef class AReturnExpr
	redef fun accept_flow_visitor(v)
	do
		super
		v.make_unreachable_flow
	end
end

redef class AEscapeExpr
	# The flow just before it become unreachable
	fun before_flow_context: nullable FlowContext
	do
		var after = self.after_flow_context
		if after == null then return null
		return after.previous.first
	end
	redef fun accept_flow_visitor(v)
	do
		super
		v.make_unreachable_flow
	end
end

redef class AAbortExpr
	redef fun accept_flow_visitor(v)
	do
		super
		v.make_unreachable_flow
	end
end

redef class ADoExpr
	redef fun accept_flow_visitor(v)
	do
		# FlowContext before the block
		var before_block = v.make_sub_flow

		# Visit the bloc, then merge the breaks
		v.enter_visit(self.n_block)
		v.merge_breaks(self.break_mark)
		var after_block =  v.current_flow_context

		# Visit the catch if there is one
		if self.n_catch != null then
			var before_catch = v.make_sub_flow
			v.make_merge_flow(before_block, after_block)
			v.enter_visit(self.n_catch)
			var after_catch = v.current_flow_context
			v.make_merge_flow(before_catch, after_catch)
		end
	end
end

redef class AIfExpr
	redef fun accept_flow_visitor(v)
	do
		var after_expr = v.visit_expr(self.n_expr)

		v.current_flow_context = after_expr.when_true
		v.enter_visit(self.n_then)
		var after_then = v.current_flow_context

		v.current_flow_context = after_expr.when_false
		v.enter_visit(self.n_else)
		var after_else = v.current_flow_context

		v.make_merge_flow(after_then, after_else)
	end
end

redef class AIfexprExpr
	redef fun accept_flow_visitor(v)
	do
		var after_expr = v.visit_expr(self.n_expr)

		v.current_flow_context = after_expr.when_true
		v.enter_visit(self.n_then)
		var after_then = v.current_flow_context

		v.current_flow_context = after_expr.when_false
		v.enter_visit(self.n_else)
		var after_else = v.current_flow_context

		v.make_merge_flow(after_then, after_else)
	end
end

redef class AWhileExpr
	redef fun accept_flow_visitor(v)
	do
		var before_loop = v.make_sub_flow

		var after_expr = v.visit_expr(self.n_expr)

		v.current_flow_context = after_expr.when_true
		v.enter_visit(self.n_block)
		var after_block = v.current_flow_context

		before_loop.add_loop(after_block)
		v.merge_continues_to(before_loop, self.continue_mark)

		v.current_flow_context = after_expr.when_false
		v.merge_breaks(self.break_mark)
	end
end

redef class ALoopExpr
	redef fun accept_flow_visitor(v)
	do
		var before_loop = v.make_sub_flow

		v.enter_visit(self.n_block)

		var after_block = v.current_flow_context

		before_loop.add_loop(after_block)
		v.merge_continues_to(before_loop, self.continue_mark)

		v.make_unreachable_flow
		v.merge_breaks(self.break_mark)
	end
end

redef class AForExpr
	redef fun accept_flow_visitor(v)
	do
		for g in n_groups do
			v.enter_visit(g.n_expr)
		end

		var before_loop = v.make_sub_flow

		v.enter_visit(self.n_block)

		var after_block = v.current_flow_context

		before_loop.add_loop(after_block)
		v.merge_continues_to(before_loop, self.continue_mark)

		v.make_merge_flow(v.current_flow_context, before_loop)
		v.merge_breaks(self.break_mark)
	end
end

redef class AWithExpr
	redef fun accept_flow_visitor(v)
	do
		super
		v.merge_breaks(self.break_mark)
	end
end

redef class AAssertExpr
	redef fun accept_flow_visitor(v)
	do
		var after_expr = v.visit_expr(self.n_expr)

		v.current_flow_context = after_expr.when_false
		v.enter_visit(n_else)
		# the after context of n_else is a dead end, so we do not care

		v.current_flow_context = after_expr.when_true
	end
end

redef class AOrExpr
	redef fun accept_flow_visitor(v)
	do
		var after_expr = v.visit_expr(self.n_expr)

		v.current_flow_context = after_expr.when_false
		var after_expr2 = v.visit_expr(self.n_expr2)

		var merge_true = v.make_merge_flow(after_expr.when_true, after_expr2.when_true)
		merge_true.name = "OR TRUE"

		v.make_true_false_flow(merge_true, after_expr2.when_false)
	end
end

redef class AImpliesExpr
	redef fun accept_flow_visitor(v)
	do
		var after_expr = v.visit_expr(self.n_expr)

		v.current_flow_context = after_expr.when_true
		var after_expr2 = v.visit_expr(self.n_expr2)

		var merge_true = v.make_merge_flow(after_expr.when_false, after_expr2.when_true)
		merge_true.name = "OR TRUE"

		v.make_true_false_flow(merge_true, after_expr2.when_false)
	end
end

redef class AAndExpr
	redef fun accept_flow_visitor(v)
	do
		var after_expr = v.visit_expr(self.n_expr)

		v.current_flow_context = after_expr.when_true
		var after_expr2 = v.visit_expr(self.n_expr2)

		var merge_false = v.make_merge_flow(after_expr.when_false, after_expr2.when_false)
		merge_false.name = "AND FALSE"

		v.make_true_false_flow(after_expr2.when_true, merge_false)
	end
end

redef class ANotExpr
	redef fun accept_flow_visitor(v)
	do
		var after_expr = v.visit_expr(self.n_expr)

		v.make_true_false_flow(after_expr.when_false, after_expr.when_true)
	end
end

redef class AOrElseExpr
	redef fun accept_flow_visitor(v)
	do
		super
	end
end

redef class AEqExpr
	redef fun accept_flow_visitor(v)
	do
		super
		v.make_sub_true_false_flow
	end
end


redef class ANeExpr
	redef fun accept_flow_visitor(v)
	do
		super
		v.make_sub_true_false_flow
	end
end

redef class AIsaExpr
	redef fun accept_flow_visitor(v)
	do
		super
		v.make_sub_true_false_flow
	end
end

redef class AParExpr
	redef fun accept_flow_visitor(v)
	do
		var after_expr = v.visit_expr(self.n_expr)
		v.current_flow_context = after_expr
	end
end

redef class AOnceExpr
	redef fun accept_flow_visitor(v)
	do
		var after_expr = v.visit_expr(self.n_expr)
		v.current_flow_context = after_expr
	end
end
