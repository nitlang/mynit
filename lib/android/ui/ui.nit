# This file is part of NIT (http://www.nitlanguage.org).
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

# Views and services to use the Android native user interface
module ui

# Implementation note:
#
# We cannot rely on `Activity::on_restore_instance_state` to implement
# `on_restore_state` is it only invoked if there is a bundled state,
# and we don't use the Android bundled state.

import native_ui
import log
import nit_activity

import app::ui
private import data_store

redef class Control
	# The Android element used to implement `self`
	fun native: NATIVE is abstract

	# Type of `native`
	type NATIVE: JavaObject
end

redef class Window
	redef var native = app.native_activity.new_global_ref

	redef type NATIVE: NativeActivity

	redef fun add(item)
	do
		super

		# FIXME abstract the Android restriction where `content_view` must be a layout
		assert item isa Layout
		native.content_view = item.native
	end
end

redef class View
	redef type NATIVE: NativeView

	redef fun enabled=(enabled) do native.enabled = enabled or else true
	redef fun enabled do return native.enabled
end

redef class Layout
	redef type NATIVE: NativeViewGroup

	redef fun add(item)
	do
		super

		assert item isa View

		# FIXME abstract the use either homogeneous or weight to balance views size in a layout
		native.add_view_with_weight(item.native, 1.0)
	end

	redef fun remove(item)
	do
		super
		if item isa View then native.remove_view item.native
	end
end

redef class HorizontalLayout
	redef var native do
		var layout = new NativeLinearLayout(app.native_activity)
		layout = layout.new_global_ref
		layout.set_horizontal
		return layout
	end
end

redef class VerticalLayout
	redef var native do
		var layout = new NativeLinearLayout(app.native_activity)
		layout = layout.new_global_ref
		layout.set_vertical
		return layout
	end
end

redef class ListLayout
	redef type NATIVE: Android_widget_ListView

	redef var native do
		var layout = new Android_widget_ListView(app.native_activity)
		layout = layout.new_global_ref
		return layout
	end

	private var adapter: Android_widget_ArrayAdapter do
		var adapter = new Android_widget_ArrayAdapter(app.native_activity,
			android_r_layout_simple_list_item_1, self)
		native.set_adapter adapter
		return adapter
	end

	redef fun add(item)
	do
		super
		if item isa View then adapter.add item.native
	end

	private fun create_view(position: Int): NativeView
	do
		var ctrl = items[position]
		assert ctrl isa View
		return ctrl.native
	end
end

redef class Android_widget_ArrayAdapter
	private new (context: NativeContext, res: Int, sender: ListLayout)
	import ListLayout.create_view in "Java" `{
		final int final_sender_object = sender;

		return new android.widget.ArrayAdapter(context, (int)res) {
				@Override
				public android.view.View getView(int position, android.view.View convertView, android.view.ViewGroup parent) {
					return ListLayout_create_view(final_sender_object, position);
				}
			};
	`}
end

redef class TextView
	redef type NATIVE: NativeTextView

	redef fun text do return native.text.to_s
	redef fun text=(value) do
		if value == null then value = ""
		native.text = value.to_java_string
	end

	# Size of the text
	fun text_size: Float do return native.text_size

	# Size of the text
	fun text_size=(text_size: nullable Float) do
		if text_size != null then native.text_size = text_size
	end
end

redef class Label
	redef type NATIVE: NativeTextView
	redef var native do return (new NativeTextView(app.native_activity)).new_global_ref

	init do native.set_text_appearance(app.native_activity, android_r_style_text_appearance_medium)
end

redef class TextInput
	redef type NATIVE: NativeEditText
	redef var native = (new NativeEditText(app.native_activity)).new_global_ref
end

redef class Button
	super Finalizable

	redef type NATIVE: NativeButton
	redef var native = (new NativeButton(app.native_activity, self)).new_global_ref

	private fun on_click do notify_observers new ButtonPressEvent(self)

	redef fun finalize do native.delete_global_ref
end

redef class NativeButton
	private new (context: NativeActivity, sender_object: Button)
	import Button.on_click in "Java" `{
		final int final_sender_object = sender_object;

		return new android.widget.Button(context){
			@Override
			public boolean onTouchEvent(android.view.MotionEvent event) {
				if(event.getAction() == android.view.MotionEvent.ACTION_DOWN) {
					Button_on_click(final_sender_object);
					return true;
				}
				return false;
			}
		};
	`}
end
