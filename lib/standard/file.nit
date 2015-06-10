# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2004-2008 Jean Privat <jean@pryen.org>
# Copyright 2008 Floréal Morandat <morandat@lirmm.fr>
# Copyright 2008 Jean-Sébastien Gélinas <calestar@gmail.com>
#
# This file is free software, which comes along with NIT.  This software is
# distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without  even  the implied warranty of  MERCHANTABILITY or  FITNESS FOR A
# PARTICULAR PURPOSE.  You can modify it is you want,  provided this header
# is kept unaltered, and a notification of the changes is added.
# You  are  allowed  to  redistribute it and sell it, alone or is a part of
# another product.

# File manipulations (create, read, write, etc.)
module file

intrude import stream
intrude import ropes
import string_search
import time
import gc

in "C Header" `{
	#include <dirent.h>
	#include <string.h>
	#include <sys/types.h>
	#include <sys/stat.h>
	#include <unistd.h>
	#include <stdio.h>
	#include <poll.h>
	#include <errno.h>
`}

# `Stream` used to interact with a File or FileDescriptor
abstract class FileStream
	super Stream
	# The path of the file.
	var path: nullable String = null

	# The FILE *.
	private var file: nullable NativeFile = null

	# The status of a file. see POSIX stat(2).
	#
	#     var f = new FileReader.open("/etc/issue")
	#     assert f.file_stat.is_file
	#
	# Return null in case of error
	fun file_stat: nullable FileStat
	do
		var stat = _file.file_stat
		if stat.address_is_null then return null
		return new FileStat(stat)
	end

	# File descriptor of this file
	fun fd: Int do return _file.fileno

	redef fun close
	do
		if _file == null then return
		if _file.address_is_null then
			if last_error != null then return
			last_error = new IOError("Cannot close unopened file")
			return
		end
		var i = _file.io_close
		if i != 0 then
			last_error = new IOError("Close failed due to error {sys.errno.strerror}")
		end
		_file = null
	end

	# Sets the buffering mode for the current FileStream
	#
	# If the buf_size is <= 0, its value will be 512 by default
	#
	# The mode is any of the buffer_mode enumeration in `Sys`:
	#	- buffer_mode_full
	#	- buffer_mode_line
	#	- buffer_mode_none
	fun set_buffering_mode(buf_size, mode: Int) do
		if buf_size <= 0 then buf_size = 512
		if _file.set_buffering_type(buf_size, mode) != 0 then
			last_error = new IOError("Error while changing buffering type for FileStream, returned error {sys.errno.strerror}")
		end
	end
end

# `Stream` that can read from a File
class FileReader
	super FileStream
	super BufferedReader
	super PollableReader
	# Misc

	# Open the same file again.
	# The original path is reused, therefore the reopened file can be a different file.
	#
	#     var f = new FileReader.open("/etc/issue")
	#     var l = f.read_line
	#     f.reopen
	#     assert l == f.read_line
	fun reopen
	do
		if not eof and not _file.address_is_null then close
		last_error = null
		_file = new NativeFile.io_open_read(path.to_cstring)
		if _file.address_is_null then
			last_error = new IOError("Error: Opening file at '{path.as(not null)}' failed with '{sys.errno.strerror}'")
			end_reached = true
			return
		end
		end_reached = false
		buffer_reset
	end

	redef fun close
	do
		super
		buffer_reset
		end_reached = true
	end

	redef fun fill_buffer
	do
		var nb = _file.io_read(_buffer, _buffer_capacity)
		if nb <= 0 then
			end_reached = true
			nb = 0
		end
		_buffer_length = nb
		_buffer_pos = 0
	end

	# End of file?
	redef var end_reached = false

	# Open the file at `path` for reading.
	#
	#     var f = new FileReader.open("/etc/issue")
	#     assert not f.end_reached
	#     f.close
	#
	# In case of error, `last_error` is set
	#
	#     f = new FileReader.open("/fail/does not/exist")
	#     assert f.end_reached
	#     assert f.last_error != null
	init open(path: String)
	do
		self.path = path
		prepare_buffer(10)
		_file = new NativeFile.io_open_read(path.to_cstring)
		if _file.address_is_null then
			last_error = new IOError("Error: Opening file at '{path}' failed with '{sys.errno.strerror}'")
			end_reached = true
		end
	end

	# Creates a new File stream from a file descriptor
	#
	# This is a low-level method.
	init from_fd(fd: Int) do
		self.path = ""
		prepare_buffer(1)
		_file = fd.fd_to_stream(read_only)
		if _file.address_is_null then
			last_error = new IOError("Error: Converting fd {fd} to stream failed with '{sys.errno.strerror}'")
			end_reached = true
		end
	end
