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
module list

import abstract_collection

# Double linked lists.
class List[E]
	super Sequence[E]
# Access
	redef fun [](index) do return get_node(index).item

	redef fun []=(index, item) do get_node(index).item = item

	# O(1)
	redef fun first do return _head.item

	# O(1)
	redef fun first=(e) do _head.item = e

	# O(1)
	redef fun last do return _tail.item

	# O(1)
	redef fun last=(e) do _tail.item = e

# Queries

	# O(1)
	redef fun is_empty do return _head == null

	# O(n)
	redef fun length
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
	redef fun has(e) do return search_node_after(e, _head) != null

	redef fun has_only(e)
	do
		var node = _head
		while node != null do
			if node.item != e then return false
			node = node.next
		end
		return true
	end

	redef fun count(e)
	do
		var nb = 0
		var node = _head
		while node != null do
			if node.item != e then nb += 1
			node = node.next
		end
		return nb
	end

	# Return a list of elements between 'from' and 'to'.
	fun slice(from: Int, to: Int): List[E] do
		assert from >= 0 and from < length
		assert to >= 0 and to < length and from <= to
		var list = new List[E]
		while from <= to do
			list.add(self[from])
			from += 1
		end
		return list
	end

# Add elements

	# O(1)
	redef fun push(e)
	do
		var node = new ListNode[E](e)
		if _tail == null then
			_head = node
		else
			_tail.next = node
			node.prev = _tail
		end
		_tail = node
		_protection.kill_canary
	end

	# O(1)
	redef fun unshift(e)
	do
		var node = new ListNode[E](e)
		if _head == null then
			_tail = node
		else
			node.next = _head
			_head.prev = node
		end
		_head = node
		_protection.kill_canary
	end

	# O(n)
	redef fun insert(e, i)
	do
		var node = get_node(i)
		if node == null then
			push(e)
			return
		end
		var nnode = new ListNode[E](e)
		var next = node.next
		if next == null then
			_tail = nnode
		else
			next.prev = nnode
		end
		nnode.prev = node
		nnode.next = next
		node.next = nnode
		_protection.kill_canary
	end

	# Append `l` to `self` but clear `l`.
	##
	# O(1)
	fun link(l: List[E])
	do
		if _tail == null then
			_head = l._head
		else if l._head != null then
			_tail.next = l._head
			_tail.next.prev = _tail
		end
		_tail = l._tail
		l.clear
		_protection.kill_canary
		l._protection.kill_canary
	end

# Remove elements

	# O(1)
	redef fun pop
	do
		var node = _tail
		_tail = node.prev
		node.prev = null
		if _tail == null then
			_head = null
		else
			_tail.next = null
		end
		_protection.kill_canary
		return node.item
	end

	# O(1)
	redef fun shift
	do
		var node = _head
		_head = node.next
		node.next = null
		if _head == null then
			_tail = null
		else
			_head.prev = null
		end
		_protection.kill_canary
		return node.item
	end

	redef fun remove(e)
	do
		var node = search_node_after(e, _head)
		if node != null then remove_node(node)
	end

	redef fun remove_at(i)
	do
		var node = get_node(i)
		if node != null then remove_node(node)
	end

	redef fun clear
	do
		_head = null
		_tail = null
		_protection.kill_canary
	end


	redef fun iterator: ListIterator[E] do return new ListIterator[E](self)

	# Build an empty list.
	init do end
	
	# Build a list filled with the items of `coll`.
	init from(coll: Collection[E]) do append(coll)

	# The first node of the list
	var _head: nullable ListNode[E]

	# The last node of the list
	var _tail: nullable ListNode[E]

	# Track the validity of iterators
	var _protection = new CanaryProtection

	# Get the `i`th node. get `null` otherwise.
	private fun get_node(i: Int): nullable ListNode[E]
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

	# get the first node that contains `e` after 'after', null otherwise
	private fun search_node_after(e: E, after: nullable ListNode[E]): nullable ListNode[E]
	do
		var n = after
		while n != null and n.item != e do n = n.next
		return n
	end

	# Remove the node (ie. atach prev and next)
	private fun remove_node(node: ListNode[E])
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
		_protection.kill_canary
	end

	private fun insert_before(element: E, node: ListNode[E])
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
		_protection.kill_canary
	end
end

# This is the iterator class of List
class ListIterator[E]
	super IndexedIterator[E]
	redef fun item do
		assert iterator_still_valid: _canary.item
		return _node.item
	end

	fun item=(e: E)
	do
		assert iterator_still_valid: _canary.item
		_node.item = e
	end

	redef fun is_ok
	do
		assert iterator_still_valid: _canary.item
		return not _node == null
	end

	redef fun next
	do
		assert iterator_still_valid: _canary.item
		_node = _node.next
		_index += 1
	end

	# Track the validity
	var _canary: Container[Bool]

	redef fun is_still_valid do return _canary.item

	# Build a new iterator for `list`.
	private init(list: List[E])
	do
		_canary = list._protection.get_canary
		_list = list
		_node = list._head
		_index = 0
	end

	# The current list
	var _list: List[E]

	# The current node of the list
	var _node: nullable ListNode[E]

	# The index of the current node
	redef readable var _index: Int

	# Remove the current item
	fun delete
	do
		assert iterator_still_valid: _canary.item
		_list.remove_node(_node.as(not null))
		_canary = _list._protection.get_canary
	end

	# Insert before the current item
	fun insert_before(element: E)
	do
		assert iterator_still_valid: _canary.item
		_list.insert_before(element, _node.as(not null))
		_canary = _list._protection.get_canary
	end
end

# Linked nodes that constitute a linked list.
private class ListNode[E]
	super Container[E]
	init(i: E)
	do 
		item = i
	end

	# The next node.
	readable writable var _next: nullable ListNode[E]

	# The previous node.
	readable writable var _prev: nullable ListNode[E]
end
