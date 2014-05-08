# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2005-2008 Jean Privat <jean@pryen.org>
#
# This file is free software, which comes along with NIT.  This software is
# distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without  even  the implied warranty of  MERCHANTABILITY or  FITNESS FOR A
# PARTICULAR PURPOSE.  You can modify it is you want,  provided this header
# is kept unaltered, and a notification of the changes is added.
# You  are  allowed  to  redistribute it and sell it, alone or is a part of
# another product.

# This module contains classes used to sorts arrays.
# In order to provide your own sort class you should define a subclass of `Comparator` with
# a custom `Comparator::compare` function.
module sorter

import range
import array

# This abstract class generalizes ways to sort an array
interface Comparator[E]
	# Compare `a` and `b`.
	# Returns:
	#	-1 if a < b
	#	0  if a = b
	#	1  if a > b
	fun compare(a: E, b: E): Int is abstract

	# Sort `array` using the `compare` function.
	#
	#     var s = new DefaultComparator[Int]
	#     var a = [5, 2, 3, 1, 4]
	#     s.sort(a)
	#     assert a == [1, 2, 3, 4, 5]
	fun sort(array: Array[E]) do sub_sort(array, 0, array.length-1)

	# Sort `array` between `from` and `to` indices
	private fun sub_sort(array: Array[E], from: Int, to: Int)
	do
		if from >= to then
			return
		else if from + 7 < to then
			quick_sort(array, from, to)
		else
			bubble_sort(array, from, to)
		end
	end

	# Quick-sort `array` between `from` and `to` indices
	# Worst case: O(n^2), Average case: O(n lg n)
	#
	#     var s = new DefaultComparator[Int]
	#     var a = [5, 2, 3, 1, 4]
	#     s.quick_sort(a, 0, a.length - 1)
	#     assert a == [1, 2, 3, 4, 5]
	fun quick_sort(array: Array[E], from: Int, to: Int) do
		var pivot = array[from]
		var i = from
		var j = to
		while j > i do
			while i <= to and compare(array[i], pivot) <= 0 do i += 1
			while j > i and compare(array[j], pivot) >= 0 do j -= 1
			if j > i then
				var t = array[i]
				array[i] = array[j]
				array[j] = t
			end
		end
		array[from] = array[i-1]
		array[i-1] = pivot
		sub_sort(array, from, i-2)
		sub_sort(array, i, to)
	end

	# Bubble-sort `array` between `from` and `to` indices
	# Worst case: O(n^2), average case: O(n^2)
	#
	#     var s = new DefaultComparator[Int]
	#     var a = [5, 2, 3, 1, 4]
	#     s.bubble_sort(a, 0, a.length - 1)
	#     assert a == [1, 2, 3, 4, 5]
	fun bubble_sort(array: Array[E], from: Int, to: Int)
	do
		var i = from
		while i < to do
			var min = i
			var min_v = array[i]
			var j = i
			while j <= to do
				if compare(min_v, array[j]) > 0 then
					min = j
					min_v = array[j]
				end
				j += 1
			end
			if min != i then
				array[min] = array[i]
				array[i] = min_v
			end
			i += 1
		end
	end

	# Insertion-sort `array` between `from` and `to` indices
	# Worst case: O(n^2), average case: O(n^2)
	#
	#     var s = new DefaultComparator[Int]
	#     var a = [5, 2, 3, 1, 4]
	#     s.insertion_sort(a, 0, a.length - 1)
	#     assert a == [1, 2, 3, 4, 5]
	fun insertion_sort(array: Array[E], from: Int, to: Int) do
		var last = array.length
		for i in [from..to] do
			var j = i
			while j > 0 and compare(array[j], array[j - 1]) < 0 do
				array.swap_at(j, j - 1)
				j -= 1
			end
		end
	end

	# Merge-sort `array` between `from` and `to` indices
	# Worst case: O(n lg n), average: O(n lg n)
	#
	#     var s = new DefaultComparator[Int]
	#     var a = [5, 2, 3, 1, 4]
	#     s.merge_sort(a, 0, a.length - 1)
	#     assert a == [1, 2, 3, 4, 5]
	fun merge_sort(array: Array[E], from, to: Int) do
		if from >= to then return
		var mid = (to + from) / 2
		merge_sort(array, from, mid)
		merge_sort(array, mid + 1, to)
		merge(array, from, mid, to)
	end

	private fun merge(array: Array[E], from, mid, to: Int) do
		var l = new Array[E]
		for i in [from..mid] do l.add array[i]
		var r = new Array[E]
		for i in [mid + 1..to] do r.add array[i]
		var i = 0
		var j = 0
		for k in [from..to] do
			if i >= l.length then
				array[k] = r[j]
				j += 1
			else if j >= r.length then
				array[k] = l[i]
				i += 1
			else if compare(l[i], r[j]) <= 0 then
				array[k] = l[i]
				i += 1
			else
				array[k] = r[j]
				j += 1
			end
		end
	end

	# Heap-sort `array` between `from` and `to` indices
	# Worst case: O(n lg n), average: O(n lg n)
	#
	#     var s = new DefaultComparator[Int]
	#     var a = [5, 2, 3, 1, 4]
	#     s.heap_sort(a, 0, a.length - 1)
	#     assert a == [1, 2, 3, 4, 5]
	fun heap_sort(array: Array[E], from, to: Int) do
		var size = build_heap(array)
		for j in [from..to[ do
			array.swap_at(0, size)
			size -= 1
			heapify(array, 0, size)
		end
	end

	private fun build_heap(array: Array[E]): Int do
		var size = array.length - 1
		var i = size / 2
		while i >= 0 do
			heapify(array, i, size)
			i -= 1
		end
		return size
	end

	private fun heapify(array: Array[E], from, to: Int) do
		var l = from * 2
		var r = l + 1
		var largest: Int
		if l < to and compare(array[l], array[from]) > 0 then
			largest = l
		else
			largest = from
		end
		if r < to and compare(array[r], array[largest]) > 0 then
			largest = r
		end
		if largest != from then
			array.swap_at(from, largest)
			heapify(array, largest, to)
		end
	end

end

# Deprecated class, use `Comparator` instead
interface AbstractSorter[E]
	super Comparator[E]
end

# This comparator uses the operator `<=>` to compare objects.
# see `default_comparator` for an easy-to-use general stateless default comparator.
class DefaultComparator[E: Comparable]
	super Comparator[E]
	# Return a <=> b
	redef fun compare(a, b) do return a <=> b

	init do end
end

# Deprecated class, use `DefaultComparator` instead
class ComparableSorter[E: Comparable]
	super DefaultComparator[E]
end

# Easy-to-use general stateless default comparator that uses `<=>` to compare things.
fun default_comparator: Comparator[Comparable] do return once new DefaultComparator[Comparable]
