# This file is part of NIT ( http://www.nitlanguage.org ).
#
# This file is free software, which comes along with NIT.  This software is
# distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without  even  the implied warranty of  MERCHANTABILITY or  FITNESS FOR A
# PARTICULAR PURPOSE.  You can modify it is you want,  provided this header
# is kept unaltered, and a notification of the changes is added.
# You  are  allowed  to  redistribute it and sell it, alone or is a part of
# another product.

# Easy XML DOM parser
module dom

import parser

redef class XMLEntity

	# The `XMLTag` children with the `tag_name`
	#
	# ~~~
	# var code = """
	# <?xml version="1.0" encoding="us-ascii"?>
	# <animal>
	#     <cat/>
	#     <tiger>This is a white tiger!</tiger>
	#     <cat/>
	# </animal>"""
	#
	# var xml = code.to_xml
	# assert xml["animal"].length == 1
	# assert xml["animal"].first["cat"].length == 2
	# ~~~
	fun [](tag_name: String): Array[XMLEntity]
	do
		var res = new Array[XMLEntity]
		for child in children do
			if child isa XMLTag and child.tag_name == tag_name then
				res.add child
			end
		end
		return res
	end
end

redef class XMLStartTag

	# Content of this XML tag held within a `PCDATA` or `CDATA`
	#
	# ~~~
	# var code = """
	# <?xml version="1.0" encoding="us-ascii"?>
	# <animal>
	#     <cat/>
	#     <tiger>This is a white tiger!</tiger>
	#     <cat/>
	# </animal>"""
	#
	# var xml = code.to_xml
	# assert xml["animal"].first["tiger"].first.as(XMLStartTag).data == "This is a white tiger!"
	# ~~~
	fun data: String
	do
		for child in children do
			if child isa PCDATA then return child.content
			if child isa CDATA then return child.content
		end
		abort
	end
end
