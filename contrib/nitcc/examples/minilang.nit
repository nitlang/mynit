import minilang_test_parser

class Interpretor
	super Visitor
	var stack = new Array[Int]
	var bstack = new Array[Bool]
	var vars = new HashMap[String, Int]

	redef fun visit(n) do n.accept_calculator(self)
end

redef class Node
	fun accept_calculator(v: Interpretor) do visit_children(v)
end

redef class Nint
	redef fun accept_calculator(v) do v.stack.push(text.to_i)
end

redef class Ns_assign
	redef fun accept_calculator(v) do
		super
		v.vars[n_id.text] = v.stack.pop
	end
end

redef class Ns_print
	redef fun accept_calculator(v) do
		super
		printn v.stack.pop
	end
end
redef class Ns_print_str
	redef fun accept_calculator(v) do
		var text = n_str.text
		text = text.substring(1, text.length-2)
		printn text
	end
end
redef class Ns_println
	redef fun accept_calculator(v) do
		print ""
	end
end
redef class Ns_if
	redef fun accept_calculator(v) do
		v.enter_visit(n_c)
		if v.bstack.pop then
			v.enter_visit(n_then)
		else
			var nelse = n_else
			if nelse != null then v.enter_visit(nelse)
		end
	end
end
redef class Ns_while
	redef fun accept_calculator(v) do
		loop
			v.enter_visit(n_c)
			if not v.bstack.pop then break
			v.enter_visit(n_stmts)
		end
	end
end


redef class Nc_and
	redef fun accept_calculator(v) do
		super
		var b1 = v.bstack.pop
		var b2 = v.bstack.pop
		v.bstack.push(b1 and b2)
	end
end

redef class Nc_or
	redef fun accept_calculator(v) do
		super
		var b1 = v.bstack.pop
		var b2 = v.bstack.pop
		v.bstack.push(b1 or b2)
	end
end

redef class Nc_not
	redef fun accept_calculator(v) do
		super
		v.bstack.push(not v.bstack.pop)
	end
end

redef class Nc_eq
	redef fun accept_calculator(v) do
		super
		v.bstack.push(v.stack.pop == v.stack.pop)
	end
end

redef class Nc_ne
	redef fun accept_calculator(v) do
		super
		v.bstack.push(v.stack.pop != v.stack.pop)
	end
end

redef class Nc_lt
	redef fun accept_calculator(v) do
		super
		v.bstack.push(v.stack.pop > v.stack.pop)
	end
end

redef class Nc_le
	redef fun accept_calculator(v) do
		super
		v.bstack.push(v.stack.pop >= v.stack.pop)
	end
end

redef class Nc_gt
	redef fun accept_calculator(v) do
		super
		v.bstack.push(v.stack.pop < v.stack.pop)
	end
end

redef class Nc_ge
	redef fun accept_calculator(v) do
		super
		v.bstack.push(v.stack.pop <= v.stack.pop)
	end
end

redef class Ne_add
	redef fun accept_calculator(v) do
		super
		v.stack.push(v.stack.pop+v.stack.pop)
	end
end
redef class Ne_sub
	redef fun accept_calculator(v) do
		super
		var n1 = v.stack.pop
		v.stack.push(v.stack.pop-n1)
	end
end
redef class Ne_neg
	redef fun accept_calculator(v) do
		super
		v.stack.push(-v.stack.pop)
	end
end
redef class Ne_mul
	redef fun accept_calculator(v) do
		super
		v.stack.push(v.stack.pop*v.stack.pop)
	end
end
redef class Ne_div
	redef fun accept_calculator(v) do
		super
		var n1 = v.stack.pop
		v.stack.push(v.stack.pop/n1)
	end
end
redef class Ne_var
	redef fun accept_calculator(v) do
		v.stack.push v.vars[n_id.text]
	end
end
redef class Ne_read
	redef fun accept_calculator(v) do
		var t = gets
		v.stack.push(t.to_i)
	end
end

var t = new TestParser_minilang
var n = t.main

var v = new Interpretor 
v.enter_visit(n)
