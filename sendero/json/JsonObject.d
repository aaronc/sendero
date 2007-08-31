/** 
 * Copyright: Copyright (C) 2007 Aaron Craelius.  All rights reserved.
 * License:   BSD Style
 * Authors:   Aaron Craelius
 */

module sendero.json.JsonObject;

import sendero.json.JsonParser;
import sendero.util.StringCharIterator;

import Float = tango.text.convert.Float;

/**
 * Enumerates the seven acceptable JSON value types.
 */
enum JSONValueType { String, Number, Object, Array, True, False, Null };


/**
 * Represents a JSON value that is one of the seven types specified by the enum
 * JSONValueType.
 */
class JSONValue(Ch = char)
{
	private union Data
	{
		real number;
		Ch[] string;
		JSONValue!(Ch)[] array;
		JSONObject!(Ch) object;
	}
	private Data data_;
	
	private JSONValueType type_ = JSONValueType.Null;
	JSONValueType type() {return type_;}
	
	Ch[] getString()
	{
		return type_ == JSONValueType.String ? data_.string : null;
	}
	
	void opAssign(Ch[] str)
	{
		type_ = JSONValueType.String;
		data_.string = str;
	}
	
	JSONObject!(Ch) getObject()
	{
		return type_ == JSONValueType.Object ? data_.object : null;
	}
	
	void opAssign(JSONObject!(Ch) obj)
	{
		type_ = JSONValueType.Object;
		data_.object = obj;
	}
	
	real getNumber()
	{
		return type_ == JSONValueType.Number ? data_.number : 0;
	}
	
	void opAssign(real num)
	{
		type_ = JSONValueType.Number;
		data_.number = num;
	}
	
	JSONValue!(Ch)[] getArray()
	{
		return type_ == JSONValueType.Array ? data_.array : null;
	}
	
	void opAssign(JSONValue!(Ch)[] arr)
	{
		type_ = JSONValueType.Array;
		data_.array = arr;
	}
}

/**
 * Represents a single member (name-value pair) of a JSONObject.
 */
class JSONMember(Ch = char)
{
	this()
	{
		value = new JSONValue!(Ch);
	}
	Ch[] name;
	JSONValue!(Ch) value;
}

/**
 * Represents a single JSON Object.
 */
class JSONObject(Ch = char)
{
	JSONMember!(Ch)[] members;
	
	/**
	 * Parses the provided text string into a JSON Object.
	 */
	static JSONObject!(Ch) parse(Ch[] text)
	{
		return parse(new StringCharIterator!(Ch)(text));
	}
	
	static private JSONValue!(Ch)[] parseArray(JSONParser!(Ch) p)
	{
		JSONValue!(Ch)[] arr;
		
		while(p.next) {
			if(p.type == JSONTokenType.EndArray)
				return arr;
			
			arr ~= parseValue(p);
		}
	}
	
	static private JSONObject!(Ch) parseObject(JSONParser!(Ch) p)
	{
		auto o = new JSONObject!(Ch);
		while(p.next) {
			if(p.type == JSONTokenType.EndObject)
				return o;
			else if(p.type != JSONTokenType.Name)
				return null;
			
			auto m = new JSONMember!(Ch);
			m.name = p.value;
			
			if(!p.next)
				return null;
			m.value = parseValue(p);
			
			o.members ~= m;
		}
	}
	
	static private JSONValue!(Ch) parseValue(JSONParser!(Ch) p)
	{
		auto v = new JSONValue!(Ch);
		switch(p.type)
		{
		case JSONTokenType.True:
			v.type_ = JSONValueType.True;
			break;
		case JSONTokenType.False:
			v.type_ = JSONValueType.False;
			break;
		case JSONTokenType.Null:
			v.type_ = JSONValueType.Null;
			break;
		case JSONTokenType.String:
			v = p.value;
			break;
		case JSONTokenType.Number:
			auto num = Float.parse(p.value);
			v = num;
			break;
		case JSONTokenType.BeginObject:
			v = parseObject(p);
			break;
		case JSONTokenType.BeginArray:
			v = parseArray(p);
		default:
			return null;
		}
		return v;
	}
	
	/**
	 * Parses the provided ICharIterator into a JSON Object.
	 */
	static JSONObject!(Ch) parse(ICharIterator!(Ch) itr)
	{
		auto p = new JSONParser!(Ch)(itr);		
		if(!p.next) return null;
		if(p.type != JSONTokenType.BeginObject) return null;
		return parseObject(p);
	}
}

unittest
{
	auto obj = JSONObject!(char).parse(TestCase.one);
	assert(obj);
	assert(obj.members[0].name == "glossary");
	assert(obj.members[0].value.type == JSONValueType.Object);
	auto o = obj.members[0].value.getObject;
	assert(o.members[0].name == "title");
	assert(o.members[1].name == "GlossDiv");
	o = o.members[1].value.getObject;
	assert(o.members[0].name == "title");
	assert(o.members[1].name == "GlossList");
}