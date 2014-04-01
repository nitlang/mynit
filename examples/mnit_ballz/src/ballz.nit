# this file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2014 Romain Chanoir <romain.chanoir@viacesi.fr>
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

module ballz

import realtime
import mnit_android
import game_logic

class MyApp
	super App

	var screen: nullable Screen

	var target_dt = 20000000

	init do super


	redef fun init_window 
	do
		super
		screen = new Screen(self, display.as(Display))
		
	end

	redef fun frame_core(display)
	do
		var screen = self.screen
		if screen != null then
			var clock = new Clock

			screen.game.do_turn
			screen.do_frame(display)
			
			var dt = clock.lapse
			if dt.sec == 0 and dt.nanosec < target_dt then
				var sleep_t = target_dt - dt.nanosec
				sys.nanosleep(0, sleep_t)
			end
		end
	end

	redef fun input(ie)
	do	
		if ie isa QuitEvent then 
			quit = true
			return true
		end
		if screen != null then
			return screen.input(ie)
		end
		return false
	end
end

var app = new MyApp
app.sensors_support_enabled = true
app.accelerometer.enabled = true
app.accelerometer.event_rate = 10000
app.magnetic_field.enabled = true
app.gyroscope.enabled = true
app.light.enabled = true
app.proximity.enabled = true
app.main_loop
