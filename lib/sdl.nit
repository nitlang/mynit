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

# Simple DirectMedia Layer
module sdl is
	cflags exec("sdl-config", "--cflags")
	ldflags(exec("sdl-config", "--libs"), "-lSDL_image -lSDL_ttf")
end

import mnit::display
import c

in "C header" `{
	#include <unistd.h>
	#include <SDL/SDL.h>
	#include <SDL/SDL_syswm.h>
	#include <SDL/SDL_image.h>
	#include <SDL/SDL_ttf.h>
`}

# Represent a screen surface
extern class SDLDisplay `{SDL_Surface *`}
	super Display

	redef type I: SDLImage

	# Initialize a surface with width and height
	new (w, h: Int) import enable_mouse_motion_events `{
		SDL_Init(SDL_INIT_VIDEO);

		if(TTF_Init()==-1) {
			printf("TTF_Init: %s\n", TTF_GetError());
			exit(2);
		}

 		SDL_Surface *self = SDL_SetVideoMode(w, h, 24, SDL_HWSURFACE);

		if (!SDLDisplay_enable_mouse_motion_events(self)) {
			/* ignores mousemotion for performance reasons */
			SDL_EventState(SDL_MOUSEMOTION, SDL_IGNORE);
		}

		return self;
	`}

	# Indicates wether we want the SDL mouse motion event (or only clicks).
	# Disabled by defaut for performance reason. To activate, redef this method
	# andd return true
	fun enable_mouse_motion_events: Bool do return false

	# Destroy the surface
	fun destroy `{
		if (SDL_WasInit(SDL_INIT_VIDEO))
			SDL_Quit();

		if (TTF_WasInit())
			TTF_Quit();
	`}

	redef fun finish `{ SDL_Flip(self); `}

	# Clear the entire window with given RGB color (integer values)
	fun clear_int(r, g, b: Int) `{
		SDL_FillRect(self, NULL, SDL_MapRGB(self->format,r,g,b));
	`}

	redef fun width `{ return self->w; `}
	redef fun height `{ return self->h; `}

	# Fill a rectangle with given color
	fun fill_rect(rect: SDLRectangle, r, g, b: Int) `{
		SDL_FillRect(self, rect,  SDL_MapRGB(self->format,r,g,b));
	`}

	redef fun clear(r, g, b) `{
		Uint8 ri, gi, bi;
		ri = (Uint8)r*255;
		gi = (Uint8)g*255;
		bi = (Uint8)b*255;
		SDL_FillRect(self, NULL, SDL_MapRGB(self->format,ri,gi,bi));
	`}

	# SDL events since the last call to this method
	fun events: Sequence[SDLInputEvent]
	do
		var events = new Array[SDLInputEvent]
		loop
			var new_event = poll_event
			if new_event == null then break
			events.add new_event
		end
		return events
	end

	private fun poll_event: nullable SDLInputEvent import SDLKeyEvent, SDLMouseButtonEvent, SDLMouseMotionEvent, SDLQuitEvent, NativeString.to_s, SDLMouseButtonEvent.as(nullable SDLInputEvent), SDLMouseMotionEvent.as(nullable SDLInputEvent), SDLKeyEvent.as(nullable SDLInputEvent), SDLQuitEvent.as(nullable SDLInputEvent) `{
		SDL_Event event;

		SDL_PumpEvents();

		if (SDL_PollEvent(&event))
		{
			switch (event.type) {
				case SDL_KEYDOWN:
				case SDL_KEYUP:
	#ifdef DEBUG
					printf("The \"%s\" key was pressed!\n",
						   SDL_GetKeyName(event.key.keysym.sym));
	#endif

					return SDLKeyEvent_as_nullable_SDLInputEvent(
							new_SDLKeyEvent(NativeString_to_s(
								SDL_GetKeyName(event.key.keysym.sym)),
								event.type==SDL_KEYDOWN));

				case SDL_MOUSEMOTION:
	#ifdef DEBUG
					printf("Mouse moved by %d,%d to (%d,%d)\n",
						   event.motion.xrel, event.motion.yrel,
						   event.motion.x, event.motion.y);
	#endif

					return SDLMouseMotionEvent_as_nullable_SDLInputEvent(
							new_SDLMouseMotionEvent(event.motion.x, event.motion.y,
								event.motion.xrel, event.motion.yrel, SDL_GetMouseState(NULL, NULL)&SDL_BUTTON(1)));

				case SDL_MOUSEBUTTONDOWN:
				case SDL_MOUSEBUTTONUP:
	#ifdef DEBUG
					printf("Mouse button \"%d\" pressed at (%d,%d)\n",
						   event.button.button, event.button.x, event.button.y);
	#endif
					return SDLMouseButtonEvent_as_nullable_SDLInputEvent(
							new_SDLMouseButtonEvent(event.button.x, event.button.y,
								event.button.button, event.type == SDL_MOUSEBUTTONDOWN));

				case SDL_QUIT:
	#ifdef DEBUG
					printf("Quit event\n");
	#endif
					return SDLQuitEvent_as_nullable_SDLInputEvent(new_SDLQuitEvent());
			}
		}

		return null_SDLInputEvent();
	`}

	# Set the position of the cursor to x,y
	fun warp_mouse(x,y: Int) `{ SDL_WarpMouse(x, y); `}

	# Show or hide the cursor
	fun show_cursor=(val: Bool) `{ SDL_ShowCursor(val? SDL_ENABLE: SDL_DISABLE); `}

	# Is the cursor visible?
	fun show_cursor: Bool `{ return SDL_ShowCursor(SDL_QUERY); `}

	# Grab or release the input
	fun grab_input=(val: Bool) `{ SDL_WM_GrabInput(val? SDL_GRAB_ON: SDL_GRAB_OFF); `}

	# Is the input grabbed?
	fun grab_input: Bool `{ return SDL_WM_GrabInput(SDL_GRAB_QUERY) == SDL_GRAB_ON; `}

	# Are instances of `SDLMouseMotionEvent` ignored?
	fun ignore_mouse_motion_events: Bool `{
		return SDL_EventState(SDL_MOUSEMOTION, SDL_QUERY);
	`}

	# Do not raise instances of `SDLMouseMotionEvent` if `val`
	fun ignore_mouse_motion_events=(val: Bool) `{
		SDL_EventState(SDL_MOUSEMOTION, val? SDL_IGNORE: SDL_ENABLE);
	`}

	# Does `self` has the mouse focus?
	fun mouse_focus: Bool `{ return SDL_GetAppState() & SDL_APPMOUSEFOCUS; `}

	# Does `self` has the input focus?
	fun input_focus: Bool `{ return SDL_GetAppState() & SDL_APPINPUTFOCUS; `}
