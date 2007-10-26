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
alias JSONValueType JSONType;


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
 * Represents a single JSON Object.
 */
class JSONObject(Ch = char)
{
	//JSONMember!(Ch)[] members;
	JSONValue!(Ch)[Ch[]] members;
	
	/**
	 * Parses the provided text string into a JSON Object.
	 */
	static JSONObject!(Ch) parse(Ch[] text)
	{
		scope itr = new StringCharIterator!(Ch)(text);
		return parse(itr);
	}
	
	static private JSONValue!(Ch)[] parseArray(JSONParser!(Ch) p)
	{
		JSONValue!(Ch)[] arr;
		
		while(p.next) {
			if(p.type == JSONTokenType.EndArray)
				return arr;
			
			arr ~= parseValue(p);
		}
		return arr;
	}
	
	static private JSONObject!(Ch) parseObject(JSONParser!(Ch) p)
	{
		auto o = new JSONObject!(Ch);
		while(p.next) {
			if(p.type == JSONTokenType.EndObject)
				return o;
			else if(p.type != JSONTokenType.Name)
				return null;
			
//			auto m = new JSONMember!(Ch);
			//m.name = p.value;
			Ch[] name = p.value;
			
			if(!p.next)
				return null;
			//m.value = parseValue(p);
			o.members[name] = parseValue(p);
		}
		return o;
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
		case JSONTokenType.BeginObject:
			v = parseObject(p);
			break;
		case JSONTokenType.BeginArray:
			v = parseArray(p);
			break;
		case JSONTokenType.String:
			v = p.value;
			break;
		case JSONTokenType.Number:
			auto num = Float.parse(p.value);
			v = num;
			break;
		default:
			v.type_ = JSONValueType.Null;
			break;
		}
		return v;
	}
	
	/**
	 * Parses the provided ICharIterator into a JSON Object.
	 */
	static JSONObject!(Ch) parse(ICharIterator!(Ch) itr)
	{
		scope p = new JSONParser!(Ch)(itr);		
		if(!p.next) return null;
		if(p.type != JSONTokenType.BeginObject) return null;
		return parseObject(p);
	}
	
	Ch[] print()
	{
		Ch[] res;
		
		Ch[] tab;
		
		void printVal(JSONValue!(Ch) val)
		{
			void printObj(JSONObject!(Ch) obj)
			{
				bool first = true;
				res ~= tab ~ "\n{\n";
				//tab ~= " ";
				foreach(k, v; obj.members)
				{
					if(!first) res ~= ",\n";
					res ~= tab ~ "\"" ~ k ~ "\":";
					printVal(v);
					first = false;
				}
				//tab = tab[0 .. $-1];
				res ~= tab ~ "\n}\n";
				
			}
			
			void printArr(JSONValue!(Ch)[] arr)
			{
				
				bool first = true;
				res ~= tab ~ "\n[\n";
				//tab ~= " ";
				foreach(v; arr)
				{
					if(!first) res ~= ",\n";
					res ~= tab;
					printVal(v);
					first = false;
				}
				//tab = tab[0 .. $-1];
				res ~= tab ~ "\n]\n";
			}
			
			with(JSONValueType)
			{
				switch(val.type)
				{
				case String:
					res ~= "\"" ~ val.getString ~ "\"";
					break;
				case Number:
					res ~= Float.toUtf8(val.getNumber);
					break;
				case Object:
					printObj(val.getObject);
					break;
				case Array:
					printArr(val.getArray);
					break;
				case True:
					res ~= "true";
					break;
				case False:
					res ~= "false";
					break;
				case Null:
				default:
					res ~= "null";
					break;
				}
			}
		}
		
		auto val = new JSONValue!(Ch);
		val = this;
		printVal(val);
		
		return res;
	}
}

alias JSONObject!(char) JSON;

unittest
{
	auto obj = JSONObject!(char).parse(TestCase.one);
	assert(obj);
	//assert(obj.members[0].name == "glossary");
	//assert(obj.members[0].value.type == JSONValueType.Object);
	assert("glossary" in obj.members);
	assert(obj.members["glossary"].type == JSONValueType.Object);
	auto o = obj.members["glossary"].getObject;
	//assert(o.members[0].name == "title");
	//assert(o.members[1].name == "GlossDiv");
	assert("title" in o.members);
	assert("GlossDiv" in o.members);
	o = o.members["GlossDiv"].getObject;
	//assert(o.members[0].name == "title");
	//assert(o.members[1].name == "GlossList");
	
	assert("title" in o.members);
	assert("GlossList" in o.members);
}