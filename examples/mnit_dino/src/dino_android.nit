# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2012-2014 Alexis Laferrière <alexis.laf@xymus.net>
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

module dino_android is
	app_namespace "org.nitlanguage.dino"
end

import dino

import mnit::android
import android::portrait
import android::vibration

redef class ImageSet
	redef fun start_over_path do return "images/play_again_mobile.png"
end

redef class SplashScreen
	redef fun splash_play_path do return "images/splash_play_mobile.png"
end

redef class Display
	redef fun top_offset do return 92
end

redef class Dino
	# When hit, vibrate
	redef fun hit(hitter, dmg)
	do
		app.vibrator.vibrate 25
		super
	end
end

redef class Caveman
	# When crushed, vibrate a little
	redef fun die(turn)
	do
		app.vibrator.vibrate 10
		super
	end
end
