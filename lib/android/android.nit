# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2014 Alexis Laferrière <alexis.laf@xymus.net>
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

# Android services and implementation of app.nit
#
# This module provides basic logging facilities, advanced logging can be
# achieved by importing `android::log`.
module android

import platform
import native_app_glue
import dalvik
private import log

redef class App
	redef fun init_window
	do
		super
		on_create
		on_restore_state
		on_start
	end

	redef fun term_window
	do
		super
		on_stop
	end

	# Is the application currently paused?
	var paused = true

	redef fun pause
	do
		paused = true
		on_pause
		super
	end

	redef fun resume
	do
		paused = false
		on_resume
		super
	end

	redef fun save_state do on_save_state

	redef fun lost_focus
	do
		paused = true
		super
	end

	redef fun gained_focus
	do
		paused = false
		super
	end

	redef fun destroy do on_destroy
end
