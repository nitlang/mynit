# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2004-2008 Jean Privat <jean@pryen.org>
#
# This file is free software, which comes along with NIT.  This software is
# distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without  even  the implied warranty of  MERCHANTABILITY or  FITNESS FOR A 
# PARTICULAR PURPOSE.  You can modify it is you want,  provided this header
# is kept unaltered, and a notification of the changes is added.
# You  are  allowed  to  redistribute it and sell it, alone or is a part of
# another product.

# This module handle double linked lists
package list

import abstract_collection

# Double linked lists.
class List[E]
special IndexedCollection[E]
# Access
	redef meth [](index) do return get_node(index).item

	redef meth []=(index, item) do get_node(index).item = item

	# O(1)
	redef meth first do return _head.item

	# O(1)
	redef meth first=(e) do _head.item = e

	# O(1)
	redef meth last do return _tail.item

	# O(1)
	redef meth last=(e) do _tail.item = e

# Queries

	# O(1)
	redef meth is_empty do return _head == null

	# O(n)
	redef meth length
	do
		var l = 0
		var t = _head
		while t != null do
			l += 1
			t = t.next 
		end
		return l      
	end

	# O(n)
	redef meth has(e) do return search_node_after(e, _head) != null

	redef meth has_only(e)
	do
		var node = _head
		while node != null do
			if node.item != e then return false
			node = node.next
		end
		return true
	end

	redef meth count(e)
	do
		var nb = 0
		var node = _head
		while node != null do
			if node.item != e then nb += 1
			node = node.next
		end
		return nb
	end

	redef meth has_key(index) do return get_node(index) != null

# Add elements

	# O(1)
	redef meth push(e)
	do
		var node = new ListNode[E](e)
		if _tail == null then
			_head = node
		else
			_tail.next = node
			node.prev = _tail
		end
		_tail = node
	end

	# O(1)
	redef meth unshift(e)
	do
		var node = new ListNode[E](e)
		if _head == null then
			_tail = node
		else
			node.next = _head
			_head.prev = node
		end
		_head = node
	end

	# Append `l' to `self' but clear `l'.
	##
	# O(1)
	meth link(l: List[E])
	do
		if _tail == null then
			_head = l._head
		else if l._head != null then
			_tail.next = l._head
			_tail.next.prev = _tail
		end
		_tail = l._tail
		l.clear
	end

# Remove elements

	# O(1)
	redef meth pop
	do
		var node = _tail
		_tail = node.prev
		node.prev = null
		if _tail == null then
			_head = null
		else
			_tail.next = null
		end
		return node.item
	end

	# O(1)
	redef meth shift
	do
		var node = _head
		_head = node.next
		node.next = null
		if _head == null then
			_tail = null
		else
			_head.prev = null
		end
		return node.item
	end

	redef meth remove(e)
	do
		var node = search_node_after(e, _head)
		if node != null then remove_node(node)
	end

	redef meth remove_at(i)
	do
		var node = get_node(i)
		if node != null then remove_node(node)
	end

	redef meth clear
	do
		_head = null
		_tail = null
	end


	redef meth iterator: ListIterator[E] do return new ListIterator[E](_head)

	# Build an empty list.
	init do end
	
	# Build a list filled with the items of `coll'.
	init from(coll: Collection[E]) do append(coll)

	# The first node of the list
	attr _head: nullable ListNode[E]

	# The last node of the list
	attr _tail: nullable ListNode[E]

	# Get the `i'th node. get `null' otherwise.
	private meth get_node(i: Int): nullable ListNode[E]
	do
		var n = _head
		if i < 0 then
			return null
		end
		while n != null and i > 0 do
			n = n.next
			i -= 1
		end
		return n 
	end

	# get the first node that contains e after 'after', null otherwise
	private meth search_node_after(e: E, after: nullable ListNode[E]): nullable ListNode[E]
	do
		var n = after
		while n != null and n.item != e do n = n.next
		return n
	end

	# Remove the node (ie. atach prev and next)
	private meth remove_node(node: ListNode[E])
	do
		if node.prev == null then
			_head = node.next
			if node.next == null then
				_tail = null
			else
				node.next.prev = null
			end
		else if node.next == null then
			_tail = node.prev
			node.prev.next = null
		else
			node.prev.next = node.next
			node.next.prev = node.prev
		end
	end

	private meth insert_before(element: E, node: ListNode[E])
	do
		var nnode = new ListNode[E](element)
		var prev = node.prev
		if prev == null then
			_head = nnode
		else
			prev.next = nnode
		end
		nnode.prev = prev
		nnode.next = node
		node.prev = nnode
	end
end

# This is the iterator class of List
class ListIterator[E]
special IndexedIterator[E]
	redef meth item do return _node.item

	# redef meth item=(e) do _node.item = e

	redef meth is_ok do return not _node == null

	redef meth next
	do
		_node = _node.next
		_index += 1
	end

	# Build a new iterator from `node'.
	private init(node: nullable ListNode[E])
	do
		_node = node
		_index = 0
	end

	# The current node of the list
	attr _node: nullable ListNode[E]

	# The index of the current node
	redef readable attr _index: Int
end

# Linked nodes that constitute a linked list.
private class ListNode[E]
special Container[E]
	init(i: E)
	do 
		item = i
	end

	# The next node.
	readable writable attr _next: nullable ListNode[E]

	# The previous node.
	readable writable attr _prev: nullable ListNode[E]
end