end

# `Stream` that can write to a File
class FileWriter
	super FileStream
	super Writer

	redef fun write_bytes(s) do
		if last_error != null then return
		if not _is_writable then
			last_error = new IOError("cannot write to non-writable stream")
			return
		end
		write_native(s.items, s.length)
	end

	redef fun write(s)
	do
		if last_error != null then return
		if not _is_writable then
			last_error = new IOError("cannot write to non-writable stream")
			return
		end
		for i in s.substrings do write_native(i.to_cstring, i.length)
	end

	redef fun write_byte(value)
	do
		if last_error != null then return
		if not _is_writable then
			last_error = new IOError("Cannot write to non-writable stream")
			return
		end
		if _file.address_is_null then
			last_error = new IOError("Writing on a null stream")
			_is_writable = false
			return
		end

		var err = _file.write_byte(value)
		if err != 1 then
			# Big problem
			last_error = new IOError("Problem writing a byte: {err}")
		end
	end

	redef fun close
	do
		super
		_is_writable = false
	end
	redef var is_writable = false

	# Write `len` bytes from `native`.
	private fun write_native(native: NativeString, len: Int)
	do
		if last_error != null then return
		if not _is_writable then
			last_error = new IOError("Cannot write to non-writable stream")
			return
		end
		if _file.address_is_null then
			last_error = new IOError("Writing on a null stream")
			_is_writable = false
			return
		end
		var err = _file.io_write(native, len)
		if err != len then
			# Big problem
			last_error = new IOError("Problem in writing : {err} {len} \n")
		end
	end

	# Open the file at `path` for writing.
	init open(path: String)
	do
		_file = new NativeFile.io_open_write(path.to_cstring)
		self.path = path
		_is_writable = true
		if _file.address_is_null then
			last_error = new IOError("Error: Opening file at '{path}' failed with '{sys.errno.strerror}'")
			is_writable = false
		end
	end

	# Creates a new File stream from a file descriptor
	init from_fd(fd: Int) do
		self.path = ""
		_file = fd.fd_to_stream(wipe_write)
		_is_writable = true
		 if _file.address_is_null then
			 last_error = new IOError("Error: Opening stream from file descriptor {fd} failed with '{sys.errno.strerror}'")
			_is_writable = false
		end
	end
end

redef class Int
	# Creates a file stream from a file descriptor `fd` using the file access `mode`.
	#
	# NOTE: The `mode` specified must be compatible with the one used in the file descriptor.
	private fun fd_to_stream(mode: NativeString): NativeFile is extern "file_int_fdtostream"
end

# Constant for read-only file streams
private fun read_only: NativeString do return once "r".to_cstring

# Constant for write-only file streams
#
# If a stream is opened on a file with this method,
# it will wipe the previous file if any.
# Else, it will create the file.
private fun wipe_write: NativeString do return once "w".to_cstring

###############################################################################

# Standard input stream.
#
# The class of the default value of `sys.stdin`.
class Stdin
	super FileReader

	init do
		_file = new NativeFile.native_stdin
		path = "/dev/stdin"
		prepare_buffer(1)
	end

	redef fun poll_in is extern "file_stdin_poll_in"
end

# Standard output stream.
#
# The class of the default value of `sys.stdout`.
class Stdout
	super FileWriter
	init do
		_file = new NativeFile.native_stdout
		path = "/dev/stdout"
		_is_writable = true
		set_buffering_mode(256, sys.buffer_mode_line)
	end
end

# Standard error stream.
#
# The class of the default value of `sys.stderr`.
class Stderr
	super FileWriter
	init do
		_file = new NativeFile.native_stderr
		path = "/dev/stderr"
		_is_writable = true
	end
end

###############################################################################

redef class Writable
	# Like `write_to` but take care of creating the file
	fun write_to_file(filepath: String)
	do
		var stream = new FileWriter.open(filepath)
		write_to(stream)
		stream.close
	end
end