end

# Basic Drawing figures
extern class SDLDrawable `{SDL_Surface*`}
	super Drawable

	redef type I: SDLImage

	redef fun blit(img, x, y) do native_blit(img, x.to_i, y.to_i)
	private fun native_blit(img: I, x, y: Int) `{
		SDL_Rect dst;
		dst.x = x;
		dst.y = y;
		dst.w = 0;
		dst.h = 0;

		SDL_BlitSurface(img, NULL, self, &dst);
	`}

	redef fun blit_centered(img, x, y)
	do
		x = x - img.width / 2
		y = y - img.height / 2
		blit(img, x, y)
	end
end

# A drawable Image
extern class SDLImage
	super DrawableImage
	super SDLDrawable

	# Import image from a file
	new from_file(path: String) import String.to_cstring `{
		SDL_Surface *image = IMG_Load(String_to_cstring(path));
		return image;
	`}

	# Copy of an existing SDLImage
	new copy_of(image: SDLImage) `{
		SDL_Surface *new_image = SDL_CreateRGBSurface(
			image->flags, image->w, image->h, 24,
			0, 0, 0, 0);

		SDL_Rect dst;
		dst.x = 0;
		dst.y = 0;
		dst.w = image->w;
		dst.h = image->h;
		SDL_BlitSurface(image, NULL, new_image, &dst);

		return new_image;
	`}

	# Save the image into the specified file
	fun save_to_file(path: String) import String.to_cstring `{ `}

	# Destroy the image and free the memory
	redef fun destroy `{ SDL_FreeSurface(self); `}

	redef fun width `{ return self->w; `}
	redef fun height `{ return self->h; `}

	fun is_ok: Bool do return not address_is_null

	# Returns a reference to the pixels of the texture
	fun pixels: NativeCByteArray `{ return self->pixels; `}

	# Mask for the alpha value of each pixel
	fun amask: Int `{ return self->format->Amask; `}
