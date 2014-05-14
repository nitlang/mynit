# This file is part of NIT ( http://www.nitlanguage.org ).
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

# Binary Tree data-structure
# A binary tree is a tree data structure in which each node has at most two children
# (referred to as the left child and the right child).
# In a binary tree, the degree of each node can be at most two.
# Binary trees are used to implement binary search trees and binary heaps,
# and are used for efficient searching and sorting.
module bintree

import abstract_tree

# Binary Tree Map
#
# Properties:
#  * unique root
#  * node.left.key < node.key
#  * node.right.key > node.key
#  * no duplicates allowed
#
# Operations:
#  * search average O(lg n) worst O(n)
#  * insert average O(lg n) worst O(n)
#  * delete average O(lg n) worst O(n)
#
# Usage:
#     var tree = new BinTreeMap[Int, String]
#     tree[1] = "n1"
#     assert tree.min == "n1"
class BinTreeMap[K: Comparable, E]
	super TreeMap[K, E]

	redef type N: BinTreeNode[K, E]

	# Get the node value associated to `key`
	# O(n) in worst case, average is O(h) with h: tree height
	#
	#     var tree = new BinTreeMap[Int, String]
	#     for i in [4, 2, 1, 5, 3] do tree[i] = "n{i}"
	#     assert tree[1] == "n1"
	redef fun [](key: K): E do
		assert not_empty: root != null
		var res = search_down(root.as(not null), key)
		assert has_key: res != null
		return res.value
	end

	protected fun search_down(from: N, key: K): nullable N do
		if key == from.key then return from
		if from.left != null and key < from.key then
			return search_down(from.left.as(not null), key)
		else if from.right != null then
			return search_down(from.right.as(not null), key)
		end
		return null
	end

	# Get the node with the minimum key
	# O(n) in worst case, average is O(h) with h: tree height
	#
	#     var tree = new BinTreeMap[Int, String]
	#     for i in [4, 2, 1, 5, 3] do tree[i] = "n{i}"
	#     assert tree.min == "n1"
	fun min: E do
		assert not_empty: root != null
		return min_from(root.as(not null)).value
	end

	protected fun min_from(node: N): N do
		if node.left == null then return node
		return min_from(node.left.as(not null))
	end

	# Get the node with the maximum key
	# O(n) in worst case, average is O(h) with h: tree height
	#
	#     var tree = new BinTreeMap[Int, String]
	#     for i in [4, 2, 1, 5, 3, 6, 7, 8] do tree[i] = "n{i}"
	#     assert tree.max == "n8"
	fun max: E do
		assert not_empty: root != null
		return max_from(root.as(not null)).value
	end

	protected fun max_from(node: N): N do
		if node.right == null then return node
		return max_from(node.right.as(not null))
	end

	# Insert a new node in tree using `key` and `item`
	# O(n) in worst case, average is O(h) with h: tree height
	#
	#     var tree = new BinTreeMap[Int, String]
	#     tree[1] = "n1"
	#     assert tree.max == "n1"
	#     tree[3] = "n3"
	#     assert tree.max == "n3"
	redef fun []=(key, item) do
		insert_node(new BinTreeNode[K, E](key, item))
	end

	protected fun insert_node(node: N) do
		if root == null then
			root = node
		else
			shift_down(root.as(not null), node)
		end
	end

	# Push down the `node` in tree from a specified `from` index
	protected fun shift_down(from, node: N) do
		if node.key < from.key then
			if from.left == null then
				from.left = node
				node.parent = from
			else
				shift_down(from.left.as(not null), node)
			end
		else if node.key > from.key then
			if from.right == null then
				from.right = node
				node.parent = from
			else
				shift_down(from.right.as(not null), node)
			end
		end
	end

	# Delete node at `key` (also return the deleted node value)
	# O(n) in worst case, average is O(h) with h: tree height
	#
	#     var tree = new BinTreeMap[Int, String]
	#     tree[1] = "n1"
	#     assert tree.max == "n1"
	#     tree[3] = "n3"
	#     assert tree.max == "n3"
	#     tree.delete(3)
	#     assert tree.max == "n1"
	fun delete(key: K): nullable E do
		assert is_empty: root != null
		var node = search_down(root.as(not null), key)
		if node == null then return null
		if node.left == null then
			transplant(node, node.right)
		else if node.right == null then
			transplant(node, node.left)
		else
			var min = min_from(node.right.as(not null))
			if min.parent != node then
				transplant(min, min.right)
				min.right = node.right
				min.right.parent = min
			end
			transplant(node, min)
			min.left = node.left
			min.left.parent = min
		end
		return node.value
	end

	# Swap a `node` with the `other` in this Tree
	# note: Nodes parents are updated, children still untouched
	protected fun transplant(node, other: nullable N) do
		if node == null then return
		if node.parent == null then
			root = other
		else if node == node.parent.left then
			node.parent.left = other
		else
			node.parent.right = other
		end
		if other != null then other.parent = node.parent
	end

	# Perform left rotation on `node`
	#
	#     N             Y
	#    / \     >     / \
	#   a   Y         N   c
	#      / \   <   / \
	#     b   c     a   b
	#
	protected fun rotate_left(node: N) do
		var y = node.right
		node.right = y.left
		if y.left != null then
			y.left.parent = node
		end
		y.parent = node.parent
		if node.parent == null then
			root = y
		else if node == node.parent.left then
			node.parent.left = y
		else
			node.parent.right = y
		end
		y.left = node
		node.parent = y
	end

	# Perform right rotation on `node`
	#
	#     N             Y
	#    / \     >     / \
	#   a   Y         N   c
	#      / \   <   / \
	#     b   c     a   b
	#
	protected fun rotate_right(node: N) do
		var y = node.left
		node.left = y.right
		if y.right != null then
			y.right.parent = node
		end
		y.parent = node.parent
		if node.parent == null then
			root = y
		else if node == node.parent.right then
			node.parent.right = y
		else
			node.parent.left = y
		end
		y.right = node
		node.parent = y
	end

	# Sort the tree into an array
	# O(n)
	#
	#     var tree = new BinTreeMap[Int, String]
	#     for i in [4, 2, 1, 5, 3] do tree[i] = "n{i}"
	#     assert tree.sort == ["n1", "n2", "n3", "n4", "n5"]
	fun sort: Array[E] do
		var sorted = new Array[E]
		if root == null then return sorted
		sort_down(root.as(not null), sorted)
		return sorted
	end

	protected fun sort_down(node: N, sorted: Array[E]) do
		if node.left != null then sort_down(node.left.as(not null), sorted)
		sorted.add(node.value)
		if node.right != null then sort_down(node.right.as(not null), sorted)
	end

	redef fun to_s do
		var root = self.root
		if root == null then return "[]"
		return "[{print_tree(root)}]"
	end

	protected fun print_tree(node: N): String do
		var s = new FlatBuffer
		s.append(node.to_s)
		if node.left != null then s.append(print_tree(node.left.as(not null)))
		if node.right != null then s.append(print_tree(node.right.as(not null)))
		return s.to_s
	end

	redef fun show_dot do
		assert not_empty: root != null
		var f = new OProcess("dot", "-Txlib")
		f.write "digraph \{\n"
		dot_down(root.as(not null), f)
		f.write "\}\n"
		f.close
	end

	protected fun dot_down(node: N, f: OProcess) do
		if node.left != null then dot_down(node.left.as(not null), f)
		f.write node.to_dot
		if node.right != null then dot_down(node.right.as(not null), f)
	end
