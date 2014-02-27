# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2011-2013 Alexis Laferrière <alexis.laf@xymus.net>
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

# Defines abstract classes for user and general inputs to the application.
# Implemented independantly for each platforms and technologies.
module input_events

# Input to the App, propagated through `App::input`.
interface InputEvent
end

# Mouse and touch input events
interface PointerEvent
	super InputEvent

	# X position on screen (in pixels)
	fun x: Float is abstract

	# Y position on screen (in pixels)
	fun y: Float is abstract

	# Is down? either going down or already down
	fun pressed: Bool is abstract
	fun depressed: Bool is abstract
end

# Pointer motion event, mais concern many events
interface MotionEvent
	super InputEvent

	# A pointer just went down?
	fun just_went_down: Bool is abstract

	# Which pointer is down, if any
	fun down_pointer: nullable PointerEvent is abstract
end

# Specific touch event
interface TouchEvent
	super PointerEvent

	# Pressure level of input
	fun pressure: Float is abstract
end

# Keyboard or other keys event
interface KeyEvent
	super InputEvent

	# Key is currently down?
	fun is_down: Bool is abstract

	# Key is currently up?
	fun is_up: Bool is abstract

	# Key is the up arrow key?
	fun is_arrow_up: Bool is abstract

	# Key is the left arrow key?
	fun is_arrow_left: Bool is abstract

	# Key is the down arrow key?
	fun is_arrow_down: Bool is abstract

	# Key is the right arrow key?
	fun is_arrow_right: Bool is abstract

	# Key code, is plateform specific
	fun code: Int is abstract

	# Get Char value of key, if any
	fun to_c: nullable Char is abstract
end

# Mobile hardware (or pseudo hardware) event
interface MobileKeyEvent
	super KeyEvent

	# Key is back button? (mostly for Android)
	fun is_back_key: Bool is abstract

	# Key is menu button? (mostly for Android)
	fun is_menu_key: Bool is abstract

	# Key is search button? (mostly for Android)
	fun is_search_key: Bool is abstract

	# Key is home button? (mostly for Android)
	fun is_home_key: Bool is abstract
end

# Quit event, used for window close button
interface QuitEvent
	super InputEvent
end
