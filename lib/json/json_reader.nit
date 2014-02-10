# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2012-2013 Alexis Laferrière <alexis.laf@xymus.net>
#
# This file is free software, which comes along with NIT.  This software is
# distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without  even  the implied warranty of  MERCHANTABILITY or  FITNESS FOR A 
# PARTICULAR PURPOSE.  You can modify it is you want,  provided this header
# is kept unaltered, and a notification of the changes is added.
# You  are  allowed  to  redistribute it and sell it, alone or is a part of
# another product.

# Deserialisation from the Json format to Nit objects
module json_reader

intrude import jsonable

in "C Header" `{
	#define __STRICT_ANSI__
	#include <json/json.h>
`}

redef class String
	# Deserializes this String and return its value as a Map[String, nullable Jsonable]
	# On error, null is returned.
	fun json_to_object : nullable Map[String, nullable Jsonable] import NativeString.to_s, JsonObject.json_to_map `{
		char *native_recv;
		json_object *jobj;
		nullable_Map_of_String_nullable_Jsonable map;

		native_recv = String_to_cstring( recv );
		jobj = json_tokener_parse( native_recv );
		map = JsonObject_json_to_map( jobj );

		/*json_object_put( jobj );*/
		return map;
	`}
end

redef extern JsonObject
	# Get this json object as a Map
	private fun json_to_map : nullable Map[String, nullable Jsonable] import NativeString.to_s, String.to_cstring, HashMap[String,nullable Jsonable], HashMap[String,nullable Jsonable].[]=, json_cross, HashMap[String, nullable Jsonable].as(nullable Map[String, nullable Jsonable]) `{
		HashMap_of_String_nullable_Jsonable map;
		String nit_key;
		nullable_Jsonable nit_val;
		enum json_type type;

		map = new_HashMap_of_String_nullable_Jsonable();

		{ /* prevents "mixed declaration and code" warning for C90 */
		json_object_object_foreach( recv, key, val ) {
			nit_key = NativeString_to_s( key );

			if ( val == NULL ) type = json_type_null;
			else type = json_object_get_type( val );

			nit_val = JsonObject_json_cross( val, type );

			HashMap_of_String_nullable_Jsonable__index_assign( map, nit_key, nit_val );
		}
		}

		return HashMap_of_String_nullable_Jsonable_as_nullable_Map_of_String_nullable_Jsonable( map );
	`}

	# Get this json object as a Bool
	private fun json_to_bool : Bool `{
		return json_object_get_boolean( recv );
	`}

	# Get this json object as a Float
	private fun json_to_float : Float `{
		return json_object_get_double( recv );
	`}

	# Get this json object as an Int
	private fun json_to_int : Int `{
		return json_object_get_int( recv );
	`}

	# Get this json object as a Sequence
	private fun json_to_sequence : Sequence[nullable Jsonable] import Array[nullable Jsonable], Array[nullable Jsonable].push, json_cross, Array[nullable Jsonable].as(Sequence[nullable Jsonable]) `{
		array_list* jlist;
		json_object* jobj;
		nullable_Jsonable obj;
		Array_of_nullable_Jsonable dest;
		int i;
		int len;
		enum json_type type;

		jlist = json_object_get_array( recv );
		len = json_object_array_length( recv );
		dest = new_Array_of_nullable_Jsonable();
		for ( i = 0; i < len; i ++ ) {
			jobj = json_object_array_get_idx( recv, i );
			if ( jobj == NULL ) type = json_type_null;
			else type = json_object_get_type( jobj );
			obj = JsonObject_json_cross( jobj, type );
			Array_of_nullable_Jsonable_push( dest, obj );
		}

		return Array_of_nullable_Jsonable_as_Sequence_of_nullable_Jsonable( dest );
	`}

	# Get this json object as a String
	private fun json_to_string : String import NativeString.to_s `{
		const char *cstring;
		cstring = json_object_get_string( recv );
		return NativeString_to_s( (char*)cstring );
	`}

	# Intermediate function to convert to gt this Json object as a given type.
	# Imlemented in Nit because Nit should manage all possible typing-related work.
	private fun json_cross( json_type : Int ) : nullable Jsonable
	do
		if json_type == 0 then # null
			return null
		else if json_type == 1 then # Bool
			return json_to_bool
		else if json_type == 2 then # Float
			return json_to_float
		else if json_type == 3 then # Int
			return json_to_int
		else if json_type == 4 then # Map
			return json_to_map
		else if json_type == 5 then # Sequence
			return json_to_sequence
		else if json_type == 6 then # String
			return json_to_string
		else
			print "WARNING: Unrecongnized json object type id: {json_type}"
			return null
		end
	end
end
