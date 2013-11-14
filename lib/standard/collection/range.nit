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

# Module for range of discrete objects.
module range

import abstract_collection

# Range of discrete objects.
class Range[E: Discrete]
	super Collection[E]

	redef readable var _first: E

	# Get the last element.
	readable var _last: E

	# Get the element after the last one.
	readable var _after: E

	redef fun has(item) do return item >= _first and item <= _last

	redef fun has_only(item) do return _first == item and item == _last or is_empty

	redef fun count(item)
	do
		if has(item) then
			return 1
		else
			return 0
		end
	end

	redef fun iterator do return new IteratorRange[E](self)

	redef fun iterate
		!each(e: E)
	do
		var c = _first
		var l = _last
		while c <= l do
			each(c)
			c = c.succ
		end
	end

	redef fun length
	do
		var nb = _first.distance(_after)
		if nb > 0 then
			return nb
		else
			return 0
		end
	end

	redef fun is_empty do return _first >= _after

	# Create a range [`from`, `to`].
	# The syntax `[from..to[` is equivalent.
	init(from: E, to: E)
	do
		_first = from
		_last = to
		_after = to.succ
	end

	# Create a range [`from`, `to`[.
	# The syntax `[from..to[` is equivalent.
	init without_last(from: E, to: E)
	do
		_first = from
		_last = to.prec
		_after = to
	end
end

class IteratorRange[E: Discrete]
	# Iterator on ranges.
	super Iterator[E]
	var _range: Range[E]
	redef readable var _item: E

	redef fun is_ok do return _item < _range.after
	
	redef fun next do _item = _item.succ
	
	init(r: Range[E])
	do
		_range = r
		_item = r.first
	end
end

redef class Discrete
	# Returns the range from 0 to `self-1`, is used to do:
	#
	#    for i in 3.times do print "Cool"
	#    for i in 100.times do print "{i}/100"
	fun times: Range[OTHER] do return new Range[OTHER](0, self-1)
end
