# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2014-2015 Alexandre Terrasa <alexandre@moz-code.org>
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

# This tool is runned to listen to `Github::Event` and update the game.
module listener

import reactors
import achievements
import github::hooks

# `HookListener` that redirects events to a `Game` instance.
class RpgHookListener
   super HookListener

	# Dispatch event to registered `reactors`.
	redef fun apply_event(event) do
		var game = new Game(api, event.repo)
		# TODO handle verbosity with opts
		game.verbose_lvl = 1
		game.apply_github_event event
	end
end

if args.length != 2 then
	print "Error: missing argument"
	print ""
	print "Usage:"
	print "listener <host> <port>"
	exit 1
end

var host = args[0]
var port = args[1].to_i

var api = new GithubAPI(get_github_oauth)

var listener = new RpgHookListener(api, host, port)
print "Listening events on {host}:{port}"
listener.listen
