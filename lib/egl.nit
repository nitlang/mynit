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

# EGL is an interface between the rendering APIs OpenGL, OpenGL ES, etc.
# and the native windowing system.
#
# Most services of this module are a direct wrapper of the underlying
# C library. If a method or class is not documented in Nit, refer to
# the official documentation by the Khronos Group at:
# http://www.khronos.org/registry/egl/sdk/docs/man/xhtml/
module egl is pkgconfig("egl")

in "C Header" `{
	#include <EGL/egl.h>
`}

extern class EGLNativeDisplayType `{ EGLNativeDisplayType `}
	new from_x11(handle: Pointer) `{ return (EGLNativeDisplayType)handle; `}
end

extern class EGLDisplay `{ EGLDisplay `}
	new current `{ return eglGetCurrentDisplay(); `}
	new(handle: Pointer) `{ return eglGetDisplay(handle); `}

	fun is_valid: Bool `{ return recv != EGL_NO_DISPLAY; `}

	fun initialize: Bool `{
		EGLBoolean r = eglInitialize(recv, NULL, NULL);
		if (r == EGL_FALSE) {
			fprintf(stderr, "Unable to eglInitialize");
			return 0;
		}
		return 1;
	`}

	fun major_version: Int `{
		EGLint val;
		eglInitialize(recv, &val, NULL);
		return val;
	`}
	fun minor_version: Int `{
		EGLint val;
		eglInitialize(recv, NULL, &val);
		return val;
	`}

	# TODO if useful
	# Returns all configs supported by the hardware
	#fun get_configs: nullable Array[EGLConfig] import Array[EGLConfig].with_native `{

	# Returns some configs compatible with the specified `attributes`
	fun choose_configs(attribs: Array[Int]): nullable Array[EGLConfig] import Array[Int].length, Array[Int].[], Array[EGLConfig], Array[EGLConfig].add, Array[EGLConfig] as nullable, report_egl_error `{
		EGLConfig *configs;
		int n_configs;
		int n_attribs = Array_of_Int_length(attribs);
		int i;
		int *c_attribs = malloc(sizeof(int)*n_attribs);
		for (i = 0; i < n_attribs; i ++) {
			c_attribs[i] = Array_of_Int__index(attribs, i);
		}

		// get number of configs
		EGLBoolean r = eglChooseConfig(recv, c_attribs, NULL, 0, &n_configs);

		if (r == EGL_FALSE) {
			EGLDisplay_report_egl_error(recv, "failed to get number of available configs.");
			return null_Array_of_EGLConfig();
		} else if (n_configs == 0) {
			EGLDisplay_report_egl_error(recv, "no config available.");
			return null_Array_of_EGLConfig();
		}

		configs = (EGLConfig*)malloc(sizeof(EGLConfig)*n_configs);
 
		r = eglChooseConfig(recv, c_attribs, configs, n_configs, &n_configs);

		if (r == EGL_FALSE) {
			EGLDisplay_report_egl_error(recv, "failed to load config.");
			return null_Array_of_EGLConfig();
		} else {
			Array_of_EGLConfig array = new_Array_of_EGLConfig();
			for (i=0; i < n_configs; i++)
				Array_of_EGLConfig_add(array, configs[i]);

			return Array_of_EGLConfig_as_nullable(array);
		}
	`}

	# Can be used directly, but it is preferable to use a `EGLConfigAttribs`
	fun config_attrib(config: EGLConfig, attribute: Int): Int `{
		EGLint val;
		EGLBoolean r = eglGetConfigAttrib(recv, config, attribute, &val);
		if (r == EGL_FALSE)
			return -1;
		else
			return val;
	`}

	fun terminate: Bool `{
		return eglTerminate(recv) == EGL_TRUE;
	`}

	fun create_window_surface(config: EGLConfig, native_window: Pointer, attribs: Array[Int]): EGLSurface `{
		EGLSurface surface = eglCreateWindowSurface(recv, config, (EGLNativeWindowType)native_window, NULL);
		return surface;
	`}

	# TODO add share_context
	fun create_context(config: EGLConfig): EGLContext `{
		EGLint context_attribs[] = {EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE, EGL_NONE}; // TODO move out!
		EGLContext context = eglCreateContext(recv, config, EGL_NO_CONTEXT, context_attribs);
		return context;
	`}

	fun make_current(draw, read: EGLSurface, context: EGLContext): Bool `{
		if (eglMakeCurrent(recv, draw, read, context) == EGL_FALSE) {
			fprintf(stderr, "Unable to eglMakeCurrent");
			return 0;
		}
		return 1;
	`}

	# Can be used directly, but it is preferable to use a `EGLSurfaceAttribs`
	fun query_surface(surface: EGLSurface, attribute: Int): Int `{
		int val;
		EGLBoolean r = eglQuerySurface(recv, surface, attribute, &val);
		if (r == EGL_FALSE)
			return -1;
		else
			return val;
	`}

	fun destroy_context(context: EGLContext): Bool `{
		return eglDestroyContext(recv, context);
	`}

	fun destroy_surface(surface: EGLSurface): Bool `{
		return eglDestroySurface(recv, surface);
	`}

	fun error: EGLError `{ return eglGetError(); `}

	# Utility method for easier debugging
	fun assert_no_egl_error
	do
		var error = self.error
		if not error.is_success then
			print "EGL error: {error}"
			abort
		end
	end

	private fun query_string(name: Int): String import NativeString.to_s `{
		return (void*)(long)NativeString_to_s(eglQueryString(recv, name));
	`}

	fun vendor: String do return query_string("3053".to_hex)

	fun version: String do return query_string("3054".to_hex)

	fun extensions: Array[String] do return query_string("3055".to_hex).split_with(" ")

	fun client_apis: Array[String] do return query_string("308D".to_hex).split_with(" ")

	fun swap_buffers(surface: EGLSurface) `{ eglSwapBuffers(recv, surface); `}