# Utility class to access file system services
#
# Usually created with `Text::to_path`.
class Path

	private var path: String

	# Path to this file
	redef fun to_s do return path

	# Name of the file name at `to_s`
	#
	# ~~~
	# var path = "/tmp/somefile".to_path
	# assert path.filename == "somefile"
	# ~~~
	var filename: String = path.basename("") is lazy

	# Does the file at `path` exists?
	fun exists: Bool do return stat != null

	# Information on the file at `self` following symbolic links
	#
	# Returns `null` if there is no file at `self`.
	#
	#     assert "/etc/".to_path.stat.is_dir
	#     assert "/etc/issue".to_path.stat.is_file
	#     assert "/fail/does not/exist".to_path.stat == null
	#
	# ~~~
	# var p = "/tmp/".to_path
	# var stat = p.stat
	# if stat != null then # Does `p` exist?
	#     print "It's size is {stat.size}"
	#     if stat.is_dir then print "It's a directory"
	# end
	# ~~~
	fun stat: nullable FileStat
	do
		var stat = path.to_cstring.file_stat
		if stat.address_is_null then return null
		return new FileStat(stat)
	end

	# Information on the file or link at `self`
	#
	# Do not follow symbolic links.
	fun link_stat: nullable FileStat
	do
		var stat = path.to_cstring.file_lstat
		if stat.address_is_null then return null
		return new FileStat(stat)
	end

	# Delete a file from the file system, return `true` on success
	fun delete: Bool do return path.to_cstring.file_delete

	# Copy content of file at `path` to `dest`
	#
	# Require: `exists`
	fun copy(dest: Path)
	do
		var input = open_ro
		var output = dest.open_wo

		while not input.eof do
			var buffer = input.read(1024)
			output.write buffer
		end

		input.close
		output.close
	end

	# Open this file for reading
	#
	# Require: `exists and not link_stat.is_dir`
	fun open_ro: FileReader
	do
		# TODO manage streams error when they are merged
		return new FileReader.open(path)
	end

	# Open this file for writing
	#
	# Require: `not exists or not stat.is_dir`
	fun open_wo: FileWriter
	do
		# TODO manage streams error when they are merged
		return new FileWriter.open(path)
	end

	# Read all the content of the file
	#
	# ~~~
	# var content = "/etc/issue".to_path.read_all
	# print content
	# ~~~
	#
	# See `Reader::read_all` for details.
	fun read_all: String do return read_all_bytes.to_s

	fun read_all_bytes: Bytes
	do
		var s = open_ro
		var res = s.read_all_bytes
		s.close
		return res
	end

	# Read all the lines of the file
	#
	# ~~~
	# var lines = "/etc/passwd".to_path.read_lines
	#
	# print "{lines.length} users"
	#
	# for l in lines do
	#     var fields = l.split(":")
	#     print "name={fields[0]} uid={fields[2]}"
	# end
	# ~~~
	#
	# See `Reader::read_lines` for details.
	fun read_lines: Array[String]
	do
		var s = open_ro
		var res = s.read_lines
		s.close
		return res
	end

	# Return an iterator on each line of the file
	#
	# ~~~
	# for l in "/etc/passwd".to_path.each_line do
	#     var fields = l.split(":")
	#     print "name={fields[0]} uid={fields[2]}"
	# end
	# ~~~
	#
	# Note: the stream is automatically closed at the end of the file (see `LineIterator::close_on_finish`)
	#
	# See `Reader::each_line` for details.
	fun each_line: LineIterator
	do
		var s = open_ro
		var res = s.each_line
		res.close_on_finish = true
		return res
	end


	# Lists the name of the files contained within the directory at `path`
	#
	# Require: `exists and is_dir`
	fun files: Array[Path]
	do
		var files = new Array[Path]
		for filename in path.files do
			files.add new Path(path / filename)
		end
		return files
	end

	# Delete a directory and all of its content, return `true` on success
	#
	# Does not go through symbolic links and may get stuck in a cycle if there
	# is a cycle in the file system.
	fun rmdir: Bool
	do
		var ok = true
		for file in self.files do
			var stat = file.link_stat
			if stat.is_dir then
				ok = file.rmdir and ok
			else
				ok = file.delete and ok
			end
		end

		# Delete the directory itself
		if ok then ok = path.to_cstring.rmdir and ok

		return ok
	end

	redef fun ==(other) do return other isa Path and path.simplify_path == other.path.simplify_path
	redef fun hash do return path.simplify_path.hash
end

