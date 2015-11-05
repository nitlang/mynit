<span class="nitcode"><span class="line" id="L1"><span class="nc_c"># This file is part of NIT ( http:&#47;&#47;www.nitlanguage.org ).
</span></span><span class="line" id="L2"><span class="nc_c">#
</span></span><span class="line" id="L3"><span class="nc_c"># Copyright 2006-2008 Jean Privat &lt;jean@pryen.org&gt;
</span></span><span class="line" id="L4"><span class="nc_c">#
</span></span><span class="line" id="L5"><span class="nc_c"># Licensed under the Apache License, Version 2.0 (the &#34;License&#34;);
</span></span><span class="line" id="L6"><span class="nc_c"># you may not use this file except in compliance with the License.
</span></span><span class="line" id="L7"><span class="nc_c"># You may obtain a copy of the License at
</span></span><span class="line" id="L8"><span class="nc_c">#
</span></span><span class="line" id="L9"><span class="nc_c">#     http:&#47;&#47;www.apache.org&#47;licenses&#47;LICENSE-2.0
</span></span><span class="line" id="L10"><span class="nc_c">#
</span></span><span class="line" id="L11"><span class="nc_c"># Unless required by applicable law or agreed to in writing, software
</span></span><span class="line" id="L12"><span class="nc_c"># distributed under the License is distributed on an &#34;AS IS&#34; BASIS,
</span></span><span class="line" id="L13"><span class="nc_c"># WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
</span></span><span class="line" id="L14"><span class="nc_c"># See the License for the specific language governing permissions and
</span></span><span class="line" id="L15"><span class="nc_c"># limitations under the License.
</span></span><span class="line" id="L16">
</span><span class="line" id="L17"><span class="nc_k">import</span> <span class="nc_k">end</span>
</span><span class="line" id="L18">
</span><span class="nc_cdef foldable" id="base_simple3#Object"><span class="line" id="L19"><span class="nc_k">interface</span> <span class="nc_def nc_t">Object</span>
</span><span class="line" id="L20"><span class="nc_k">end</span>
</span></span><span class="line" id="L21">
</span><span class="nc_cdef foldable" id="base_simple3#Bool"><span class="line" id="L22"><span class="nc_k">enum</span> <span class="nc_def nc_t">Bool</span>
</span><span class="line" id="L23"><span class="nc_k">end</span>
</span></span><span class="line" id="L24">
</span><span class="nc_cdef foldable" id="base_simple3#Int"><span class="line" id="L25"><span class="nc_k">enum</span> <span class="nc_def nc_t">Int</span>
</span><span class="nc_pdef foldable" id="base_simple3#Int#output"><span class="line" id="L26">	<span class="nc_k">fun</span> <span class="nc_def popupable" title="base_simple3#Int#output" data-title="&lt;a href=&#34;base_simple3.html#base_simple3#Int#output&#34;&gt;base_simple3#Int#output&lt;&#47;a&gt;" data-content="&lt;div&gt;&lt;b&gt;fun&lt;&#47;b&gt; &lt;span&gt;output&lt;span&gt;&lt;&#47;span&gt;&lt;&#47;span&gt;&lt;br&#47;&gt;&lt;&#47;div&gt;" data-toggle="popover"><span class="nc_i">output</span></span> <span class="nc_k">is</span> <span class="nc_i">intern</span>
</span></span><span class="line" id="L27"><span class="nc_k">end</span>
</span></span><span class="line" id="L28">
</span><span class="nc_cdef foldable" id="base_simple3#A"><span class="line" id="L29"><span class="nc_k">class</span> <span class="nc_def nc_t">A</span>
</span><span class="nc_pdef foldable" id="base_simple3#A#init"><span class="line" id="L30">	<span class="nc_k">init</span> <span class="nc_k">do</span> <span class="nc_l">5</span><span>.</span><span class="nc_i">output</span>
</span></span><span class="nc_pdef foldable" id="base_simple3#A#run"><span class="line" id="L31">	<span class="nc_k">fun</span> <span class="nc_def popupable" title="base_simple3#A#run" data-title="&lt;a href=&#34;base_simple3.html#base_simple3#A#run&#34;&gt;base_simple3#A#run&lt;&#47;a&gt;" data-content="&lt;div&gt;&lt;b&gt;fun&lt;&#47;b&gt; &lt;span&gt;run&lt;span&gt;&lt;&#47;span&gt;&lt;&#47;span&gt;&lt;br&#47;&gt;&lt;&#47;div&gt;" data-toggle="popover"><span class="nc_i">run</span></span> <span class="nc_k">do</span> <span class="nc_l">6</span><span>.</span><span class="nc_i">output</span>
</span></span><span class="line" id="L32"><span class="nc_k">end</span>
</span></span><span class="line" id="L33">
</span><span class="nc_cdef foldable" id="base_simple3#B"><span class="line" id="L34"><span class="nc_k">class</span> <span class="nc_def nc_t">B</span>
</span><span class="nc_pdef foldable" id="base_simple3#B#_val"><a id="base_simple3#B#val"></a><a id="base_simple3#B#val="></a><span class="line" id="L35">	<span class="nc_k">var</span> <span class="nc_def nc_i">val</span><span>:</span> <span class="nc_t">Int</span>
</span></span><span class="nc_pdef foldable" id="base_simple3#B#init"><span class="line" id="L36">	<span class="nc_k">init</span><span>(</span><span class="nc_v nc_i">v</span><span>:</span> <span class="nc_t">Int</span><span>)</span>
</span><span class="line" id="L37">	<span class="nc_k">do</span>
</span><span class="line" id="L38">		<span class="nc_l">7</span><span>.</span><span class="nc_i">output</span>
</span><span class="line" id="L39">		<span class="nc_k">self</span><span>.</span><span class="nc_i">val</span> <span>=</span> <span class="nc_v nc_i">v</span>
</span><span class="line" id="L40">	<span class="nc_k">end</span>
</span></span><span class="nc_pdef foldable" id="base_simple3#B#run"><span class="line" id="L41">	<span class="nc_k">fun</span> <span class="nc_def popupable" title="base_simple3#B#run" data-title="&lt;a href=&#34;base_simple3.html#base_simple3#B#run&#34;&gt;base_simple3#B#run&lt;&#47;a&gt;" data-content="&lt;div&gt;&lt;b&gt;fun&lt;&#47;b&gt; &lt;span&gt;run&lt;span&gt;&lt;&#47;span&gt;&lt;&#47;span&gt;&lt;br&#47;&gt;&lt;&#47;div&gt;" data-toggle="popover"><span class="nc_i">run</span></span> <span class="nc_k">do</span> <span class="nc_i">val</span><span>.</span><span class="nc_i">output</span>
</span></span><span class="line" id="L42"><span class="nc_k">end</span>
</span></span><span class="line" id="L43">
</span><span class="nc_cdef foldable" id="base_simple3#C"><span class="line" id="L44"><span class="nc_k">class</span> <span class="nc_def nc_t">C</span>
</span><span class="nc_pdef foldable" id="base_simple3#C#_val1"><a id="base_simple3#C#val1"></a><a id="base_simple3#C#val1="></a><span class="line" id="L45">	<span class="nc_k">var</span> <span class="nc_def nc_i">val1</span><span>:</span> <span class="nc_t">Int</span>
</span></span><span class="nc_pdef foldable" id="base_simple3#C#_val2"><a id="base_simple3#C#val2"></a><a id="base_simple3#C#val2="></a><span class="line" id="L46">	<span class="nc_k">var</span> <span class="nc_def nc_i">val2</span><span>:</span> <span class="nc_t">Int</span> <span>=</span> <span class="nc_l">10</span>
</span></span><span class="line" id="L47"><span class="nc_k">end</span>
</span></span><span class="line" id="L48">
</span><span class="nc_pdef foldable" id="base_simple3#Sys#foo"><span class="line" id="L49"><span class="nc_k">fun</span> <span class="nc_def popupable" title="base_simple3#Sys#foo" data-title="&lt;a href=&#34;base_simple3.html#base_simple3#Sys#foo&#34;&gt;base_simple3#Sys#foo&lt;&#47;a&gt;" data-content="&lt;div&gt;&lt;b&gt;fun&lt;&#47;b&gt; &lt;span&gt;foo&lt;span&gt;&lt;&#47;span&gt;&lt;&#47;span&gt;&lt;br&#47;&gt;&lt;&#47;div&gt;" data-toggle="popover"><span class="nc_i">foo</span></span> <span class="nc_k">do</span> <span class="nc_l">2</span><span>.</span><span class="nc_i">output</span>
</span></span><span class="nc_pdef foldable" id="base_simple3#Sys#bar"><span class="line" id="L50"><span class="nc_k">fun</span> <span class="nc_def popupable" title="base_simple3#Sys#bar" data-title="&lt;a href=&#34;base_simple3.html#base_simple3#Sys#bar&#34;&gt;base_simple3#Sys#bar&lt;&#47;a&gt;" data-content="&lt;div&gt;&lt;b&gt;fun&lt;&#47;b&gt; &lt;span&gt;bar&lt;span&gt;(i: &lt;a href=&#34;base_simple3.html#base_simple3#Int&#34;&gt;Int&lt;&#47;a&gt;)&lt;&#47;span&gt;&lt;&#47;span&gt;&lt;br&#47;&gt;&lt;&#47;div&gt;" data-toggle="popover"><span class="nc_i">bar</span></span><span>(</span><span class="nc_v nc_i">i</span><span>:</span> <span class="nc_t">Int</span><span>)</span> <span class="nc_k">do</span> <span class="nc_v nc_i">i</span><span>.</span><span class="nc_i">output</span>
</span></span><span class="nc_pdef foldable" id="base_simple3#Sys#baz"><span class="line" id="L51"><span class="nc_k">fun</span> <span class="nc_def popupable" title="base_simple3#Sys#baz" data-title="&lt;a href=&#34;base_simple3.html#base_simple3#Sys#baz&#34;&gt;base_simple3#Sys#baz&lt;&#47;a&gt;" data-content="&lt;div&gt;&lt;b&gt;fun&lt;&#47;b&gt; &lt;span&gt;baz&lt;span&gt;: &lt;a href=&#34;base_simple3.html#base_simple3#Int&#34;&gt;Int&lt;&#47;a&gt;&lt;&#47;span&gt;&lt;&#47;span&gt;&lt;br&#47;&gt;&lt;&#47;div&gt;" data-toggle="popover"><span class="nc_i">baz</span></span><span>:</span> <span class="nc_t">Int</span> <span class="nc_k">do</span> <span class="nc_k">return</span> <span class="nc_l">4</span>
</span></span><span class="line" id="L52">
</span><span class="nc_pdef foldable" id="base_simple3#Sys#main"><span class="line" id="L53"><span class="nc_l">1</span><span>.</span><span class="nc_i">output</span>
</span><span class="line" id="L54"><span class="nc_i">foo</span>
</span><span class="line" id="L55"><span class="nc_i">bar</span><span>(</span><span class="nc_l">3</span><span>)</span>
</span><span class="line" id="L56"><span class="nc_i">baz</span><span>.</span><span class="nc_i">output</span>
</span><span class="line" id="L57">
</span><span class="line" id="L58"><span class="nc_k">var</span> <span class="nc_v nc_i">a</span> <span>=</span> <span class="nc_k">new</span> <span class="nc_t">A</span>
</span><span class="line" id="L59"><span class="nc_v nc_i">a</span><span>.</span><span class="nc_i">run</span>
</span><span class="line" id="L60">
</span><span class="line" id="L61"><span class="nc_k">var</span> <span class="nc_v nc_i">b</span> <span>=</span> <span class="nc_k">new</span> <span class="nc_t">B</span><span>(</span><span class="nc_l">8</span><span>)</span>
</span><span class="line" id="L62"><span class="nc_v nc_i">b</span><span>.</span><span class="nc_i">run</span>
</span><span class="line" id="L63">
</span><span class="line" id="L64"><span class="nc_k">var</span> <span class="nc_v nc_i">c</span> <span>=</span> <span class="nc_k">new</span> <span class="nc_t">C</span><span>(</span><span class="nc_l">9</span><span>)</span>
</span><span class="line" id="L65"><span class="nc_v nc_i">c</span><span>.</span><span class="nc_i">val1</span><span>.</span><span class="nc_i">output</span>
</span><span class="line" id="L66"><span class="nc_v nc_i">c</span><span>.</span><span class="nc_i">val2</span><span>.</span><span class="nc_i">output</span>
</span></span></span>