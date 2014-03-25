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

import kernel
class A
	fun pubA(a: A) do end
	protected fun proA(a: A) do end
	private fun priA(a: A) do end

	var vpubA: nullable A writable
	protected var vproA: nullable A protected writable
	private var vpriA: nullable A

	var vpubA2 writable = new A
	protected var vproA2 protected writable = new A
	private var vpriA2 = new A

	#alt1#fun pubB(a: B) do end
	#alt2#protected fun proB(a: B) do end
	private fun priB(a: B) do end

	#alt3#var vpubB: nullable B writable
	#alt4#protected var vproB: nullable B protected writable
	private var vpriB: nullable B

	#alt5#var vpubB2 writable = new B
	#alt6#protected var vproB2 protected writable = new B
	private var vpriB2 = new B

	init do end
end

private class B
	fun pubA(a: A) do end
	#alt7#protected fun proA(a: A) do end
	private fun priA(a: A) do end

	var vpubA: nullable A writable
	#alt7#protected var vproA: nullable A protected writable
	private var vpriA: nullable A

	var vpubA2 writable = new A
	#alt7#protected var vproA2 protected writable = new A
	private var vpriA2 = new A

	fun pubB(a: B) do end
	#alt7#protected fun proB(a: B) do end
	private fun priB(a: B) do end

	var vpubB: nullable B writable
	#alt7#protected var vproB: nullable B protected writable
	private var vpriB: nullable B

	var vpubB2 writable = new B
	#alt7#protected var vproB2 protected writable = new B
	private var vpriB2 = new B

	init do end
end