end

extern class EGLConfig `{ EGLConfig `}
	fun attribs(display: EGLDisplay): EGLConfigAttribs do
		return new EGLConfigAttribs(display, self)
	end
end

extern class EGLSurface `{ EGLSurface `}
	new current_draw `{ return eglGetCurrentSurface(EGL_DRAW); `}
	new current_read `{ return eglGetCurrentSurface(EGL_READ); `}
	new none `{ return EGL_NO_SURFACE; `}

	fun is_ok: Bool `{ return recv != EGL_NO_SURFACE; `}

	fun attribs(display: EGLDisplay): EGLSurfaceAttribs do
		return new EGLSurfaceAttribs(display, self)
	end
end

extern class EGLContext `{ EGLContext `}
	new current `{ return eglGetCurrentContext(); `}
	new none `{ return EGL_NO_CONTEXT; `}

	fun is_ok: Bool `{ return recv != EGL_NO_CONTEXT; `}
end

# Attributes of a config for a given EGL display
class EGLConfigAttribs
	var display: EGLDisplay
	var config: EGLConfig

	fun alpha_size: Int do return display.config_attrib(config, "3021".to_hex)
	fun native_visual_id: Int do return display.config_attrib(config, "302E".to_hex)
	fun native_visual_type: Int do return display.config_attrib(config, "302F".to_hex)
end

