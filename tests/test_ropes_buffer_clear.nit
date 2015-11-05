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

# Checks if `RopeBuffer.clear` actually reset everything.
module test_ropes_buffer_clear

import core

var buffer = new RopeBuffer

buffer.append "1"
# Force to flush the internal buffer, so that all the internal positions will be
# set to a non-zero value.
buffer.append("?" * (maxlen + 1))
buffer.clear
buffer.append "23"
print buffer

buffer = new RopeBuffer
buffer.append "12"
# Force to flush the internal buffer, so that all the internal positions will be
# set to a non-zero value.
buffer.append("?" * (maxlen + 1))
buffer.clear
buffer.append "3"
print buffer
