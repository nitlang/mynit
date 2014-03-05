# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2004-2009 Jean Privat <jean@pryen.org>
#
# This file is free software, which comes along with NIT.  This software is
# distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without  even  the implied warranty of  MERCHANTABILITY or  FITNESS FOR A
# PARTICULAR PURPOSE.  You can modify it is you want,  provided this header
# is kept unaltered, and a notification of the changes is added.
# You  are  allowed  to  redistribute it and sell it, alone or is a part of
# another product.

# Introduce Hashmap and Hashset.
module hash_collection

import array

# A HashCollection is an array of HashNode[K] indexed by the K hash value
private abstract class HashCollection[K: Object, N: HashNode[Object]]
	super ArrayCapable[nullable N]

	var _array: nullable NativeArray[nullable N] = null # Used to store items
	var _capacity: Int = 0 # Size of _array
	var _length: Int = 0 # Number of items in the map

	readable var _first_item: nullable N = null # First added item (used to visit items in nice order)
	var _last_item: nullable N = null # Last added item (same)

	# The last key accessed (used for cache)
	var _last_accessed_key: nullable K = null

	# The last node accessed (used for cache)
	var _last_accessed_node: nullable N = null

	# Return the index of the key k
	fun index_at(k: K): Int
	do
		var i = k.hash % _capacity
		if i < 0 then i = - i
		return i
	end

	# Return the node assosiated with the key
	fun node_at(k: K): nullable N
	do
		# cache: `is` is used instead of `==` because it is a faster filter (even if not exact)
		if k.is_same_instance(_last_accessed_key) then return _last_accessed_node

		var res = node_at_idx(index_at(k), k)
		_last_accessed_key = k
		_last_accessed_node = res
		return res
	end

	# Return the node assosiated with the key (but with the index already known)
	fun node_at_idx(i: Int, k: K): nullable N
	do
		var c = _array[i]
		while c != null do
			var ck = c._key
			if ck.is_same_instance(k) or ck == k then # FIXME prefilter because the compiler is not smart enought yet
				break
			end
			c = c._next_in_bucklet
		end
		return c
	end

	# Add a new node at a given index
	fun store(index: Int, node: N)
	do
		# Store the item in the list
		if _first_item == null then
			_first_item = node
		else
			_last_item._next_item = node
		end
		node._prev_item = _last_item
		node._next_item = null
		_last_item = node

		# Then store it in the array
		var next = _array[index]
		_array[index] = node
		node._next_in_bucklet = next
		if next != null then next._prev_in_bucklet = node

		_last_accessed_key = node._key
		_last_accessed_node = node

		# Enlarge if needed
		var l = _length
		_length = l + 1
		l = (l + 5) * 3 / 2
		if l >= _capacity then
			enlarge(l * 2)
		end
	end

	# Remove the node assosiated with the key
	fun remove_node(k: K)
	do
		var i = index_at(k)
		var node = node_at_idx(i, k)
		if node == null then return

		# Remove the item in the list
		var prev = node._prev_item
		var next = node._next_item
		if prev != null then
			prev._next_item = next
		else
			_first_item = next
		end
		if next != null then
			next._prev_item = prev
		else
			_last_item = prev
		end

		# Remove the item in the array
		_length -= 1
		prev = node._prev_in_bucklet
		next = node._next_in_bucklet
		if prev != null then
			prev._next_in_bucklet = next
		else
			_array[i] = next
		end
		if next != null then
			next._prev_in_bucklet = prev
		end

		_last_accessed_key = null
	end

	# Clear the whole structure
	fun raz
	do
		var i = _capacity - 1
		while i >= 0 do
			_array[i] = null
			i -= 1
		end
		_length = 0
		_first_item = null
		_last_item = null
		_last_accessed_key = null
	end

	# Force a capacity
	fun enlarge(cap: Int)
	do
		var old_cap = _capacity
		# get a new capacity
		if cap < _length + 1 then cap = _length + 1
		if cap <= _capacity then return
		_capacity = cap
		_last_accessed_key = null

		# get a new array
		var new_array = calloc_array(cap)
		_array = new_array

		# clean the new array
		var i = cap - 1
		while i >=0 do
			new_array[i] = null
			i -= 1
		end

		if _capacity <= old_cap then return

		# Reput items in the array
		var node = _first_item
		while node != null do
			var index = index_at(node._key)
			# Then store it in the array
			var next = new_array[index]
			new_array[index] = node
			node._next_in_bucklet = next
			if next != null then next._prev_in_bucklet = node
			node = node._next_item
		end
	end
end

private abstract class HashNode[K: Object]
	var _key: K
	type N: HashNode[K]
	readable writable var _next_item: nullable N = null
	readable writable var _prev_item: nullable N = null
	var _prev_in_bucklet: nullable N = null
	var _next_in_bucklet: nullable N = null
	init(k: K)
	do
		_key = k
	end
end