# Information on a file
#
# Created by `Path::stat` and `Path::link_stat`.
#
# The information within this class is gathered when the instance is initialized
# it will not be updated if the targeted file is modified.
class FileStat
	super Finalizable

	# TODO private init

	# The low-level status of a file
	#
	# See: POSIX stat(2)
	private var stat: NativeFileStat

	private var finalized = false

	redef fun finalize
	do
		if not finalized then
			stat.free
			finalized = true
		end
	end

	# Returns the last access time in seconds since Epoch
	fun last_access_time: Int
	do
		assert not finalized
		return stat.atime
	end

	# Returns the last access time
	#
	# alias for `last_access_time`
	fun atime: Int do return last_access_time

	# Returns the last modification time in seconds since Epoch
	fun last_modification_time: Int
	do
		assert not finalized
		return stat.mtime
	end

	# Returns the last modification time
	#
	# alias for `last_modification_time`
	fun mtime: Int do return last_modification_time


	# Size of the file at `path`
	fun size: Int
	do
		assert not finalized
		return stat.size
	end

	# Is self a regular file and not a device file, pipe, socket, etc.?
	fun is_file: Bool
	do
		assert not finalized
		return stat.is_reg
	end

	# Alias for `is_file`
	fun is_reg: Bool do return is_file

	# Is this a directory?
	fun is_dir: Bool
	do
		assert not finalized
		return stat.is_dir
	end

	# Is this a symbolic link?
	fun is_link: Bool
	do
		assert not finalized
		return stat.is_lnk
	end

	# FIXME Make the following POSIX only? or implement in some other way on Windows

	# Returns the last status change time in seconds since Epoch
	fun last_status_change_time: Int
	do
		assert not finalized
		return stat.ctime
	end

	# Returns the last status change time
	#
	# alias for `last_status_change_time`
	fun ctime: Int do return last_status_change_time

	# Returns the permission bits of file
	fun mode: Int
	do
		assert not finalized
		return stat.mode
	end

	# Is this a character device?
	fun is_chr: Bool
	do
		assert not finalized
		return stat.is_chr
	end

	# Is this a block device?
	fun is_blk: Bool
	do
		assert not finalized
		return stat.is_blk
	end

	# Is this a FIFO pipe?
	fun is_fifo: Bool
	do
		assert not finalized
		return stat.is_fifo
	end

	# Is this a UNIX socket
	fun is_sock: Bool
	do
		assert not finalized
		return stat.is_sock
	end
end

redef class Text
	# Access file system related services on the path at `self`
	fun to_path: Path do return new Path(to_s)
end

