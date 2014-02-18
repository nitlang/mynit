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

# Curses for Nit
module curses

in "C header" `{
	#include <ncurses.h>
`}

# A curse windows
extern Window `{WINDOW *`}
	# Initialize the screen
	new `{
		WINDOW *res;
		res = initscr();
		if (res == NULL) {
			fprintf(stderr, "Error initialising ncurses.\n");
			exit(EXIT_FAILURE);
		}
		raw();
		keypad(res, TRUE);
		noecho();
		return res;
	`}

	# Move the cursor at the position (y,x) and print a string
	fun move_print_string(y,x: Int, str: String) import String::to_cstring `{
		char *c_string = String_to_cstring( str );
		mvaddstr(y, x, c_string);
	`}

	# Update the window
	fun refresh `{
		refresh();
	`}
	
	# Clear the entire window so it can be repainted from scratch with a refresh
	fun clear `{
		wclear(recv);
	`}
	
	# Delete the window
	fun delete `{
		delwin(recv);
	`}
	
	# Suspend the curses session and restore the previous terminal
	fun end_session `{
		endwin();
	`}
end