# A map implemented with a hash table.
# Keys of such a map cannot be null and require a working `hash` method
class HashMap[K: Object, V]
	super Map[K, V]
	super HashCollection[K, HashMapNode[K, V]]

	redef fun [](key)
	do
		var c = node_at(key)
		if c == null then
			return provide_default_value(key)
		else
			return c._value
		end
	end

	redef fun iterator: HashMapIterator[K, V] do return new HashMapIterator[K,V](self)

	redef fun length do return _length

	redef fun is_empty do return _length == 0

	redef fun []=(key, v)
	do
		var i = index_at(key)
		var c = node_at_idx(i, key)
		if c != null then
			c._key = key
			c._value = v
		else
			store(i, new HashMapNode[K, V](key, v))
		end
	end

	redef fun clear do raz

	init
	do
		_capacity = 0
		_length = 0
		enlarge(0)
	end

	redef var keys: HashMapKeys[K, V] = new HashMapKeys[K, V](self)
	redef var values: HashMapValues[K, V] = new HashMapValues[K, V](self)
end

# View of the keys of a HashMap
class HashMapKeys[K: Object, V]
	super RemovableCollection[K]
	# The original map
	var map: HashMap[K, V]

	redef fun count(k) do if self.has(k) then return 1 else return 0
	redef fun first do return self.map._first_item._key
	redef fun has(k) do return self.map.node_at(k) != null
	redef fun has_only(k) do return (self.has(k) and self.length == 1) or self.is_empty
	redef fun is_empty do return self.map.is_empty
	redef fun length do return self.map.length

	redef fun iterator do return new MapKeysIterator[K, V](self.map.iterator)

	redef fun clear do self.map.clear

	redef fun remove(key) do self.map.remove_node(key)
	redef fun remove_all(key) do self.map.remove_node(key)
end

# View of the values of a Map
class HashMapValues[K: Object, V]
	super RemovableCollection[V]
	# The original map
	var map: HashMap[K, V]

	redef fun count(item)
	do
		var nb = 0
		var c = self.map._first_item
		while c != null do
			if c._value == item then nb += 1
			c = c._next_item
		end
		return nb
	end
	redef fun first do return self.map._first_item._value

	redef fun has(item)
	do
		var c = self.map._first_item
		while c != null do
			if c._value == item then return true
			c = c._next_item
		end
		return false
	end

	redef fun has_only(item)
	do
		var c = self.map._first_item
		while c != null do
			if c._value != item then return false
			c = c._next_item
		end
		return true
	end

	redef fun is_empty do return self.map.is_empty
	redef fun length do return self.map.length

	redef fun iterator do return new MapValuesIterator[K, V](self.map.iterator)

	redef fun clear do self.map.clear

	redef fun remove(item)
	do
		var map = self.map
		var c = map._first_item
		while c != null do
			if c._value == item then
				map.remove_node(c._key)
				return
			end
			c = c._next_item
		end
	end

	redef fun remove_all(item)
	do
		var map = self.map
		var c = map._first_item
		while c != null do
			if c._value == item then
				map.remove_node(c._key)
			end
			c = c._next_item
		end
	end
end

private class HashMapNode[K: Object, V]
	super HashNode[K]
	redef type N: HashMapNode[K, V]
	var _value: V

	init(k: K, v: V)
	do
		super(k)
		_value = v
	end
end

class HashMapIterator[K: Object, V]
	super MapIterator[K, V]
	redef fun is_ok do return _node != null

	redef fun item
	do
		assert is_ok
		return _node._value
	end

	#redef fun item=(value)
	#do
	#	assert is_ok
	#	_node.second = value
	#end

	redef fun key
	do
		assert is_ok
		return _node._key
	end

	redef fun next
	do
		assert is_ok
		_node = _node._next_item
	end

	# The map to iterate on
	var _map: HashMap[K, V]

	# The current node
	var _node: nullable HashMapNode[K, V]

	init(map: HashMap[K, V])
	do
		_map = map
		_node = map.first_item
	end
end

# A `Set` implemented with a hash table.
# Keys of such a map cannot be null and require a working `hash` method
class HashSet[E: Object]
	super Set[E]
	super HashCollection[E, HashSetNode[E]]

	redef fun length do return _length

	redef fun is_empty do return _length == 0

	redef fun first
	do
		assert _length > 0
		return _first_item._key
	end

	redef fun has(item)
	do
		return node_at(item) != null
	end

	redef fun add(item)
	do
		var i = index_at(item)
		var c = node_at_idx(i, item)
		if c != null then
			c._key = item
		else
			store(i,new HashSetNode[E](item))
		end
	end

	redef fun remove(item) do remove_node(item)

	redef fun clear do raz

	redef fun iterator do return new HashSetIterator[E](self)

	init
	do
		_capacity = 0
		_length = 0
		enlarge(0)
	end

	# Build a list filled with the items of `coll`.
	init from(coll: Collection[E]) do
		init
		add_all(coll)
	end
end

private class HashSetNode[E: Object]
	super HashNode[E]
	redef type N: HashSetNode[E]

	init(e: E)
	do
		_key = e
	end
end

class HashSetIterator[E: Object]
	super Iterator[E]
	redef fun is_ok do return _node != null

	redef fun item
	do
		assert is_ok
		return _node._key
	end

	redef fun next
	do
		assert is_ok
		_node = _node._next_item
	end

	# The set to iterate on
	var _set: HashSet[E]

	# The position in the internal map storage
	var _node: nullable HashSetNode[E]

	init(set: HashSet[E])
	do
		_set = set
		_node = set._first_item
	end
end