redef class String
	# return true if a file with this names exists
	fun file_exists: Bool do return to_cstring.file_exists

	# The status of a file. see POSIX stat(2).
	fun file_stat: nullable FileStat
	do
		var stat = to_cstring.file_stat
		if stat.address_is_null then return null
		return new FileStat(stat)
	end

	# The status of a file or of a symlink. see POSIX lstat(2).
	fun file_lstat: nullable FileStat
	do
		var stat = to_cstring.file_lstat
		if stat.address_is_null then return null
		return new FileStat(stat)
	end

	# Remove a file, return true if success
	fun file_delete: Bool do return to_cstring.file_delete

	# Copy content of file at `self` to `dest`
	fun file_copy_to(dest: String) do to_path.copy(dest.to_path)

	# Remove the trailing extension `ext`.
	#
	# `ext` usually starts with a dot but could be anything.
	#
	#     assert "file.txt".strip_extension(".txt")  == "file"
	#     assert "file.txt".strip_extension("le.txt")  == "fi"
	#     assert "file.txt".strip_extension("xt")  == "file.t"
	#
	# if `ext` is not present, `self` is returned unmodified.
	#
	#     assert "file.txt".strip_extension(".tar.gz")  == "file.txt"
	fun strip_extension(ext: String): String
	do
		if has_suffix(ext) then
			return substring(0, length - ext.length)
		end
		return self
	end

	# Extract the basename of a path and remove the extension
	#
	#     assert "/path/to/a_file.ext".basename(".ext")         == "a_file"
	#     assert "path/to/a_file.ext".basename(".ext")          == "a_file"
	#     assert "path/to".basename(".ext")                     == "to"
	#     assert "path/to/".basename(".ext")                    == "to"
	#     assert "path".basename("")                        == "path"
	#     assert "/path".basename("")                       == "path"
	#     assert "/".basename("")                           == "/"
	#     assert "".basename("")                            == ""
	fun basename(ext: String): String
	do
		var l = length - 1 # Index of the last char
		while l > 0 and self.chars[l] == '/' do l -= 1 # remove all trailing `/`
		if l == 0 then return "/"
		var pos = chars.last_index_of_from('/', l)
		var n = self
		if pos >= 0 then
			n = substring(pos+1, l-pos)
		end
		return n.strip_extension(ext)
	end

	# Extract the dirname of a path
	#
	#     assert "/path/to/a_file.ext".dirname         == "/path/to"
	#     assert "path/to/a_file.ext".dirname          == "path/to"
	#     assert "path/to".dirname                     == "path"
	#     assert "path/to/".dirname                    == "path"
	#     assert "path".dirname                        == "."
	#     assert "/path".dirname                       == "/"
	#     assert "/".dirname                           == "/"
	#     assert "".dirname                            == "."
	fun dirname: String
	do
		var l = length - 1 # Index of the last char
		while l > 0 and self.chars[l] == '/' do l -= 1 # remove all trailing `/`
		var pos = chars.last_index_of_from('/', l)
		if pos > 0 then
			return substring(0, pos)
		else if pos == 0 then
			return "/"
		else
			return "."
		end
	end

	# Return the canonicalized absolute pathname (see POSIX function `realpath`)
	fun realpath: String do
		var cs = to_cstring.file_realpath
		var res = cs.to_s_with_copy
		# cs.free_malloc # FIXME memory leak
		return res
	end

	# Simplify a file path by remove useless `.`, removing `//`, and resolving `..`
	#
	# * `..` are not resolved if they start the path
	# * starting `.` is simplified unless the path is empty
	# * starting `/` is not removed
	# * trailing `/` is removed
	#
	# Note that the method only work on the string:
	#
	#  * no I/O access is performed
	#  * the validity of the path is not checked
	#
	# ~~~
	# assert "some/./complex/../../path/from/../to/a////file//".simplify_path	     ==  "path/to/a/file"
	# assert "../dir/file".simplify_path       ==  "../dir/file"
	# assert "dir/../../".simplify_path        ==  ".."
	# assert "dir/..".simplify_path            ==  "."
	# assert "//absolute//path/".simplify_path ==  "/absolute/path"
	# assert "//absolute//../".simplify_path   ==  "/"
	# assert "/".simplify_path                 == "/"
	# assert "../".simplify_path               == ".."
	# assert "./".simplify_path                == "."
	# assert "././././././".simplify_path      == "."
	# assert "./../dir".simplify_path		   == "../dir"
	# assert "./dir".simplify_path			   == "dir"
	# ~~~
	fun simplify_path: String
	do
		var a = self.split_with("/")
		var a2 = new Array[String]
		for x in a do
			if x == "." and not a2.is_empty then continue # skip `././`
			if x == "" and not a2.is_empty then continue # skip `//`
			if x == ".." and not a2.is_empty and a2.last != ".." then
				if a2.last == "." then # do not skip `./../`
					a2.pop # reduce `./../` in `../`
				else # reduce `dir/../` in `/`
					a2.pop
					continue
				end
			else if not a2.is_empty and a2.last == "." then
				a2.pop # reduce `./dir` in `dir`
			end
			a2.push(x)
		end
		if a2.is_empty then return "."
		if a2.length == 1 and a2.first == "" then return "/"
		return a2.join("/")
	end

	# Correctly join two path using the directory separator.
	#
	# Using a standard "{self}/{path}" does not work in the following cases:
	#
	# * `self` is empty.
	# * `path` starts with `'/'`.
	#
	# This method ensures that the join is valid.
	#
	#     assert "hello".join_path("world")   == "hello/world"
	#     assert "hel/lo".join_path("wor/ld") == "hel/lo/wor/ld"
	#     assert "".join_path("world")        == "world"
	#     assert "hello".join_path("/world")  == "/world"
	#     assert "hello/".join_path("world")  == "hello/world"
	#     assert "hello/".join_path("/world") == "/world"
	#
	# Note: You may want to use `simplify_path` on the result.
	#
	# Note: This method works only with POSIX paths.
	fun join_path(path: String): String
	do
		if path.is_empty then return self
		if self.is_empty then return path
		if path.chars[0] == '/' then return path
		if self.last == '/' then return "{self}{path}"
		return "{self}/{path}"
	end

	# Convert the path (`self`) to a program name.
	#
	# Ensure the path (`self`) will be treated as-is by POSIX shells when it is
	# used as a program name. In order to do that, prepend `./` if needed.
	#
	#     assert "foo".to_program_name == "./foo"
	#     assert "/foo".to_program_name == "/foo"
	#     assert "".to_program_name == "./" # At least, your shell will detect the error.
	fun to_program_name: String do
		if self.has_prefix("/") then
			return self
		else
			return "./{self}"
		end
	end

	# Alias for `join_path`
	#
	#     assert "hello" / "world"      ==  "hello/world"
	#     assert "hel/lo" / "wor/ld"    ==  "hel/lo/wor/ld"
	#     assert "" / "world"           ==  "world"
	#     assert "/hello" / "/world"    ==  "/world"
	#
	# This operator is quite useful for chaining changes of path.
	# The next one being relative to the previous one.
	#
	#     var a = "foo"
	#     var b = "/bar"
	#     var c = "baz/foobar"
	#     assert a/b/c == "/bar/baz/foobar"
	fun /(path: String): String do return join_path(path)

	# Returns the relative path needed to go from `self` to `dest`.
	#
	#     assert "/foo/bar".relpath("/foo/baz") == "../baz"
	#     assert "/foo/bar".relpath("/baz/bar") == "../../baz/bar"
	#
	# If `self` or `dest` is relative, they are considered relatively to `getcwd`.
	#
	# In some cases, the result is still independent of the current directory:
	#
	#     assert "foo/bar".relpath("..") == "../../.."
	#
	# In other cases, parts of the current directory may be exhibited:
	#
	#     var p = "../foo/bar".relpath("baz")
	#     var c = getcwd.basename("")
	#     assert p == "../../{c}/baz"
	#
	# For path resolution independent of the current directory (eg. for paths in URL),
	# or to use an other starting directory than the current directory,
	# just force absolute paths:
	#
	#     var start = "/a/b/c/d"
	#     var p2 = (start/"../foo/bar").relpath(start/"baz")
	#     assert p2 == "../../d/baz"
	#
	#
	# Neither `self` or `dest` has to be real paths or to exist in directories since
	# the resolution is only done with string manipulations and without any access to
	# the underlying file system.
	#
	# If `self` and `dest` are the same directory, the empty string is returned:
	#
	#     assert "foo".relpath("foo") == ""
	#     assert "foo/../bar".relpath("bar") == ""
	#
	# The empty string and "." designate both the current directory:
	#
	#     assert "".relpath("foo/bar")  == "foo/bar"
	#     assert ".".relpath("foo/bar") == "foo/bar"
	#     assert "foo/bar".relpath("")  == "../.."
	#     assert "/" + "/".relpath(".") == getcwd
	fun relpath(dest: String): String
	do
		var cwd = getcwd
		var from = (cwd/self).simplify_path.split("/")
		if from.last.is_empty then from.pop # case for the root directory
		var to = (cwd/dest).simplify_path.split("/")
		if to.last.is_empty then to.pop # case for the root directory

		# Remove common prefixes
		while not from.is_empty and not to.is_empty and from.first == to.first do
			from.shift
			to.shift
		end

		# Result is going up in `from` with ".." then going down following `to`
		var from_len = from.length
		if from_len == 0 then return to.join("/")
		var up = "../"*(from_len-1) + ".."
		if to.is_empty then return up
		var res = up + "/" + to.join("/")
		return res
	end

	# Create a directory (and all intermediate directories if needed)
	#
	# Return an error object in case of error.
	#
	#    assert "/etc/".mkdir != null
	fun mkdir: nullable Error
	do
		var dirs = self.split_with("/")
		var path = new FlatBuffer
		if dirs.is_empty then return null
		if dirs[0].is_empty then
			# it was a starting /
			path.add('/')
		end
		var error: nullable Error = null
		for d in dirs do
			if d.is_empty then continue
			path.append(d)
			path.add('/')
			var res = path.to_s.to_cstring.file_mkdir
			if not res and error == null then
				error = new IOError("Cannot create directory `{path}`: {sys.errno.strerror}")
			end
		end
		return error
	end

	# Delete a directory and all of its content, return `true` on success
	#
	# Does not go through symbolic links and may get stuck in a cycle if there
	# is a cycle in the filesystem.
	#
	# Return an error object in case of error.
	#
	#    assert "/fail/does not/exist".rmdir != null
	fun rmdir: nullable Error
	do
		var res = to_path.rmdir
		if res then return null
		var error = new IOError("Cannot change remove `{self}`: {sys.errno.strerror}")
		return error
	end

	# Change the current working directory
	#
	#     "/etc".chdir
	#     assert getcwd == "/etc"
	#     "..".chdir
	#     assert getcwd == "/"
	#
	# Return an error object in case of error.
	#
	#     assert "/etc".chdir == null
	#     assert "/fail/does no/exist".chdir != null
	#     assert getcwd == "/etc" # unchanger
	fun chdir: nullable Error
	do
		var res = to_cstring.file_chdir
		if res then return null
		var error = new IOError("Cannot change directory to `{self}`: {sys.errno.strerror}")
		return error
	end

	# Return right-most extension (without the dot)
	#
	# Only the last extension is returned.
	# There is no special case for combined extensions.
	#
	#     assert "file.txt".file_extension      == "txt"
	#     assert "file.tar.gz".file_extension   == "gz"
	#
	# For file without extension, `null` is returned.
	# Hoever, for trailing dot, `""` is returned.
	#
	#     assert "file".file_extension          == null
	#     assert "file.".file_extension         == ""
	#
	# The starting dot of hidden files is never considered.
	#
	#     assert ".file.txt".file_extension     == "txt"
	#     assert ".file".file_extension         == null
	fun file_extension: nullable String
	do
		var last_slash = chars.last_index_of('.')
		if last_slash > 0 then
			return substring( last_slash+1, length )
		else
			return null
		end
	end

	# Returns entries contained within the directory represented by self.
	#
	#     var files = "/etc".files
	#     assert files.has("issue")
	#
	# Returns an empty array in case of error
	#
	#     files = "/etc/issue".files
	#     assert files.is_empty
	#
	# TODO find a better way to handle errors and to give them back to the user.
	fun files: Array[String]
	do
		var res = new Array[String]
		var d = new NativeDir.opendir(to_cstring)
		if d.address_is_null then return res

		loop
			var de = d.readdir
			if de.address_is_null then break
			var name = de.to_s_with_copy
			if name == "." or name == ".." then continue
			res.add name
		end
		d.closedir

		return res
	end
