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

# Process privileges management utilities
#
# Used mainly by daemons and such to aquire resources as su and
# then drop back to a restricted user.
module privileges

import opts

class UserGroup
	var user: String
	var group: nullable String

	fun drop_privileges
	do
		var passwd = new Passwd.from_name(user)
		var uid = passwd.uid

		var group = group
		var gid
		if group != null then
			var gpasswd = new Group.from_name(group)
			gid = gpasswd.gid
		else gid = passwd.gid

		sys.gid = gid
		sys.uid = uid
	end
end

# Option to ask for a username and group
class OptionDropPrivileges
	super OptionUserAndGroup

	init do init_user_and_group("Drop privileges to user:group or simply user", "-u", "--usergroup")
end

# Option to ask for a username and group
class OptionUserAndGroup
	super OptionParameter

	redef type VALUE: nullable UserGroup

	#init for_droping_privileges() do init("Drop privileges to user:group or simply user", "-u", "--usergroup")
	init(help: String, names: String...) do init_opt(help, null, names)
	private init init_user_and_group(help: String, names: String...) do init_opt(help, null, names)

	redef fun convert(str)
	do
		var words = str.split(":")
		if words.length == 1 then
			return new UserGroup(str, null)
		else if words.length == 2 then
			return new UserGroup(words[0], words[1])
		else
			errors.add("Option {names.join(", ")} expected parameter in the format \"user:group\" or simply \"user\".\n")
			abort # FIXME only for nitc, remove and replace with next line when FFI is working in nitg
			#return null
		end
	end
end
