# Contract Programming

Nit supports [contract programming](https://en.wikipedia.org/wiki/Design_by_contract). Contracts can be seen as the materialization of specifications in the code itself. The idea is to define the behavior of a property using conditions which will be evaluated at runtime. A contract defines the rules between a property and all its potential callers. If one of the two parties (callee/caller) does not respect the defined rules, the contract is considered to be broken and will cause a runtime error.

You can put contracts on different elements of the language: methods, attributes, interfaces and classes in order to verify the conformity of the implementation compared to its specification.

Different types of contracts exist:

* The preconditions (`expect`) and the postconditions (`ensure`) can be put on methods and attributes (setter) to define respectively the condition to check before and after the execution of the method.

* The invariants (`invariant`) that can be put on class and interface to define the conditions that must remain unchanged before and after the execution of each method of the class.

Using contracts is particularly useful when dealing with business rules. For example when developing a library where it may be necessary to specify contracts as to ensure valid usages of the API. In addition, the contracts take in consideration the inheritance, which means that any future modification (addition of extensions, functionalities or maintenance of existing code) will not break the existing specifications.

Let us take a look at the `Stack` class bellow:

~~~
class Stack[T]
	invariant(size >= 0)

	var data = new Array[T]

	var size = 0

	fun is_empty: Bool
	is
		ensure(result == (size == 0))
	do
		return size == 0
	end

	# Add `item` on top of the stack
	fun push(item: T)
	is
		ensure(size == old(size) + 1)
		ensure(data[size-1] == item)
	do
		data[size] = item
		size += 1
	end

	# Remove the item on top of the stack
	fun pop
	is
		expect(not is_empty)
		ensure(size == old(size) - 1)
	do
		data.pop
		size -= 1
	end

	# Return the item at the given index.
	fun [](index: Int): T
	is
		expect(index < size)
		expect(index >= 0)
		ensure(result == data[index])
	do
		return data[index]
	end

	# Set the item at the given index
	fun []=(index: Int, item: T)
	is
		expect(index >= 0)
		expect(index <= size)
	do
		data[index] = item
	end
end
~~~

As we can see, the contracts are defined using several annotations:

* `invariant` which designates the class invariants
* `expect` which designates the preconditions
* `ensure` which designates the postconditions.

All the conditions of a contract must be expressed as boolean expressions like assertions. Each contract of this example will be detailed in the sections below.

When you compile or interpret a program, the default contract strategy is as follows:

* All contracts (`ensure`, `expect`, `invariant`) used in the main module are enabled.
* Direct imported modules have only the expects contracts enabled (`ensure` and `invariant` contracts are disabled).
* All other indirect imported modules don't have active contracts.

Here is an example of enabled contracts, if you compile (or interpret) respectively a program that imports the module `stack` or if you compile directly the module `stack`.

`nitc my_file_that_uses_stack.nit` or `nit my_file_that_uses_stack.nit`

| Module           | `my_file_that_uses_stack`       | `stack`  | stdlib   | other  |
|------------------|---------------------------------|----------|----------|--------|
| Enabled contracts| `expect`, `ensure`, `invariant` | `expect` | `expect` | `none` |

`nitc stack.nit` or `nit stack.nit`

| Module           | `stack`                         | stdlib   | other  |
|------------------|---------------------------------|----------|--------|
| Enabled contracts| `expect`, `ensure`, `invariant` | `expect` | `none` |

Note that, all modules in the standard library are considered to be directly imported, therefore, all "except" contracts are enabled. If you need to manage contracts differently you can use options to change the contract rule see `Options` section for more information.

All contracts conditions can be declared in several ways, all are equivalent:
~~~nitish
fun foo(a: Int, b: Int) is expect(a > 0, b < 0)
~~~
~~~nitish
fun foo(a: Int, b: Int) is expect(a > 0 and b < 0)
~~~
~~~nitish
fun foo(a: Int, b: Int) is expect(a > 0), ensure(b < 0)
~~~

## Writing invariants

Invariants are used to specify the characteristics of a class/interface which must always be true, except when executing a member function. In other words, invariants define conditions that must be respected by our instance. Any instance which does not respect one or more of those conditions will be considered as in an incoherent state, and will cause an "assertion failed" error at runtime.

To define an invariant we use the class annotation `invariant`. Here is an example with our Stack. The class defines that it is impossible to be in a state where the size is less than 0.

~~~nitish
class Stack
	invariant(size >= 0)
end
~~~

Another example with a class that represents a date (day, month). To be in a consistent state, the date must be represented with a day between 1 and 31 and a month between 1 and 12.

~~~
class Date
	invariant(day >= 1 and day <= 31)
	invariant(month >= 1 and month <= 12)

	var day: Int
	var month: Int
end
~~~

When a class defines an invariant, all methods and constructors (inherited, redefined, and introduced) will check this one. By default, the invariants are only checked on exit. See section `Verification policy` to activate them on in and out. For all constructors the invariant is only checked at the end of this, this is due to the fact that the object is not yet initialized. See the section `Execution order` for example.

The invariant is not checked when the call is on `self`. The following example shows the execution of invariant:

~~~
class A
	invariant(print_invariant)

	fun print_invariant: Bool
	do
		print "In invariant verification"
		return true
	end

	fun foo
	do
		print "In foo"
		self.bar # The called property is a member of "self", the invariant will not be checked.
	end

	fun bar
	do
		print "In bar"
	end
end

var a = new A
a.foo # The called property is not a member of "self", the invariant will be checked.
~~~

This example gives the following output:
~~~nitish
In invariant verification
In foo
In bar
In invariant verification
~~~

## Writing contracts

Methods, as well as attribute setters, can be associated with two types of contracts; precondition (`expect`) that expresses requirements of the routine´s call and postcondition (`ensure`) that expresses what the routine guarantee after her execution. Together, they define the rules to be respected between the callee and the caller. If the caller fulfills the `expect` condition on entry, then the caller can assume that the callee fulfills the `ensure` condition on exit.

All contracts (`expect`, `ensure`) are evaluated in the same context as the called method, it's possible to refer to attributes, methods and parameters in the condition.

When defining a precondition or a postcondition on an attribute, contracts are only applied to the write property (setter).

~~~nitish
var baz: Int is expect(baz > 0) # In the contract, baz refers to the parameter of the write property (setter).
~~~

### Define preconditions with `expect`

We define a precondition using the annotation `expect`. In the `Stack` class, the method `pop` defines a precondition, that a call to the method should be made on a non-empty stack.

~~~nitish
fun pop is expect(not_empty)
~~~

### Define postconditions with `ensure`

We define a postcondition using the annotation `ensure`. In the `Stack` class, the method `push` defines postconditions. The first guarantee defines that, the method must add the element received as argument (`object`) at the top of the stack.

~~~nitish
fun push(object: T) is ensure(self[size - 1] == object)
~~~

Within an `ensure` contract we can refer to the return value of the method with the keyword `result`. In the `Stack` class, the `[]` method guarantees that, the return value is the same as the element stored in the stack at the given index.

~~~nitish
fun [](index: Int): T is ensure(result == data[index])
~~~

Note that the keyword `result` can only be used when the method has a return parameter.


In an `ensure` we can refer to any arguments and instance variables before the method call, using the `old` keyword. Again, with the `pop` method, we can ensure that the `size` of the stack after the method call will be the same as before minus one `old(size) - 1 == size`.

~~~nitish
fun pop(object: T) is ensure(old(size) - 1 == size)
~~~

In an `old(expression)` the `expression` is evaluated in the same context as the called method. Thus, it's possible to refer to attributes, methods, and arguments.

`old(object)` stores a reference to object. By doing so, if `object` is mutated in the method the `old(object)` will also be mutated.

Let's take a look at the following example:

~~~
class Boat
	var position: Position

	fun move(direction: Position)
	do
		position = position + direction
	end
end

class Position
	var x: Float
	var y: Float

	fun +(position: Position): Position
	is
		ensure(old(x) + position.x == x)
		ensure(old(y) + position.y == y)
	do
		x += position.x
		y += position.y
		return self
	end

	redef fun ==(other)
	is
		ensure(result == (x == other.x and y == other.y))
	do
		if not other isa Position then return false
		return x == other.x and y == other.y
	end
end
~~~

This example introduce the following problem: How to define the postcondition of the `move` method to indicate that the new position is equal to the old position plus direction?

As we store a reference it's impossible to proceed like this `ensure(old(position) + direction == position)`. Several solutions exist to solve this problem:

- You can capture the changes individually like as the `+` method in the `Position` class. Which would give the following postcondition for the `move` method:

~~~nitish
fun move(direction: Position) is ensure( old(position.x) + direction.x  == position.x and old(position.y) + direction.y  == position.y)
~~~

- You can duplicate the object `position` with a method like `clone`, so that `not old(position.clone).is_same_instance(position)` is true.

~~~nitish
class Position
	super Cloneable
	var x: Float
	var y: Float

	redef fun clone: SELF do return new Position(x,y)
end

class Boat
	var position: Position

	fun move(direction: Position)
	is
		ensure(old(position.clone) + direction  == position)
	do
		position =  position + direction
	end
end
~~~

Note that it is often better to capture only the interesting part, rather than providing a duplication method. The duplication method is generally reserved when you deal with complex objects.

## Inheritance

The Nit contracts support multiple inheritance and refinement. The specialization can be interpreted as subcontracting. All methods, class/interface which are redefined must keep the set of conditions defined by all the previous definitions. Here are the subtyping rules for each type of the contracts:

* The `expect` can be weakened, which guarantees that all the contracts introduced in the previous definitions will always be considered as valid entries. During the specialization of a method it will be possible to redefine its preconditions in order the widen the allowed input.

Example:
~~~
class MyClass
	fun foo(x: Int) is abstract, expect(x == 0)
end

class MySub
	super MyClass

	redef fun foo(x: Int) is expect(x == -1)
end

class MySubSub
	super MySub

	redef fun foo(x: Int) is expect(x == -2)
end
~~~

| Class    | Condition of `foo(x)`          |
|----------|--------------------------------|
| MyClass  | `x == 0`                       |
| MySub    | `x == 0 or x == -1`            |
| MySubSub | `x == 0 or x == -1 or x == -2` |

When refining a precondition (`expect`) the new condition is equivalent to an `or` between the set of inherited preconditions.

* The `ensure` can be reinforced, which guarantees that all of the expected results introduced in the previous definitions must be respected. During the specialization of a method it will be possible to redefine its postcondition in order to restrict the possible outputs.

Example:
~~~
class MyClass
	fun foo: Int is abstract, ensure(result > 0)
end

class MySub
	super MyClass

	redef fun foo: Int is abstract, ensure(result > 10)
end

class MySubSub
	super MyClass

	redef fun foo: Int is abstract, ensure(result > 100)
end
~~~

| Class    | Condition of `foo`                            |
|----------|-----------------------------------------------|
| MyClass  | `result > 0`                                  |
| MySub    | `result > 0 and result > 10`                  |
| MySubSub | `result > 0 and result > 10 and result > 100` |

When refining a postcondition (`ensure`) the new condition is equivalent to an `and` between the set of inherited postconditions.

* The `invariant` can be reinforced, which guarantees that constraints of validated state previously defined in the superclasses/interfaces must be respected. The specialization of a class makes it possible to restrict all of the valid states. The objective is that an object must always be considered as a coherent value of all of its superclasses/interfaces.

Example:
~~~
class MyClass
	invariant(i > 0)
	var i: Int
end

class MySub
	super MyClass
	invariant(i > 10)
end

class MySubSub
	super MySub
	invariant(i > 100)
end
~~~

| Class    | Condition of `invariant`       |
|----------|--------------------------------|
| MyClass  | `i > 0`                        |
| MySub    | `i > 0 and i > 10`             |
| MySubSub | `i > 0 and i > 10 and i > 100` |

When we specialize or refine a class, its invariants are equivallent to an `AND` between the inherited and new conditions.

Nit offers the possibility of removing the inheritance of contracts with the `no_contract`  annotation. This annotation should be used sparingly (use it when; it´s really necessary and you know what you are doing).

Example:
~~~
class MyClass
	fun foo(x: Int) is abstract, ensure(x == 0)
end

class MySub
	super MyClass

	redef fun foo(x: Int) is no_contract
end
~~~

| Class   | Condition of `foo(x)` |
|---------|-----------------------|
| MyClass | `i == 0`              |
| MySub   | `none`                |

## Execution

When performing the evaluation of a contract, all routines executed in the evaluation context will be executed without contracts verification. The objective is to remove the potential risk of falling into an infinite loop of verification.

Now we add a small test program to see the contract of `Stack` class in action:

~~~nitish
var stack = new Stack[String]
stack.push("Banana")
stack.push("Coconut")
# stack.get_at(5) # Causes an assertion failed because the given index is > size
stack.pop
stack.pop
# stack.pop # Causes an assertion failed because the stack is empty
# stack.size = -1 # Causes an assertion failed because a stack cannot have a size < 0
~~~

### Execution order

~~~
class A
	invariant(i > 10)

	var i: Int

	init default(i: Int)
	is
		expect(i > 0)
		ensure(self.i == i + 10)
	do
		_i = i + 10
	end

	fun foo(x: Int): Bool
	is
		expect( x > 0 )
		ensure( result == true )
	do
		return true
	end
end

var a = new A(2)
a.foo(10)
~~~

This is the evaluation order of the `var a = new A(2)`:

1- preconditions (`expect(i > 0)`)
2- called property (execution of the method body)
3- postconditions (`ensure(self.i = i + 10)`)
4- invariant (`invariant(i > 10)`)

This is the evaluation order of the `a.foo`:

1- invariant (`invariant(i > 10)`)
2- preconditions (`expect( x > 0 )`)
3- called property (execution of the method body)
4- postconditions (`result == true`)
5- invariant (`invariant(i > 10)`)

In redefinition when you make a call to `super` the contracts is not checked again.

Example:
~~~
class A
	fun print_expect: Bool
	do
		print "In expect A"
		return true
	end

	fun foo
	is
		expect(print_expect)
	do
		print "In foo of A"
	end
end

class B
	super A

	fun print_new_expect: Bool
	do
		print "In expect B"
		return true
	end

	redef fun foo
	is
		expect(print_new_expect)
	do
		super
		print "In foo of B"
	end
end

var b = new B
b.foo
~~~

This example gives the following output:
~~~nitish
In expect B
In foo of A
In foo of B
~~~

Note this example also shows the fact that during elevations of `expect` in an inheritance frame when one of the `expect` conditions is satisfied we stop the verification.

To summarize the evaluation order for public methods/attribute, is as follows:

1- invariant
2- preconditions (`expect`)
3- called property
4- postconditions (`ensure`)
5- invariant

For constructors only the invariant verification in entry (first step) is ignored.

### Options

Here is the list of options to manage contract verification, all options are available on both engines `nitc` and `nit`:

`--full-contract`: Enable contracts on all modules. Warning: this is an expensive option at runtime.

`--no-contract`: all contracts are disabled.

`--in-out-invariant`: Enable `invariant` verification on entry and exit. By default, invariants are only checked on exit

`--no-self-contract`: Disables all contracts on member routines of the same instance.
