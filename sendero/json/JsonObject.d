/** 
 * Copyright: Copyright (C) 2007 Aaron Craelius.  All rights reserved.
 * License:   BSD Style
 * Authors:   Aaron Craelius
 */

module sendero.json.JsonObject;

import sendero.json.JsonParser;
import sendero.util.StringCharIterator;

import Float = tango.text.convert.Float;

import sendero.util.ArrayWriter;

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
	private union
	{
		real number_;
		Ch[] string_;
		JSONValue!(Ch)[] array_;
		JSONObject!(Ch) object_;
	}
	//private Data data_;
	
	private JSONValueType type_ = JSONValueType.Null;
	JSONValueType type() {return type_;}
	
	Ch[] getString()
	{
		return type_ == JSONValueType.String ? string_ : null;
	}
	
	void opAssign(Ch[] str)
	{
		type_ = JSONValueType.String;
		string_ = str;
	}
	
	JSONObject!(Ch) getObject()
	{
		return type_ == JSONValueType.Object ? object_ : null;
	}
	
	void opAssign(JSONObject!(Ch) obj)
	{
		type_ = JSONValueType.Object;
		object_ = obj;
	}
	
	real getNumber()
	{
		return type_ == JSONValueType.Number ? number_ : 0;
	}
	
	void opAssign(real num)
	{
		type_ = JSONValueType.Number;
		number_ = num;
	}
	
	void opAssign(bool b)
	{
		type_ = b ? JSONValueType.True : JSONValueType.False;		
	}
	
	JSONValue!(Ch)[] getArray()
	{
		return type_ == JSONValueType.Array ? array_ : null;
	}
	
	void opAssign(JSONValue!(Ch)[] arr)
	{
		type_ = JSONValueType.Array;
		array_ = arr;
	}
	
	void setNull()
	{
		type_ = JSONValueType.Null;
	}
}

/**
 * Represents a single JSON Object.
 */
class JSONObject(Ch = char)
{
	JSONValue!(Ch)[Ch[]] members;
	
	JSONValue!(Ch) opIndex(char[] key)
	{
		auto pVal = (key in members);
		if(pVal) return *pVal;
		return null;
	}
	
	void opIndexAssign(JSONValue!(Ch) val, char[] key)
	{
		members[key] = val;
	}
	
	int opApply(int delegate(inout char[] key, inout JSONValue!(Ch) val) dg)
	{
		int res;
		foreach(k, v; members)
		{
			//debug assert(v !is null, key);
			if((res = dg(k, v)) != 0) break;
		}
		return res;
	}
	
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
			
			Ch[] name = p.value;
			
			if(!p.next)
				return null;
			
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
		auto res = new ArrayWriter!(Ch)(100, 100);
		
		void printVal(JSONValue!(Ch) val)
		{
			if(val is null) return;
			
			void printObj(JSONObject!(Ch) obj)
			{
				if(obj is null) return;
				
				bool first = true;
				res ~= "{";
				foreach(k, v; obj.members)
				{
					if(!first) res ~= ",";
					res ~= "\"" ~ k ~ "\":";
					printVal(v);
					first = false;
				}
				res ~= "}";
				
			}
			
			void printArr(JSONValue!(Ch)[] arr)
			{
				
				bool first = true;
				res ~= "[";
				foreach(v; arr)
				{
					if(!first) res ~= ",";
					printVal(v);
					first = false;
				}
				res ~= "]";
			}
			
			Ch[] escapeString(Ch[] str)
			{
				auto res = new ArrayWriter!(Ch);
				foreach(c; str)
				{
					switch(c)
					{
					case '\"': res ~= "\\\""; break;
					case '\\': res ~= "\\\\"; break;
					case '/': res ~= "\\/"; break;
					case '\b': res ~= "\\\b"; break;
					case '\f': res ~= "\\\f"; break;
					case '\n': res ~= "\\\n"; break;
					case '\r': res ~= "\\\r"; break;
					case '\t': res ~= "\\\t"; break;
					default: res ~= c; break;
					}
				}
				return res.get;
			}
			
			with(JSONValueType)
			{
				switch(val.type)
				{
				case String:
					res ~= "\"" ~ escapeString(val.getString) ~ "\"";
					break;
				case Number:
					res ~= Float.toString(val.getNumber);
					break;
				case Object:
					auto obj = val.getObject;
					debug assert(obj !is null);
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
		
		return res.get;
	}
}

alias JSONObject!(char) JSON;

version(Unittest)
{
	
import tango.io.Stdout;
import tango.io.File;
/+import tango.util.time.StopWatch;
	
void benchmark()
{
	void test(char[] filename)
	{
		auto f = new File (filename);
		auto txt = cast(char[]) f.read;
		
		uint n = (100 * 1024 * 1024) / txt.length;
		auto parser = new JSONParser!(char)(txt);
		
		StopWatch watch;
		watch.start;
		for(uint i = 0; i < n; ++i)
		{
			while(parser.next) {}
			parser.reset;
		}
		float t = watch.stop;
		long mb = (txt.length * n) / (1024 * 1024);
		Stdout.formatln("{} {} iterations, {} seconds: {} MB/s", filename, n, t, mb/t);
		
		/*auto p = new JSONParser!(char)(txt);
		while(p.next) {
			Stdout.formatln("{}:{}", p.type, p.value);
		}*/
		
		auto obj = JSON.parse(txt);
		Stdout(obj.print).newline.newline;
	}

	test("test/json/test1.json");
	test("test/json/test2.json");
	test("test/json/test3.json");
}+/

unittest
{
	//benchmark;
	
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
}