end

# A simple rectangle
extern class SDLRectangle `{SDL_Rect*`}
	# Constructor with x,y positions width and height of the rectangle
	new (x: Int, y: Int, w: Int, h: Int) `{
		SDL_Rect *rect = malloc(sizeof(SDL_Rect));
		rect->x = (Sint16)x;
		rect->y = (Sint16)y;
		rect->w = (Uint16)w;
		rect->h = (Uint16)h;
		return rect;
	`}

	fun x=(v: Int) `{ self->x = (Sint16)v; `}
	fun x: Int `{ return self->x; `}

	fun y=(v: Int) `{ self->y = (Sint16)v; `}
	fun y: Int `{ return self->y; `}

	fun w=(v: Int) `{ self->w = (Uint16)v; `}
	fun w: Int `{ return self->w; `}

	fun h=(v: Int) `{ self->h = (Uint16)v; `}
	fun h: Int `{ return self->h; `}
end

interface SDLInputEvent
	super InputEvent
end

# MouseEvent class containing the cursor position
class SDLMouseEvent
	super PointerEvent
	super SDLInputEvent

	redef var x: Float
	redef var y: Float

	private init (x, y: Float)
	do
		self.x = x
		self.y = y
	end
end

# MouseButtonEvent used to get information when a button is pressed/depressed
class SDLMouseButtonEvent
	super SDLMouseEvent

	var button: Int

	redef var pressed
	redef fun depressed do return not pressed

	# Is this event raised by the left button?
	fun is_left_button: Bool do return button == 1

	# Is this event raised by the right button?
	fun is_right_button: Bool do return button == 3

	# Is this event raised by the middle button?
	fun is_middle_button: Bool do return button == 2

	# Is this event raised by the wheel going down?
	fun is_down_wheel: Bool do return button == 4

	# Is this event raised by the wheel going up?
	fun is_up_wheel: Bool do return button == 5

	# Is this event raised by the wheel?
	fun is_wheel: Bool do return is_down_wheel or is_up_wheel

	init (x, y: Float, button: Int, pressed: Bool)
	do
		super(x, y)

		self.button = button
		self.pressed = pressed
	end

	redef fun to_s
	do
		if pressed then
			return "MouseButtonEvent button {button} down at {x}, {y}"
		else
			return "MouseButtonEvent button {button} up at {x}, {y}"
		end
	end
end

# MouseMotionEvent to get the cursor position when the mouse is moved
class SDLMouseMotionEvent
	super SDLMouseEvent

	var rel_x: Float
	var rel_y: Float

	redef var pressed
	redef fun depressed do return not pressed

	init (x, y, rel_x, rel_y: Float, pressed: Bool)
	do
		super(x, y)

		self.rel_x = rel_x
		self.rel_y = rel_y
		self.pressed = pressed
	end

	redef fun to_s do return "MouseMotionEvent at {x}, {y}"
end

# SDLKeyEvent for when a key is pressed
class SDLKeyEvent
	super KeyEvent
	super SDLInputEvent

	redef var name
	var down: Bool

	init (key_name: String, down: Bool)
	do
		self.name = key_name
		self.down = down
	end

	redef fun to_c
	do
		if name.length == 1 then return name.chars.first
		return null
	end

	redef fun to_s
	do
		if down then
			return "KeyboardEvent key {name} down"
		else
			return "KeyboardEvent key {name} up"
		end
	end

	# Return true if the key is down, false otherwise
	redef fun is_down do return down

	# Return true if the key is the up arrow
	redef fun is_arrow_up do return name == "up"
	# Return true if the key is the left arrow
	redef fun is_arrow_left do return name == "left"
	# Return true if the key is the down arrow
	redef fun is_arrow_down do return name == "down"
	# Return true if the key is the right arrow
	redef fun is_arrow_right do return name == "right"