end

redef class NativeString
	private fun file_exists: Bool is extern "string_NativeString_NativeString_file_exists_0"
	private fun file_stat: NativeFileStat is extern "string_NativeString_NativeString_file_stat_0"
	private fun file_lstat: NativeFileStat `{
		struct stat* stat_element;
		int res;
		stat_element = malloc(sizeof(struct stat));
		res = lstat(self, stat_element);
		if (res == -1) return NULL;
		return stat_element;
	`}
	private fun file_mkdir: Bool is extern "string_NativeString_NativeString_file_mkdir_0"
	private fun rmdir: Bool `{ return !rmdir(self); `}
	private fun file_delete: Bool is extern "string_NativeString_NativeString_file_delete_0"
	private fun file_chdir: Bool is extern "string_NativeString_NativeString_file_chdir_0"
	private fun file_realpath: NativeString is extern "file_NativeString_realpath"
end

# This class is system dependent ... must reify the vfs
private extern class NativeFileStat `{ struct stat * `}
	# Returns the permission bits of file
	fun mode: Int is extern "file_FileStat_FileStat_mode_0"
	# Returns the last access time
	fun atime: Int is extern "file_FileStat_FileStat_atime_0"
	# Returns the last status change time
	fun ctime: Int is extern "file_FileStat_FileStat_ctime_0"
	# Returns the last modification time
	fun mtime: Int is extern "file_FileStat_FileStat_mtime_0"
	# Returns the size
	fun size: Int is extern "file_FileStat_FileStat_size_0"

	# Returns true if it is a regular file (not a device file, pipe, sockect, ...)
	fun is_reg: Bool `{ return S_ISREG(self->st_mode); `}
	# Returns true if it is a directory
	fun is_dir: Bool `{ return S_ISDIR(self->st_mode); `}
	# Returns true if it is a character device
	fun is_chr: Bool `{ return S_ISCHR(self->st_mode); `}
	# Returns true if it is a block device
	fun is_blk: Bool `{ return S_ISBLK(self->st_mode); `}
	# Returns true if the type is fifo
	fun is_fifo: Bool `{ return S_ISFIFO(self->st_mode); `}
	# Returns true if the type is a link
	fun is_lnk: Bool `{ return S_ISLNK(self->st_mode); `}
	# Returns true if the type is a socket
	fun is_sock: Bool `{ return S_ISSOCK(self->st_mode); `}
