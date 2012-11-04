# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2008 Floréal Morandat <morandat@lirmm.fr>
# Copyright 2008 Jean Privat <jean@pryen.org>
#
# This file is free software, which comes along with NIT.  This software is
# distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without  even  the implied warranty of  MERCHANTABILITY or  FITNESS FOR A 
# PARTICULAR PURPOSE.  You can modify it is you want,  provided this header
# is kept unaltered, and a notification of the changes is added.
# You  are  allowed  to  redistribute it and sell it, alone or is a part of
# another product.

# Management of options on the command line
module opts

# Super class of all option's class
abstract class Option
	# Names for the option (including long and short ones)
	readable var _names: Array[String]

	# Type of the value of the option
	type VALUE: nullable Object

	# Human readable description of the option
	readable var _helptext: String 

	# Gathering errors during parsing
	readable var _errors: Array[String]

	# Is this option mandatory?
	readable writable var _mandatory: Bool 

	# Has this option been read?
	readable var _read:Bool

	# Current value of this option
	writable var _value: nullable VALUE

	# Current value of this option
	fun value: VALUE do return _value.as(VALUE)

	# Default value of this option
	readable writable var _default_value: nullable VALUE

	# Create a new option
	init init_opt(help: String, default: nullable VALUE, names: nullable Array[String])
	do
		if names == null then
			_names = new Array[String]
		else
			_names = names.to_a
		end
		_helptext = help
		_mandatory = false
		_read = false
		_default_value = default
		_value = default 
		_errors = new Array[String]
	end

	# Add new aliases for this option
	fun add_aliases(names: String...) do _names.add_all(names)
	
	# An help text for this option with default settings
	redef fun to_s do return pretty(2)
	
	# A pretty print for this help
	fun pretty(off: Int): String
	do
		var text = new Buffer.from("  ")
		text.append(_names.join(", "))
		text.append("  ")
		var rest = off - text.length
		if rest > 0 then text.append(" " * rest)
		text.append(helptext)
		#text.append(pretty_default)
		return text.to_s
	end

	fun pretty_default: String
	do
		var dv = default_value
		if dv != null then return " ({dv})"
		return ""
	end

	# Consume parameters for this option
	protected fun read_param(it: Iterator[String])
	do
		_read = true
	end
end

class OptionText
	super Option
	init(text: String) do init_opt(text, null, null)

	redef fun pretty(off) do return to_s

	redef fun to_s do return helptext
end

class OptionBool
	super Option
	redef type VALUE: Bool

	init(help: String, names: String...) do init_opt(help, false, names)

	redef fun read_param(it)
	do
		super
		value = true
	end
end

class OptionCount
	super Option
	redef type VALUE: Int

	init(help: String, names: String...) do init_opt(help, 0, names)

	redef fun read_param(it)
	do
		super
		value += 1
	end
end

# Option with one parameter (mandatory by default)
abstract class OptionParameter
	super Option
	protected fun convert(str: String): VALUE is abstract

	# Is the parameter mandatory?
	readable writable var _parameter_mandatory: Bool

	redef fun read_param(it)
	do
		super
		if it.is_ok and it.item.first != '-' then
			value = convert(it.item)
			it.next
		else
			if _parameter_mandatory then
				_errors.add("Parameter expected for option {names.first}.")
			end
		end
	end

	init init_opt(h, d, n)
	do
		super
		_parameter_mandatory = true
	end
end

class OptionString
	super OptionParameter
	redef type VALUE: nullable String

	init(help: String, names: String...) do init_opt(help, null, names)

	redef fun convert(str) do return str
end

class OptionEnum
	super OptionParameter
	redef type VALUE: Int
	var _values: Array[String]

	init(values: Array[String], help: String, default: Int, names: String...)
	do
		assert values.length > 0
		_values = values.to_a
		init_opt("{help} <{values.join(", ")}>", default, names)
	end

	redef fun convert(str)
	do
		var id = _values.index_of(str)
		if id == -1 then
			var e = "Unrecognized value for option {_names.join(", ")}.\n"
			e += "Expected values are: {_values.join(", ")}."
			_errors.add(e)
		end
		return id
	end

	fun value_name: String = _values[value]

	redef fun pretty_default
	do
		if default_value != null then
			return " ({_values[default_value.as(not null)]})"
		else
			return ""
		end
	end	
end

class OptionInt
	super OptionParameter
	redef type VALUE: Int

	init(help: String, default: Int, names: String...) do init_opt(help, default, names)
	
	redef fun convert(str) do return str.to_i
end

class OptionArray
	super OptionParameter
	redef type VALUE: Array[String]

	init(help: String, names: String...)
	do
		_values = new Array[String]
		init_opt(help, _values, names)
	end

	var _values: Array[String]	
	redef fun convert(str)
	do
		_values.add(str)
		return _values
	end
end

class OptionContext
	readable var _options: Array[Option] 
	readable var _rest: Array[String] 
	readable var _errors: Array[String]

	var _optmap: Map[String, Option]
	
	fun usage
	do
		var lmax = 1
		for i in _options do
			var l = 3
			for n in i.names do
				l += n.length + 2
			end
			if lmax < l then lmax = l
		end
		
		for i in _options do
			print(i.pretty(lmax))
		end
	end

	# Parse ans assign options everywhere is the argument list
	fun parse(argv: Collection[String])
	do
		var it = argv.iterator
		parse_intern(it)
	end

	protected fun parse_intern(it: Iterator[String])
	do
		var parseargs = true
		build
		var rest = _rest

		while parseargs and it.is_ok do
			var str = it.item
			if str == "--" then
				it.next
				rest.add_all(it.to_a)
				parseargs = false
			else
				# We're looking for packed short options
				if str.last_index_of('-') == 0 and str.length > 2 then
					var next_called = false
					for i in [1..str.length] do
						var short_opt = "-" + str[i].to_s
						if _optmap.has_key(short_opt) then
							var option = _optmap[short_opt]
							if option isa OptionParameter then
								it.next
								next_called = true
							end
							option.read_param(it)
						end
					end
					if not next_called then it.next
				else
					if _optmap.has_key(str) then
						var opt = _optmap[str]
						it.next
						opt.read_param(it)
					else
						rest.add(it.item)
						it.next
					end
				end
			end
		end

		for opt in _options do
			if opt.mandatory and not opt.read then
				_errors.add("Mandatory option {opt.names.join(", ")} not found.")
			end
		end
	end

	fun add_option(opts: Option...)
	do
		for opt in opts do
			_options.add(opt)
		end
	end

	init
	do
		_options = new Array[Option]
		_optmap = new HashMap[String, Option]
		_rest = new Array[String]
		_errors = new Array[String]
	end

	private fun build
	do
		for o in _options do
			for n in o.names do
				_optmap[n] = o
			end
		end
	end

	fun get_errors: Array[String]
	do
		var errors: Array[String] = new Array[String]

		errors.add_all(_errors)

		for o in _options do
			for e in o.errors do
				errors.add(e)
			end
		end

		return errors
	end
end
