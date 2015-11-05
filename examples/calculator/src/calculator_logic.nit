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

# Business logic of a calculator
module calculator_logic

import serialization

# Hold the state of the calculator and its services
class CalculatorContext
	auto_serializable

	# Result of the last operation
	var result: nullable Numeric = null

	# Last operation pushed with `push_op`, to be executed on the next push
	var last_op: nullable Char = null

	# Value currently being entered
	var current: nullable FlatBuffer = null

	# Text to display on screen
	fun display_text: String
	do
		var result = result
		var last_op = last_op
		var current = current

		var buf = new FlatBuffer

		if result != null and (current == null or last_op != '=') then
			if last_op == '=' then buf.append "= "

			buf.append result.to_s
			buf.add ' '
		end

		if last_op != null and last_op != '=' then
			buf.add last_op
			buf.add ' '
		end

		if current != null then
			buf.append current.to_s
			buf.add ' '
		end

		return buf.to_s
	end

	# Push operation `op`, will usually execute the last operation
	fun push_op(op: Char)
	do
		apply_last_op_if_any
		if op == 'C' then
			self.result = null
			last_op = null
		else
			last_op = op # store for next push_op
		end

		# prepare next current
		self.current = null
	end

	# Push a digit
	fun push_digit(digit: Int)
	do
		var current = current
		if current == null then current = new FlatBuffer
		current.add digit.to_s.chars.first
		self.current = current

		if last_op == '=' then
			self.result = null
			last_op = null
		end
	end

	# Switch entry mode from integer to decimal
	fun switch_to_decimals
	do
		var current = current
		if current == null then current = new FlatBuffer.from("0")
		if not current.chars.has('.') then current.add '.'
		self.current = current
	end

	# Execute the last operation it not null
	protected fun apply_last_op_if_any
	do
		var op = last_op
		var result = result
		var current = current
		self.current = null

		if current == null then return

		if op == null then
			result = current.to_n
		else if result != null then
			if op == '+' then
				result = result.add(current.to_n)
			else if op == '-' then
				result = result.sub(current.to_n)
			else if op == '/' then
				result = result.div(current.to_n)
			else if op == '*' then
				result = result.mul(current.to_n)
			end
		end

		self.result = result
	end
end

redef universal Float
	redef fun to_s do return to_precision(6)
end