end

# Instance of this class are standard FILE * pointers
private extern class NativeFile `{ FILE* `}
	fun io_read(buf: NativeString, len: Int): Int is extern "file_NativeFile_NativeFile_io_read_2"
	fun io_write(buf: NativeString, len: Int): Int is extern "file_NativeFile_NativeFile_io_write_2"
	fun write_byte(value: Int): Int `{
		unsigned char b = (unsigned char)value;
		return fwrite(&b, 1, 1, self);
	`}
	fun io_close: Int is extern "file_NativeFile_NativeFile_io_close_0"
	fun file_stat: NativeFileStat is extern "file_NativeFile_NativeFile_file_stat_0"
	fun fileno: Int `{ return fileno(self); `}
	# Flushes the buffer, forcing the write operation
	fun flush: Int is extern "fflush"
	# Used to specify how the buffering will be handled for the current stream.
	fun set_buffering_type(buf_length: Int, mode: Int): Int is extern "file_NativeFile_NativeFile_set_buffering_type_0"

	new io_open_read(path: NativeString) is extern "file_NativeFileCapable_NativeFileCapable_io_open_read_1"
	new io_open_write(path: NativeString) is extern "file_NativeFileCapable_NativeFileCapable_io_open_write_1"
	new native_stdin is extern "file_NativeFileCapable_NativeFileCapable_native_stdin_0"
	new native_stdout is extern "file_NativeFileCapable_NativeFileCapable_native_stdout_0"
	new native_stderr is extern "file_NativeFileCapable_NativeFileCapable_native_stderr_0"