end

class SDLQuitEvent
	super SDLInputEvent
	super QuitEvent
end

redef class Int
	fun delay `{ SDL_Delay(self); `}
end

# Class to load and use TTF_Font
extern class SDLFont `{TTF_Font *`}
	# Load a font with a specified name and size
	new (name: String, points: Int) import String.to_cstring `{
	char * cname = String_to_cstring(name);

	TTF_Font *font = TTF_OpenFont(cname, (int)points);
	if(!font) {
		printf("TTF_OpenFont: %s\n", TTF_GetError());
		exit(1);
	}

	return font;
	`}

	fun destroy `{ TTF_CloseFont(self); `}

	# Create a String with the specified color, return an SDLImage
	fun render(text: String, r, g, b: Int): SDLImage import String.to_cstring `{
		SDL_Color color;
		SDL_Surface *text_surface;
		char *ctext;

		color.r = r;
		color.g = g;
		color.b = b;

		ctext = String_to_cstring(text);
		if(!(text_surface=TTF_RenderText_Blended(self, ctext, color)))
		{
			fprintf(stderr, "SDL TFF error: %s\n", TTF_GetError());
			exit(1);
		}
		else
			return text_surface;
	`}

	# TODO reactivate fun below when updating libsdl_ttf to 2.0.10 or above
	#fun outline: Int # TODO check to make inline/nitside only
	#fun outline=(v: Int) is extern

	#fun kerning: Bool is extern
	#fun kerning=(v: Bool) is extern

	# Maximum pixel height of all glyphs of this font.
	fun height: Int `{
		return TTF_FontHeight(self);
	`}

	fun ascent: Int `{
		return TTF_FontAscent(self);
	`}

	fun descent: Int `{
		return TTF_FontDescent(self);
	`}

	# Get the recommended pixel height of a rendered line of text of the loaded font. This is usually larger than the Font.height.
	fun line_skip: Int `{
		return TTF_FontLineSkip(self);
	`}

	# Return true is the font used fixed width for each char
	fun is_fixed_width: Bool `{
		return TTF_FontFaceIsFixedWidth(self);
	`}

	# Return the family name of the font
	fun family_name: nullable String import String.to_cstring, String.as nullable  `{
		char *fn = TTF_FontFaceFamilyName(self);

		if (fn == NULL)
			return null_String();
		else
			return String_as_nullable(NativeString_to_s(fn));
	`}

	# Return the style name of the font
	fun style_name: nullable String import String.to_cstring, String.as nullable  `{
		char *sn = TTF_FontFaceStyleName(self);

		if (sn == NULL)
			return null_String();
		else
			return String_as_nullable(NativeString_to_s(sn));
	`}

	# Return the estimated width of a String if used with the current font
	fun width_of(text: String): Int import NativeString.to_s `{
		char *ctext = String_to_cstring(text);
		int w;
		if (TTF_SizeText(self, ctext, &w, NULL))
		{
			fprintf(stderr, "SDL TFF error: %s\n", TTF_GetError());
			exit(1);
		}
		else
			return w;
	`}
end

# Information on the SDL window
# Used in other modules to get window handle
extern class SDLSystemWindowManagerInfo `{SDL_SysWMinfo *`}

	new `{
		SDL_SysWMinfo *val = malloc(sizeof(SDL_SysWMinfo));

		SDL_VERSION(&val->version);

		if(SDL_GetWMInfo(val) <= 0) {
			printf("Unable to get window handle");
			return 0;
		}

		return val;
	`}

	# Returns the handle of this window on a X11 window system
	fun x11_window_handle: Pointer `{
		return (void*)self->info.x11.window;
	`}
end