# Attributes of a surface for a given EGL display
class EGLSurfaceAttribs
	var display: EGLDisplay
	var surface: EGLSurface

	fun height: Int do return display.query_surface(surface, "3056".to_hex)
	fun width: Int do return display.query_surface(surface, "3057".to_hex)
	fun largest_pbuffer: Int do return display.query_surface(surface, "3058".to_hex)
	fun texture_format: Int do return display.query_surface(surface, "3080".to_hex)
	fun texture_target: Int do return display.query_surface(surface, "3081".to_hex)
	fun mipmap_texture: Int do return display.query_surface(surface, "3082".to_hex)
	fun mipmap_level: Int do return display.query_surface(surface, "3083".to_hex)
	fun render_buffer: Int do return display.query_surface(surface, "3086".to_hex)
	fun vg_colorspace: Int do return display.query_surface(surface, "3087".to_hex)
	fun vg_alpha_format: Int do return display.query_surface(surface, "3088".to_hex)
	fun horizontal_resolution: Int do return display.query_surface(surface, "3090".to_hex)
	fun vertical_resolution: Int do return display.query_surface(surface, "3091".to_hex)
	fun pixel_aspect_ratio: Int do return display.query_surface(surface, "3092".to_hex)
	fun swap_behavior: Int do return display.query_surface(surface, "3093".to_hex)
	fun multisample_resolve: Int do return display.query_surface(surface, "3099".to_hex)
end

extern class EGLError `{ EGLint `}
	fun is_success: Bool `{ return recv == EGL_SUCCESS; `}

	fun is_not_initialized: Bool `{ return recv == EGL_NOT_INITIALIZED; `}
	fun is_bad_access: Bool `{ return recv == EGL_BAD_ACCESS; `}
	fun is_bad_alloc: Bool `{ return recv == EGL_BAD_ALLOC; `}
	fun is_bad_attribute: Bool `{ return recv == EGL_BAD_ATTRIBUTE; `}
	fun is_bad_config: Bool `{ return recv == EGL_BAD_CONFIG; `}
	fun is_bad_context: Bool `{ return recv == EGL_BAD_CONTEXT; `}
	fun is_bad_current_surface: Bool `{ return recv == EGL_BAD_CURRENT_SURFACE; `}
	fun is_bad_display: Bool `{ return recv == EGL_BAD_DISPLAY; `}
	fun is_bad_match: Bool `{ return recv == EGL_BAD_MATCH; `}
	fun is_bad_native_pixmap: Bool `{ return recv == EGL_BAD_NATIVE_PIXMAP; `}
	fun is_bad_native_window: Bool `{ return recv == EGL_BAD_NATIVE_WINDOW; `}
	fun is_bad_parameter: Bool `{ return recv == EGL_BAD_PARAMETER; `}
	fun is_bad_surface: Bool `{ return recv == EGL_BAD_SURFACE; `}
	fun is_context_lost: Bool `{ return recv == EGL_CONTEXT_LOST; `}

	redef fun to_s
	do
		if is_not_initialized then return "Not initialized"
		if is_bad_access then return "Bad access"
		if is_bad_alloc then return "Bad allocation"
		if is_bad_attribute then return "Bad attribute"
		if is_bad_config then return "Bad configuration"
		if is_bad_context then return "Bad context"
		if is_bad_current_surface then return "Bad current surface"
		if is_bad_display then return "Bad display"
		if is_bad_match then return "Bad match"
		if is_bad_native_pixmap then return "Bad native pixmap"
		if is_bad_native_window then return "Bad native window"
		if is_bad_parameter then return "Bad parameter"
		if is_bad_surface then return "Bad surface"
		if is_context_lost then return "Context lost"
		return "Unknown error" # this is not good
	end
end

