# This file is part of NIT (http://www.nitlanguage.org).
#
# Copyright 2013 Jean-Philippe Caissy <jpcaissy@piji.ca>
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

# Low-level wrapper around the libevent library to manage events on file descriptors
#
# For mor information, refer to the libevent documentation at
# http://monkey.org/~provos/libevent/doxygen-2.0.1/
module libevent is pkgconfig("libevent")

in "C header" `{
	#include <sys/stat.h>
	#include <sys/types.h>
	#include <fcntl.h>
	#include <errno.h>
	#include <sys/socket.h>

	#include <event2/listener.h>
	#include <event2/bufferevent.h>
	#include <event2/buffer.h>
`}

in "C" `{
	// Callback forwarded to 'Connection.write_callback'
	static void c_write_cb(struct bufferevent *bev, Connection ctx) {
		Connection_write_callback(ctx);
	}

	// Callback forwarded to 'Connection.read_callback_native'
	static void c_read_cb(struct bufferevent *bev, Connection ctx)
	{
		Connection_read_callback_native(ctx, bev);
	}

	// Callback forwarded to 'Connection.event_callback'
	static void c_event_cb(struct bufferevent *bev, short events, Connection ctx)
	{
		int release = Connection_event_callback(ctx, events);
		if (release) Connection_decr_ref(ctx);
	}

	// Callback forwarded to 'ConnectionFactory.accept_connection'
	static void accept_connection_cb(struct evconnlistener *listener, evutil_socket_t fd,
		struct sockaddr *address, int socklen, ConnectionFactory ctx)
	{
		ConnectionFactory_accept_connection(ctx, listener, fd, address, socklen);
	}
`}

# Structure to hold information and state for a Libevent dispatch loop.
#
# The event_base lies at the center of Libevent; every application will
# have one.  It keeps track of all pending and active events, and
# notifies your application of the active ones.
extern class NativeEventBase `{ struct event_base * `}

	# Create a new event_base to use with the rest of Libevent
	new `{ return event_base_new(); `}

	# Has `self` been correctly initialized?
	fun is_valid: Bool do return not address_is_null

	# Event dispatching loop
	#
	# This loop will run the event base until either there are no more added
	# events, or until something calls `exit_loop`.
	fun dispatch `{ event_base_dispatch(self); `}

	# Exit the event loop
	#
	# TODO support timer
	fun exit_loop `{ event_base_loopexit(self, NULL); `}

	# Destroy this instance
	fun destroy `{ event_base_free(self); `}
end

# Spawned to manage a specific connection
#
# TODO, use polls
class Connection
	super Writer

	# Closing this connection has been requested, but may not yet be `closed`
	var close_requested = false

	# This connection is closed
	var closed = false

	# The native libevent linked to `self`
	var native_buffer_event: NativeBufferEvent

	# Close this connection if possible, otherwise mark it to be closed later
	redef fun close
	do
		if closed then return
		var success = native_buffer_event.destroy
		close_requested = true
		closed = success
	end

	# Callback method on a write event
	fun write_callback
	do
		if close_requested then close
	end

	private fun read_callback_native(bev: NativeBufferEvent)
	do
		var evbuffer = bev.input_buffer
		var len = evbuffer.length
		var buf = new NativeString(len)
		evbuffer.remove(buf, len)
		var str = buf.to_s_with_length(len)
		read_callback str
	end

	# Callback method when data is available to read
	fun read_callback(content: String)
	do
		if close_requested then close
	end

	# Callback method on events: EOF, user-defined timeout and unrecoverable errors
	#
	# Returns `true` if the native handles to `self` can be released.
	fun event_callback(events: Int): Bool
	do
		if events & bev_event_error != 0 or events & bev_event_eof != 0 then
			if events & bev_event_error != 0 then print_error "Error from bufferevent"
			close
			return true
		end

		return false
	end

	# Write a string to the connection
	redef fun write(str)
	do
		if close_requested then return
		native_buffer_event.write(str.to_cstring, str.bytelen)
	end

	redef fun write_byte(byte)
	do
		if close_requested then return
		native_buffer_event.write_byte(byte)
	end

	redef fun write_bytes(bytes)
	do
		if close_requested then return
		native_buffer_event.write(bytes.items, bytes.length)
	end

	# Write a file to the connection
	#
	# If `not path.file_exists`, the method returns.
	fun write_file(path: String)
	do
		if close_requested then return

		var file = new FileReader.open(path)
		if file.last_error != null then
			var error = new IOError("Failed to open file at '{path}'")
			error.cause = file.last_error
			self.last_error = error
			file.close
			return
		end

		var stat = file.file_stat
		if stat == null then
			last_error = new IOError("Failed to stat file at '{path}'")
			file.close
			return
		end

		var err = native_buffer_event.output_buffer.add_file(file.fd, 0, stat.size)
		if err then
			last_error = new IOError("Failed to add file at '{path}'")
			file.close
		end
	end
