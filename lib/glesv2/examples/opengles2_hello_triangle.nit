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

# Basic example of OpenGL ES 2.0 usage from the book OpenGL ES 2.0 Programming Guide.
#
# Code reference:
# https://code.google.com/p/opengles-book-samples/source/browse/trunk/LinuxX11/Chapter_2/Hello_Triangle/Hello_Triangle.c
module opengles2_hello_triangle

import glesv2
import egl
import sdl
import x11

if "NIT_TESTING".environ == "true" then exit(0)

var window_width = 800
var window_height = 600

#
## SDL
#
var sdl_display = new SDLDisplay(window_width, window_height)
var sdl_wm_info = new SDLSystemWindowManagerInfo
var x11_window_handle = sdl_wm_info.x11_window_handle

#
## X11
#
var x_display = x_open_default_display
assert x_display != 0 else print "x11 fail"

#
## EGL
#
var egl_display = new EGLDisplay(x_display)
assert egl_display.is_valid else print "EGL display is not valid"
egl_display.initialize

print "EGL version: {egl_display.version}"
print "EGL vendor: {egl_display.vendor}"
print "EGL extensions: {egl_display.extensions.join(", ")}"
print "EGL client APIs: {egl_display.client_apis.join(", ")}"

assert egl_display.is_valid else print egl_display.error

var config_chooser = new EGLConfigChooser
#config_chooser.surface_type_egl
config_chooser.blue_size = 8
config_chooser.green_size = 8
config_chooser.red_size = 8
#config_chooser.alpha_size = 8
#config_chooser.depth_size = 8
#config_chooser.stencil_size = 8
#config_chooser.sample_buffers = 1
config_chooser.close

var configs = config_chooser.choose(egl_display)
assert configs != null else print "choosing config failed: {egl_display.error}"
assert not configs.is_empty else print "no EGL config"

print "{configs.length} EGL configs available"
for config in configs do
	var attribs = config.attribs(egl_display)
	print "* caveats: {attribs.caveat}"
	print "  conformant to: {attribs.conformant}"
	print "  size of RGBA: {attribs.red_size} {attribs.green_size} {attribs.blue_size} {attribs.alpha_size}"
	print "  buffer, depth, stencil: {attribs.buffer_size} {attribs.depth_size} {attribs.stencil_size}"
end

var config = configs.first

# TODO android part
# Opengles1Display_midway_init(self, format);

var surface = egl_display.create_window_surface(config, x11_window_handle, [0])
assert surface.is_ok else print egl_display.error

var context = egl_display.create_context(config)
assert context.is_ok else print egl_display.error

var make_current_res = egl_display.make_current(surface, surface, context)
assert make_current_res

var width = surface.attribs(egl_display).width
var height = surface.attribs(egl_display).height
print "Width: {width}"
print "Height: {height}"

assert egl_bind_opengl_es_api else print "eglBingAPI failed: {egl_display.error}"

#
## GLESv2
#

print "Can compile shaders? {gl.shader_compiler}"
assert_no_gl_error

assert gl.shader_compiler else print "Cannot compile shaders"

# gl program
print glGetError.to_s
var program = new GLProgram
if not glIsProgram(program) then
	print "Program is not ok: {glGetError.to_s}\nLog:"
	print program.info_log
	abort
end
assert_no_gl_error

# vertex shader
var vertex_shader = new GLVertexShader
assert glIsShader(vertex_shader) else print "Vertex shader is not ok: {glGetError}"
glShaderSource(vertex_shader, """
attribute vec4 vPosition;
void main()
{
  gl_Position = vPosition;
}
""".to_cstring)
glCompileShader vertex_shader
assert vertex_shader.is_compiled else print "Vertex shader compilation failed with: {vertex_shader.info_log} {program.info_log}"
assert_no_gl_error

# fragment shader
var fragment_shader = new GLFragmentShader
assert glIsShader(fragment_shader) else print "Fragment shader is not ok: {glGetError}"
glShaderSource(fragment_shader, """
precision mediump float;
void main()
{
	gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
}
""".to_cstring)
glCompileShader(fragment_shader)
assert fragment_shader.is_compiled else print "Fragment shader compilation failed with: {fragment_shader.info_log}"
assert_no_gl_error

glAttachShader(program, vertex_shader)
glAttachShader(program, fragment_shader)
program.bind_attrib_location(0, "vPosition")
glLinkProgram program
assert program.is_linked else print "Linking failed: {program.info_log}"
assert_no_gl_error

# draw!
var vertices = [0.0, 0.5, 0.0, -0.5, -0.5, 0.0, 0.5, -0.5, 0.0]
var vertex_array = new VertexArray(0, 3, vertices)
vertex_array.attrib_pointer
glClearColor(0.5, 0.0, 0.5, 1.0)
for i in [0..10000[ do
	printn "."
	assert_no_gl_error
	glViewport(0, 0, width, height)
	glClear gl_COLOR_BUFFER_BIT
	glUseProgram program
	vertex_array.enable
	glDrawArrays(gl_TRIANGLES, 0, 3)
	egl_display.swap_buffers(surface)
end

# delete
glDeleteProgram program
glDeleteShader vertex_shader
glDeleteShader fragment_shader

#
## EGL
#
# close
egl_display.make_current(new EGLSurface.none, new EGLSurface.none, new EGLContext.none)
egl_display.destroy_context context
egl_display.destroy_surface surface

#
## SDL
#
# close
sdl_display.destroy
