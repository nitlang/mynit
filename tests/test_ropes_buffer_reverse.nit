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

module test_ropes_buffer_reverse

import core

redef fun maxlen do return 3

var buffer = new RopeBuffer

buffer.reverse
print "/{buffer}/"

buffer.append("x" * (maxlen + 1))
buffer.add 'y'
buffer.reverse
print buffer.to_s