end

# ---
# Error code for event callbacks

# error encountered while reading
fun bev_event_reading: Int `{ return BEV_EVENT_READING; `}

# error encountered while writing
fun bev_event_writing: Int `{ return BEV_EVENT_WRITING; `}

# eof file reached
fun bev_event_eof: Int `{ return BEV_EVENT_EOF; `}

# unrecoverable error encountered
fun bev_event_error: Int `{ return BEV_EVENT_ERROR; `}

# user-specified timeout reached
fun bev_event_timeout: Int `{ return BEV_EVENT_TIMEOUT; `}

# connect operation finished.
fun bev_event_connected: Int `{ return BEV_EVENT_CONNECTED; `}

# ---
# Options that can be specified when creating a `NativeBufferEvent`

# Close the underlying file descriptor/bufferevent/whatever when this bufferevent is freed.
fun bev_opt_close_on_free: Int `{ return BEV_OPT_CLOSE_ON_FREE; `}

# If threading is enabled, protect the operations on this bufferevent with a lock.
fun bev_opt_threadsafe: Int `{ return BEV_OPT_THREADSAFE; `}

# Run callbacks deferred in the event loop.
fun bev_opt_defer_callbacks: Int `{ return BEV_OPT_DEFER_CALLBACKS; `}

# If set, callbacks are executed without locks being held on the bufferevent.
fun bev_opt_unlock_callbacks: Int `{ return BEV_OPT_UNLOCK_CALLBACKS; `}

# ---
# Options for `NativeBufferEvent::enable`

# Read operation
fun ev_read: Int `{ return EV_READ; `}

# Write operation
fun ev_write: Int `{ return EV_WRITE; `}

# ---

# A buffer event structure, strongly associated to a connection, an input buffer and an output_buffer
extern class NativeBufferEvent `{ struct bufferevent * `}

	# Socket-based `NativeBufferEvent` that reads and writes data onto a network
	new socket(base: NativeEventBase, fd, options: Int) `{
		return bufferevent_socket_new(base, fd, options);
	`}

	# Enable a bufferevent.
	fun enable(operation: Int) `{
		bufferevent_enable(self, operation);
	`}

	# Set callbacks to `read_callback_native`, `write_callback` and `event_callback` of `conn`
	fun setcb(conn: Connection) import Connection.read_callback_native,
	Connection.write_callback, Connection.event_callback, NativeString `{
		Connection_incr_ref(conn);
		bufferevent_setcb(self,
			(bufferevent_data_cb)c_read_cb,
			(bufferevent_data_cb)c_write_cb,
			(bufferevent_event_cb)c_event_cb, conn);
	`}

	# Write `length` bytes of `line`
	fun write(line: NativeString, length: Int): Int `{
		return bufferevent_write(self, line, length);
	`}

	# Write the byte `value`
	fun write_byte(value: Byte): Int `{
		unsigned char byt = (unsigned char)value;
		return bufferevent_write(self, &byt, 1);
	`}

	# Check if we have anything left in our buffers. If so, we set our connection to be closed
	# on a callback. Otherwise we close it and free it right away.
	fun destroy: Bool `{
		struct evbuffer* out = bufferevent_get_output(self);
		struct evbuffer* in = bufferevent_get_input(self);
		if(evbuffer_get_length(in) > 0 || evbuffer_get_length(out) > 0) {
			return 0;
		} else {
			bufferevent_free(self);
			return 1;
		}
	`}

	# The output buffer associated to `self`
	fun output_buffer: OutputNativeEvBuffer `{ return bufferevent_get_output(self); `}

	# The input buffer associated to `self`
	fun input_buffer: InputNativeEvBuffer `{ return bufferevent_get_input(self); `}

	# Read data from this buffer
	fun read_buffer(buf: NativeEvBuffer): Int `{ return bufferevent_read_buffer(self, buf); `}

	# Write data to this buffer
	fun write_buffer(buf: NativeEvBuffer): Int `{ return bufferevent_write_buffer(self, buf); `}
