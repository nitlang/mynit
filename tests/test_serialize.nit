# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2013 Alexis Laferrière <alexis.laf@xymus.net>
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

import serialize

var b = new Buffer
34.dump_to( b )
0.0.dump_to( b )
true.dump_to( b )
false.dump_to( b )
"hello".dump_to( b )

print b.to_s

var s = new StringDeserializationStream( b.to_s )
print s.read_int
print s.read_float
print s.read_bool
print s.read_bool
print s.read_string

