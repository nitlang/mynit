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

module linux_app

import mnit
import sdl
import linux_opengles1

in "C" `{
	#include <EGL/egl.h>
`}

redef class App
	redef type IE: SDLInputEvent
	redef type D: Opengles1Display
	redef type I: Opengles1Image

	redef init
	do
		display = new Opengles1Display

		super

		init_window
	end

	redef fun generate_input
	do
		for event in display.sdl_display.events do
			input( event )
		end
	end
end