end

# Standard `DIR*` pointer
private extern class NativeDir `{ DIR* `}

	# Open a directory
	new opendir(path: NativeString) `{ return opendir(path); `}

	# Close a directory
	fun closedir `{ closedir(self); `}

	# Read the next directory entry
	fun readdir: NativeString `{
		struct dirent *de;
		de = readdir(self);
		if (!de) return NULL;
		return de->d_name;
	`}
end

redef class Sys

	# Standard input
	var stdin: PollableReader = new Stdin is protected writable, lazy

	# Standard output
	var stdout: Writer = new Stdout is protected writable, lazy

	# Standard output for errors
	var stderr: Writer = new Stderr is protected writable, lazy

	# Enumeration for buffer mode full (flushes when buffer is full)
	fun buffer_mode_full: Int is extern "file_Sys_Sys_buffer_mode_full_0"
	# Enumeration for buffer mode line (flushes when a `\n` is encountered)
	fun buffer_mode_line: Int is extern "file_Sys_Sys_buffer_mode_line_0"
	# Enumeration for buffer mode none (flushes ASAP when something is written)
	fun buffer_mode_none: Int is extern "file_Sys_Sys_buffer_mode_none_0"

	# returns first available stream to read or write to
	# return null on interruption (possibly a signal)
	protected fun poll( streams : Sequence[FileStream] ) : nullable FileStream
	do
		var in_fds = new Array[Int]
		var out_fds = new Array[Int]
		var fd_to_stream = new HashMap[Int,FileStream]
		for s in streams do
			var fd = s.fd
			if s isa FileReader then in_fds.add( fd )
			if s isa FileWriter then out_fds.add( fd )

			fd_to_stream[fd] = s
		end

		var polled_fd = intern_poll( in_fds, out_fds )

		if polled_fd == null then
			return null
		else
			return fd_to_stream[polled_fd]
		end
	end

	private fun intern_poll(in_fds: Array[Int], out_fds: Array[Int]) : nullable Int is extern import Array[Int].length, Array[Int].[], Int.as(nullable Int) `{
		int in_len, out_len, total_len;
		struct pollfd *c_fds;
		int i;
		int first_polled_fd = -1;
		int result;

		in_len = Array_of_Int_length( in_fds );
		out_len = Array_of_Int_length( out_fds );
		total_len = in_len + out_len;
		c_fds = malloc( sizeof(struct pollfd) * total_len );

		/* input streams */
		for ( i=0; i<in_len; i ++ ) {
			int fd;
			fd = Array_of_Int__index( in_fds, i );

			c_fds[i].fd = fd;
			c_fds[i].events = POLLIN;
		}

		/* output streams */
		for ( i=0; i<out_len; i ++ ) {
			int fd;
			fd = Array_of_Int__index( out_fds, i );

			c_fds[i].fd = fd;
			c_fds[i].events = POLLOUT;
		}

		/* poll all fds, unlimited timeout */
		result = poll( c_fds, total_len, -1 );

		if ( result > 0 ) {
			/* analyse results */
			for ( i=0; i<total_len; i++ )
				if ( c_fds[i].revents & c_fds[i].events || /* awaited event */
					 c_fds[i].revents & POLLHUP ) /* closed */
				{
					first_polled_fd = c_fds[i].fd;
					break;
				}

			return Int_as_nullable( first_polled_fd );
		}
		else if ( result < 0 )
			fprintf( stderr, "Error in Stream:poll: %s\n", strerror( errno ) );

		return null_Int();
	`}

end

# Print `objects` on the standard output (`stdout`).
fun printn(objects: Object...)
do
	sys.stdout.write(objects.plain_to_s)
end

# Print an `object` on the standard output (`stdout`) and add a newline.
fun print(object: Object)
do
	sys.stdout.write(object.to_s)
	sys.stdout.write("\n")
end

# Print `object` on the error output (`stderr` or a log system)
fun print_error(object: Object)
do
	sys.stderr.write object.to_s
	sys.stderr.write "\n"
end

# Read a character from the standard input (`stdin`).
fun getc: Char
do
	var c = sys.stdin.read_char
	if c == null then return '\1'
	return c
end

# Read a line from the standard input (`stdin`).
fun gets: String
do
	return sys.stdin.read_line
end

# Return the working (current) directory
fun getcwd: String do return file_getcwd.to_s
private fun file_getcwd: NativeString is extern "string_NativeString_NativeString_file_getcwd_0"