end

# A single buffer
extern class NativeEvBuffer `{ struct evbuffer * `}
	# Length of data in this buffer
	fun length: Int `{ return evbuffer_get_length(self); `}

	# Read data from an evbuffer and drain the bytes read
	fun remove(buffer: NativeString, len: Int) `{
		evbuffer_remove(self, buffer, len);
	`}
end

# An input buffer
extern class InputNativeEvBuffer
	super NativeEvBuffer

	# Empty/clear `length` data from buffer
	fun drain(length: Int) `{ evbuffer_drain(self, length); `}
end

# An output buffer
extern class OutputNativeEvBuffer
	super NativeEvBuffer

	# Add file to buffer
	fun add_file(fd, offset, length: Int): Bool `{
		return evbuffer_add_file(self, fd, offset, length);
	`}
end

# A listener acting on an interface and port, spawns `Connection` on new connections
extern class ConnectionListener `{ struct evconnlistener * `}

	private new bind_to(base: NativeEventBase, address: NativeString, port: Int, factory: ConnectionFactory)
	import ConnectionFactory.accept_connection, error_callback `{

		struct sockaddr_in sin;
		struct evconnlistener *listener;
		ConnectionFactory_incr_ref(factory);

		struct hostent *hostent = gethostbyname(address);

		memset(&sin, 0, sizeof(sin));
		sin.sin_family = hostent->h_addrtype;
		sin.sin_port = htons(port);
		memcpy( &(sin.sin_addr.s_addr), (const void*)hostent->h_addr, hostent->h_length );

		listener = evconnlistener_new_bind(base,
			(evconnlistener_cb)accept_connection_cb, factory,
			LEV_OPT_CLOSE_ON_FREE | LEV_OPT_REUSEABLE, -1,
			(struct sockaddr*)&sin, sizeof(sin));

		if (listener != NULL) {
			evconnlistener_set_error_cb(listener, (evconnlistener_errorcb)ConnectionListener_error_callback);
		}

		return listener;
	`}

	# Get the `NativeEventBase` associated to `self`
	fun base: NativeEventBase `{ return evconnlistener_get_base(self); `}

	# Callback method on listening error
	fun error_callback do
		var cstr = socket_error
		sys.stderr.write "libevent error: '{cstr}'"
	end

	# Error with sockets
	fun socket_error: NativeString `{
		// TODO move to Nit and maybe NativeEventBase
		int err = EVUTIL_SOCKET_ERROR();
		return evutil_socket_error_to_string(err);
	`}
end

# Factory to listen on sockets and create new `Connection`
class ConnectionFactory
	# The `NativeEventBase` for the dispatch loop of this factory
	var event_base: NativeEventBase

	# Accept a connection on `listener`
	#
	# By default, it creates a new NativeBufferEvent and calls `spawn_connection`.
	fun accept_connection(listener: ConnectionListener, fd: Int, address: Pointer, socklen: Int)
	do
		var base = listener.base
		var bev = new NativeBufferEvent.socket(base, fd, bev_opt_close_on_free)
		var conn = spawn_connection(bev)
		bev.enable ev_read|ev_write
		bev.setcb conn
	end

	# Create a new `Connection` object for `buffer_event`
	fun spawn_connection(buffer_event: NativeBufferEvent): Connection
	do
		return new Connection(buffer_event)
	end

	# Listen on `address`:`port` for new connection, which will callback `spawn_connection`
	fun bind_to(address: String, port: Int): nullable ConnectionListener
	do
		var listener = new ConnectionListener.bind_to(event_base, address.to_cstring, port, self)
		if listener.address_is_null then
			sys.stderr.write "libevent warning: Opening {address}:{port} failed\n"
		end
		return listener
	end
end
