# This file is part of NIT (http://www.nitlanguage.org).
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

# Native services from the `android.view` and `android.widget` namespaces
module native_ui is android_api_min 14

import nit_activity

in "Java" `{
	import android.app.Activity;

	import android.view.Gravity;
	import android.view.View;
	import android.view.ViewGroup;
	import android.view.ViewGroup.MarginLayoutParams;

	import android.widget.Button;
	import android.widget.LinearLayout;
	import android.widget.GridLayout;
	import android.widget.PopupWindow;
	import android.widget.TextView;

	import java.lang.*;
	import java.util.*;
`}

redef extern class NativeActivity

	# Set the main layout of this activity
	fun content_view=(layout: NativeViewGroup) in "Java" `{
		final ViewGroup final_layout = layout;
		final Activity final_self = self;

		self.runOnUiThread(new Runnable() {
			@Override
			public void run()  {
				final_self.setContentView(final_layout);

				final_layout.requestFocus();
			}
		});
	`}
end

# A `View` for Android
extern class NativeView in "Java" `{ android.view.View `}
	super JavaObject

	fun minimum_width=(val: Int) in "Java" `{ self.setMinimumWidth((int)val); `}
	fun minimum_height=(val: Int) in "Java" `{ self.setMinimumHeight((int)val); `}

	fun enabled: Bool in "Java" `{ return self.isEnabled(); `}
	fun enabled=(value: Bool) in "Java" `{
		final View final_self = self;
		final boolean final_value = value;

		((Activity)self.getContext()).runOnUiThread(new Runnable() {
			@Override
			public void run()  {
				final_self.setEnabled(final_value);
			}
		});
	`}
end

# A collection of `NativeView`
extern class NativeViewGroup in "Java" `{ android.view.ViewGroup `}
	super NativeView

	fun add_view(view: NativeView) in "Java" `{ self.addView(view); `}

	fun add_view_with_weight(view: NativeView, weight: Float)
	in "Java" `{
		self.addView(view, new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.MATCH_PARENT, (float)weight));
	`}
end

# A `NativeViewGroup` organized in a line
extern class NativeLinearLayout in "Java" `{ android.widget.LinearLayout `}
	super NativeViewGroup

	new(context: NativeActivity) in "Java" `{ return new LinearLayout(context); `}

	fun set_vertical in "Java" `{ self.setOrientation(LinearLayout.VERTICAL); `}
	fun set_horizontal in "Java" `{ self.setOrientation(LinearLayout.HORIZONTAL); `}

	redef fun add_view(view) in "Java"
	`{
		MarginLayoutParams params = new MarginLayoutParams(
			LinearLayout.LayoutParams.MATCH_PARENT,
			LinearLayout.LayoutParams.WRAP_CONTENT);
		self.addView(view, params);
	`}
end

# A `NativeViewGroup` organized as a grid
extern class NativeGridLayout in "Java" `{ android.widget.GridLayout `}
	super NativeViewGroup

	new(context: NativeActivity) in "Java" `{ return new android.widget.GridLayout(context); `}

	fun row_count=(val: Int) in "Java" `{ self.setRowCount((int)val); `}

	fun column_count=(val: Int) in "Java" `{ self.setColumnCount((int)val); `}

	redef fun add_view(view) in "Java" `{ self.addView(view); `}
end

extern class NativePopupWindow in "Java" `{ android.widget.PopupWindow `}
	super NativeView

	new (context: NativeActivity) in "Java" `{
		PopupWindow self = new PopupWindow(context);
		self.setWindowLayoutMode(LinearLayout.LayoutParams.MATCH_PARENT,
			LinearLayout.LayoutParams.MATCH_PARENT);
		self.setClippingEnabled(false);
		return self;
	`}

	fun content_view=(layout: NativeViewGroup) in "Java" `{ self.setContentView(layout); `}
end

extern class NativeTextView in "Java" `{ android.widget.TextView `}
	super NativeView

	new (context: NativeActivity) in "Java" `{ return new TextView(context); `}

	fun text: JavaString in "Java" `{ return self.getText().toString(); `}

	fun text=(value: JavaString) in "Java" `{

		final TextView final_self = self;
		final String final_value = value;

		((Activity)self.getContext()).runOnUiThread(new Runnable() {
			@Override
			public void run()  {
				final_self.setText(final_value);
			}
		});
	`}

	fun gravity_center in "Java" `{
		self.setGravity(Gravity.CENTER);
	`}

	fun text_size: Float in "Java" `{
		return self.getTextSize();
	`}
	fun text_size=(dpi: Float) in "Java" `{
		self.setTextSize(android.util.TypedValue.COMPLEX_UNIT_DIP, (float)dpi);
	`}
end

extern class NativeEditText in "Java" `{ android.widget.EditText `}
	super NativeTextView

	redef type SELF: NativeEditText

	new (context: NativeActivity) in "Java" `{ return new android.widget.EditText(context); `}

	fun width=(val: Int) in "Java" `{ self.setWidth((int)val); `}

	fun input_type_text in "Java" `{ self.setInputType(android.text.InputType.TYPE_CLASS_TEXT); `}

	redef fun new_global_ref: SELF import sys, Sys.jni_env `{
		Sys sys = NativeEditText_sys(self);
		JNIEnv *env = Sys_jni_env(sys);
		return (*env)->NewGlobalRef(env, self);
	`}
end

extern class NativeButton in "Java" `{ android.widget.Button `}
	super NativeTextView

	redef type SELF: NativeButton

	redef fun new_global_ref: SELF import sys, Sys.jni_env `{
		Sys sys = NativeButton_sys(self);
		JNIEnv *env = Sys_jni_env(sys);
		return (*env)->NewGlobalRef(env, self);
	`}
end