end

# TreeNode used by BinTree
class BinTreeNode[K: Comparable, E]
	super TreeNode[K, E]

	redef type SELF: BinTreeNode[K, E]

	init(key: K, item: E) do
		super(key, item)
	end

	private var left_node: nullable SELF = null

	# `left` tree node child (null if node has no left child)
	fun left: nullable SELF do return left_node

	# set `left` child for this node (or null if left no child)
	# ENSURE: node.key < key (only if node != null)
	fun left=(node: nullable SELF) do
		assert node != null implies node.key < key
		left_node = node
	end

	private var right_node: nullable SELF = null

	# `right` tree node child (null if node has no right child)
	fun right: nullable SELF do return right_node

	# set `right` child for this node (or null if right no child)
	# ENSURE: node.key < key (only if node != null)
	fun right=(node: nullable SELF) do
		if node != null then
			assert node.key > key
		end
		right_node = node
	end

	# `parent` of the `parent` of this node (null if root)
	fun grandparent: nullable SELF do
		if parent == null then
			return null
		else
			return parent.parent
		end
	end

	# Other child of the `grandparent`
	# `left` or `right` depends on the position of the current node against its parent
	fun uncle: nullable SELF do
		var g = grandparent
		if g == null then
			return null
		else
			if parent == g.left then
				return g.right
			else
				return g.left
			end
		end
	end

	# Other child of the parent
	# `left` or `right` depends on the position of the current node against its parent
	fun sibling: nullable SELF do
		if parent == null then
			return null
		else if self == parent.left then
			return parent.right
		else if self == parent.right then
			return parent.left
		else
			return null
		end
	end

	redef fun to_s do return "\{{key}: {value}\}"
end

