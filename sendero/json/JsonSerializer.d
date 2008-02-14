/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.json.JsonSerializer;

public import sendero.json.JsonObject;
import sendero.util.Reflection;

import tango.core.Traits;

debug import tango.io.Stdout;

class JSONDeserializationVisitor(Ch)
{
	this(FieldInfo[] fields, JSONObject!(Ch) obj, void* ptr)
	{
		this.fields = fields;
		this.obj = obj;
		this.ptr = ptr;
	}
	FieldInfo[] fields;
	JSONObject!(Ch) obj;
	void* ptr;
	
	void visit(X)(inout X _x, uint index)
	{
		auto v = obj[fields[index].name];
		if(v) {
			auto p = ptr + fields[index].offset;
			JSONSerializer!(Ch).deserialize(*cast(X*)p, v);
		}
	}
}

class JSONSerializationVisitor(Ch)
{
	this(FieldInfo[] fields, JSONObject!(Ch) obj)
	{
		this.fields = fields;
		this.obj = obj;
	}
	FieldInfo[] fields;
	JSONObject!(Ch) obj;
	
	void visit(X)(in X x, uint index)
	{
		auto v = new JSONValue!(Ch);
		JSONSerializer!(Ch).serialize(x, v);
		debug Stdout("visitor.obj.ptr:")(cast(void*)obj).newline;
		obj[fields[index].name] = v;
	}
}

class JSONSerializer(Ch)
{	
	static bool deserialize(T)(inout T t, JSONObject!(Ch) obj)
	{
		static if(is(T == class) || is(T == struct))
		{
			auto fields = ReflectionOf!(T).fields;
			static if(is(T == class)) {
				t = new T;
				auto v = new JSONDeserializationVisitor!(Ch)(fields, obj, cast(void*)t);
			}
			else static if(is(T == struct)) {
				auto v = new JSONDeserializationVisitor!(Ch)(fields, obj, &t);
			}
			ReflectionOf!(T).visitTuple(t, v);
			return true;
		}
		else static assert(false);
	}
	
	static bool deserialize(T)(inout T t, JSONValue!(Ch) val)
	{
		static if(is(T == class) || is(T == struct))
		{
			if(val.type == JSONType.Object) {
				auto obj = val.getObject;
				return deserialize(t, obj);
			}			
			else return false;
		}
		else static if(is(T == Ch[]))
		{
			if(val.type == JSONType.String) {
				t = val.getString;
				return true;
			}			
			else return false;
		}
		else static if(isIntegerType!(T) || isRealType!(T))
		{
			if(val.type == JSONType.Number) {
				t = cast(T)val.getNumber;
				return true;
			}
			else return false;
		}
		else static if(is(T == bool))
		{
			if(val.type == JSONType.Bool) {
				t = val.getBool;
				return true;
			}
			else return false;
		}
		else debug assert(false, "Unsupported JSON serialization type " ~ T.stringof);
	}
	
	static bool serialize(T)(in T t, inout JSONObject!(Ch) obj)
	{
		static if(is(T == class) || is(T == struct))
		{
			debug Stdout("serializeObj.obj.ptr:")(cast(void*)obj).newline;
			
			auto fields = ReflectionOf!(T).fields;
			auto v = new JSONSerializationVisitor!(Ch)(fields, obj);
			ReflectionOf!(T).visitTuple(t, v);
			
			return true;
		}
		else static if(isDynamicArrayType!(T))
		{
			auto val = new JSONValue!(Ch);
			if(!serialize(t, val))
				return false;
			
			static if(T.stringof.length > 2 && T.stringof[$ - 3 .. $] == "[]")
			{
				obj[T.stringof[0 .. $-2] ~ "Array"] = val;
			}
			else
			{
				obj[T.stringof] = val;
			}
			
			return true;
		}
		else static assert(false);
	}
	
	static bool serialize(T)(in T t, inout JSONValue!(Ch) val)
	{
		static if(is(T == class) || is(T == struct))
		{
			auto JSONObject!(Ch) obj = new JSONObject!(Ch);
			if(!serialize(t, obj)) return false;			
			val = obj;
			debug Stdout("obj.len:")(obj.members.length).newline;
			debug Stdout("obj.ptr:")(cast(void*)obj).newline;
			debug Stdout("val.getObject.ptr:")(cast(void*)val.getObject).newline;
			debug Stdout("val.getObject.members.ptr:")(cast(void*)val.getObject.members).newline;
		}
		else static if(is(T == Ch[]))
		{
			val = t;
		}
		else static if(isIntegerType!(T) || isRealType!(T))
		{
			val = t;
		}
		else static if(is(T == bool))
		{
			val = t;
		}
		else static if(isDynamicArrayType!(T))
		{
			uint len = t.length;
			
			JSONValue!(Ch)[] array;
			array.length = len;
			
			for(uint i = 0; i < len; ++i)
			{
				auto v = new JSONValue!(Ch);
				array[i] = v;
				if(!serialize(t[i], v))
					v.setNull;
			}
			
			val = array;
		}
		else debug assert(false, "Unsupported JSON serialization type " ~ T.stringof);
		
		return true;
	}
}

version(Unittest)
{
	struct AStruct
	{
		int x;
		int y;
	}
	
	class A
	{
		char[] name;
		int num;
		double d;
		char[] someData;
		AStruct aStruct;
	}
	
	unittest
	{
		auto a = new A;
		char[] txt = "{\"name\":\"bob\", \"num\":5, \"d\" : 3.167, \"someData\": \"datadatadata\", \"aStruct\" : {\"x\" : 5, \"y\" : 7 }";
		auto json = JSON.parse(txt);
		assert(JSONSerializer!(char).deserialize(a, json));
		assert(a.name == "bob", a.name);
		assert(a.num == 5);
		assert(a.d == 3.167);
		assert(a.someData == "datadatadata");
		assert(a.aStruct.x == 5);
		assert(a.aStruct.y == 7);
		
		auto obj = new JSON;
		assert(JSONSerializer!(char).serialize(a, obj));
		assert(obj !is null);
		/+foreach(key, v; obj)
		{
			Stdout(key)(":")(v.type).newline;
		}+/
		auto aStruct = obj["aStruct"];
		assert(aStruct !is null);
		auto aStrObj = aStruct.getObject;
		Stdout("aStrObj.ptr:")(cast(void*)aStrObj).newline;
		Stdout("aStrObj.members.ptr:")(cast(void*)aStrObj.members).newline;
		assert(aStrObj !is null);
		assert(aStrObj.members !is null);
		Stdout(aStrObj.members.length).newline;
		//auto k0 = aStrObj.members.keys[0];
		//foreach(key; k0_10)
		//Stdout(k0).newline;
		/+foreach(key, v; aStrObj.members)
		{
			//Stdout(key)(":")(v.type).newline;
		}+/
		//Stdout(obj.print);
	}
}