extern class EGLContextAttribute `{ EGLint `}
	new buffer_size `{ return EGL_BUFFER_SIZE; `}
	new alpha_size `{ return EGL_ALPHA_SIZE; `}
	new blue_size `{ return EGL_BLUE_SIZE; `}
	new green_size `{ return EGL_GREEN_SIZE; `}
	new red_size `{ return EGL_RED_SIZE; `}
	new depth_size `{ return EGL_DEPTH_SIZE; `}
	new stencil_size `{ return EGL_STENCIL_SIZE; `}
	new config_caveat `{ return EGL_CONFIG_CAVEAT; `}
	new config_id `{ return EGL_CONFIG_ID; `}
	new level `{ return EGL_LEVEL; `}
	new max_pbuffer_height `{ return EGL_MAX_PBUFFER_HEIGHT; `}
	new max_pbuffer_pixels `{ return EGL_MAX_PBUFFER_PIXELS; `}
	new max_pbuffer_width `{ return EGL_MAX_PBUFFER_WIDTH; `}
	new native_renderable `{ return EGL_NATIVE_RENDERABLE; `}
	new native_visual_id `{ return EGL_NATIVE_VISUAL_ID; `}
	new native_visual_type `{ return EGL_NATIVE_VISUAL_TYPE; `}
	new samples `{ return EGL_SAMPLES; `}
	new sample_buffers `{ return EGL_SAMPLE_BUFFERS; `}
	new surface_type `{ return EGL_SURFACE_TYPE; `}
	new transparent_type `{ return EGL_TRANSPARENT_TYPE; `}
	new transparent_blue_value `{ return EGL_TRANSPARENT_BLUE_VALUE; `}
	new transparent_green_value `{ return EGL_TRANSPARENT_GREEN_VALUE; `}
	new transparent_red_value `{ return EGL_TRANSPARENT_RED_VALUE; `}
	new bind_to_texture_rgb `{ return EGL_BIND_TO_TEXTURE_RGB; `}
	new bind_to_texture_rgba `{ return EGL_BIND_TO_TEXTURE_RGBA; `}
	new min_swap_interval `{ return EGL_MIN_SWAP_INTERVAL; `}
	new max_swap_interval `{ return EGL_MAX_SWAP_INTERVAL; `}
	new limunance_size `{ return EGL_LUMINANCE_SIZE; `}
	new alpha_mask_size `{ return EGL_ALPHA_MASK_SIZE; `}
	new color_buffer_type `{ return EGL_COLOR_BUFFER_TYPE; `}
	new renderable_type `{ return EGL_RENDERABLE_TYPE; `}
	new match_native_pixmap `{ return EGL_MATCH_NATIVE_PIXMAP; `}
	new conformant `{ return EGL_CONFORMANT; `}

	# Attrib list terminator
	new none `{ return EGL_NONE; `}
end

# Utility class to choose an EGLConfig
class EGLConfigChooser
	var array = new Array[Int]
	var closed = false
	protected var inserted_attribs = new Array[Int]

	protected fun insert_attrib_key(key: Int)
	do
		assert not inserted_attribs.has(key) else
			print "Duplicate attrib passed to EGLConfigChooser"
		end
		array.add key
	end

	protected fun insert_attrib_with_val(key, val: Int)
	do
		insert_attrib_key key
		array.add val
	end

	fun close do
		insert_attrib_key "3038".to_hex
		closed = true
	end

	fun surface_type=(flag: Int) do insert_attrib_with_val("3033".to_hex, flag)
	fun surface_type_egl do surface_type = 4

	fun blue_size=(size: Int) do insert_attrib_with_val("3022".to_hex, size)
	fun green_size=(size: Int) do insert_attrib_with_val("3023".to_hex, size)
	fun red_size=(size: Int) do insert_attrib_with_val("3024".to_hex, size)

	fun alpha_size=(size: Int) do insert_attrib_with_val("3021".to_hex, size)
	fun depth_size=(size: Int) do insert_attrib_with_val("3025".to_hex, size)
	fun stencil_size=(size: Int) do insert_attrib_with_val("3026".to_hex, size)
	fun sample_buffers=(size: Int) do insert_attrib_with_val("3031".to_hex, size)

	fun choose(display: EGLDisplay): nullable Array[EGLConfig]
	do
		assert closed else print "EGLConfigChooser not closed."
		return display.choose_configs(array)
	end
end

redef class Object
	private fun report_egl_error(cmsg: NativeString)
	do
		var msg = cmsg.to_s
		print "libEGL error: {msg}"
	end
end

protected fun egl_bind_opengl_api: Bool `{ return eglBindAPI(EGL_OPENGL_API); `}
protected fun egl_bind_opengl_es_api: Bool `{ return eglBindAPI(EGL_OPENGL_ES_API); `}
protected fun egl_bind_openvg_api: Bool `{ return eglBindAPI(EGL_OPENVG_API); `}
