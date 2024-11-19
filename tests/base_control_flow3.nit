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

var a
a = null
a = 1

a.output
return
# Below this line the code is unreachable

var b
b = null
b = 1
a.output
b.output
a = b
b = a

if a == b then
	a = b
	b = a
else
	a = null
	b = null
end
a.output
b.output
var c = a.as(not null)
var d = b.as(Int)
var e
e.output

#alt1#(b+1).output # Error
b = 1
#alt1#(b+1).output # Still error
