# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2008 Floréal Morandat <morandat@lirmm.fr>
#
# This file is free software, which comes along with NIT.  This software is
# distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without  even  the implied warranty of  MERCHANTABILITY or  FITNESS FOR A 
# PARTICULAR PURPOSE.  You can modify it is you want,  provided this header
# is kept unaltered, and a notification of the changes is added.
# You  are  allowed  to  redistribute it and sell it, alone or is a part of
# another product.

class DummyArray
	super ArrayCapable[Int]
	super Set[Int]
	var _capacity: Int 
	redef readable var _length: Int 
	var _keys: NativeArray[Int]
	var _values: NativeArray[Int]

	redef fun add(value: Int)
	do
		if has(value) then return
		assert full: _length < (_capacity-1)
		var l = _length
		_values[l] = value
		_keys[value] = l
		_length = l + 1
	end

	redef fun remove(value: Int)
	do
		assert not is_empty
		var l = _length
		if l > 1 then
			var last = _values[l - 1]
			var pos = _keys[value]
			_keys[last] = pos
			_values[pos] = last
		end
		_length = l - 1
	end

	redef fun has(value: Int): Bool
	do
		assert value < _capacity
		var pos = _keys[value]
		if pos < _length then
			return _values[pos] == value
		end
		return false
	end

	fun first: Int
	do
		assert _length > 0
		return _values[0]
	end

	redef fun is_empty: Bool
	do
		return not (_length > 0)
	end

	redef fun clear
	do
		_length = 0
	end

	redef fun iterator do return new DummyIterator(self)

	private fun value_at(pos: Int): Int
	do
		return _values[pos]
	end

	init(capacity: Int)
	do
		_capacity = capacity
		_keys = calloc_array(capacity)
		_values = calloc_array(capacity)
	end
end

class DummyIterator
	super CollectionIterator[Int]
	var _array: DummyArray
	var _pos: Int

	redef fun current: Int
	do
		assert has_next
		return _array.value_at(_pos)
	end

	redef fun has_next: Bool
	do
		return _pos < _array.length
	end

	redef fun next do _pos = _pos + 1 end

	init(array: DummyArray)
	do
		_pos = 0
		_array = array
	end
end
