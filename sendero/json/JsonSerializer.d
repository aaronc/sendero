module sendero.json.JsonSerializer;

import sendero.json.JsonObject;
import sendero.util.Reflection;

import tango.core.Traits;

debug import tango.io.Stdout;

class JSONSerializationVisitor(Ch)
{
	this(FieldInfo[] fields, JSONObject!(Ch) obj, void* ptr)
	{
		this.fields = fields;
		this.obj = obj;
		this.ptr = ptr;
		//debug Stdout(ptr).newline;
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

class JSONSerializer(Ch)
{	
	static bool deserialize(T)(inout T t, JSONObject!(Ch) obj)
	{
		static if(is(T == class) || is(T == struct))
		{
			auto fields = ReflectionOf!(T).fields;
			static if(is(T == class)) {
				t = new T;
				auto v = new JSONSerializationVisitor!(Ch)(fields, obj, cast(void*)t);
			}
			else static if(is(T == struct)) {
				auto v = new JSONSerializationVisitor!(Ch)(fields, obj, &t);
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
	}
}