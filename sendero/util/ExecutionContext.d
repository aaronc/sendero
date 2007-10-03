module sendero.util.ExecutionContext;

import sendero.util.Reflection;

public import tango.core.Type;
public import tango.util.time.Date;
public import tango.util.time.DateTime;
import tango.core.Traits;
import tango.core.Variant;
import tango.text.Util;

import mango.icu.ULocale;
import mango.icu.UTimeZone;

enum VarT : ubyte {  Bool, Byte, Short, Int, Long, UByte, UShort, UInt, ULong, Float, Double, String, DateTime, Date, Time, ClassStruct, Array, Null };

interface IClassStructBinding
{
	VariableBinding getVar(char[] var);
	void setPtr(void* ptr);
}

interface IArrayVariableBinding
{
	VarT type();
	void set(void* ptr);
	int opApply (int delegate (inout VariableBinding val) dg);
	VariableBinding opIndex(size_t i);
	size_t length();
}

class ArrayVariableBinding(T) : IArrayVariableBinding
{
	static this()
	{
		type_ = getVarT!(typeof(T.init[0]))();
	}
	
	this()
	{
		
	}
	
	this(T t)
	{
		this.t = t;
	}
	
	static const VarT type_;
	
	
	VarT type() {return type_;}
	T t;
	
	void set(void* ptr)
	{
		auto pt = cast(T*)ptr;
		t = *pt;
	}
	
	int opApply (int delegate (inout VariableBinding val) dg)
    {
	    int res;
	
	    foreach(x; t)
	    {
	        VariableBinding var;
	        var.type = type_;
	        static if(is(typeof(T.init[0]) == class))
	        	var.clsBinding = new ClassStructBinding!(typeof(T.init[0]))(x);
	        else       	
	        	var.data = x;
	        if ((res = dg(var)) != 0)
	            break;
	    }
	
		return res;
    }
	
	VariableBinding opIndex(size_t i)
	{
		if(i > t.length) return VariableBinding();
		VariableBinding var;
        var.type = type_;
        var.data = t[i];
		return var;
	}
	size_t length() { return t.length;}
}

struct VarInfo
{
	VarT type;
	union
	{
		IClassStructBinding clsBinding;
		IArrayVariableBinding arrayBinding;
	}
	size_t offset;
}

VarT getVarT(X)()
{
	static if(is(X == bool)) {
		return VarT.Bool;
	}
	else static if(is(X == ubyte)) {
		return VarT.UByte;
	}
	else static if(is(X == byte)) {
		return VarT.Byte;
	}
	else static if(is(X == ushort)) {
		return VarT.UShort;
	}
	else static if(is(X == short)) {
		return VarT.Short;
	}
	else static if(is(X == uint)) {
		return VarT.UInt;
	}
	else static if(is(X == int)) {
		return VarT.Int;
	}
	else static if(is(X == ulong)) {
		return VarT.ULong;
	}
	else static if(is(X == long)) {
		return VarT.Long;
	}
	else static if(is(X == float)) {
		return VarT.Float;
	}
	else static if(is(X == double)) {
		return VarT.Double;
	}
	else static if(is(X:char[])) {
		return VarT.String;
	}
	else static if(isDynamicArrayType!(X)) {
		return VarT.Array;
	}
	else static if(is(T == DateTime))
	{
		return VarT.DateTime;
	}
	else static if(is(T == Date))
	{
		return VarT.Date;
	}
	else static if(is(T == Time))
	{
		return VarT.Time;
	}
	else static if(is(X == class))
	{
		return VarT.ClassStruct;
	}
	else return VarT.Null;
}

class VarBindingVisitor
{
	VarInfo[uint] bindings;
	
	void visit(T)(T x, uint index)
	{
		VarInfo info;
		info.type = getVarT!(T);
		if(info.type == VarT.Null) return;
		static if(is(T == class)) {
			info.clsBinding = new ClassStructBinding!(T);
		}
		else static if(isDynamicArrayType!(T) && !is(T == char[])) {
			var.arrayBinding = new ArrayVariableBinding!(T);
		}
		bindings[index] = info;
	}
}


class ClassStructBinding(T) : IClassStructBinding
{
	static void init()
	{
		auto v = new VarBindingVisitor;
		auto t = new T;
		ReflectionOf!(T).visitTuple(t, v);
		auto fields = ReflectionOf!(T).fields;
		foreach(f; fields)
		{
			auto pInfo = (f.ordinal in v.bindings);
			if(pInfo) {
				(*pInfo).offset = f.offset;
				bindInfo[f.name] = *pInfo;
			}			
		}
		initialized = true;
	}
	
	private static bool initialized; 
	private static VarInfo[char[]] bindInfo;
	
	private T t;
	this(T t)
	{
		this.t = t;
	}
	
	void setPtr(void* ptr)
	{
		t = cast(T)ptr;
	}
	
	VariableBinding getVar(char[] varName)
	{
		if(!initialized) init;
		
		if(!t) return VariableBinding();
		
		auto pInfo = (varName in bindInfo);
		if(pInfo) {
			void* ptr = cast(void*)t + (*pInfo).offset;
			VariableBinding var;
			switch((*pInfo).type)
			{
			case(VarT.Bool):
				var.data = *cast(bool*)ptr;
				break;
			case(VarT.Byte):
				var.data = *cast(byte*)ptr;
				break;
			case(VarT.Short):
				var.data = *cast(short*)ptr;
				break;
			case(VarT.Int):
				var.data = *cast(int*)ptr;
				break;
			case(VarT.Long):
				var.data = *cast(long*)ptr;
				break;
			case(VarT.UByte):
				var.data = *cast(ubyte*)ptr;
				break;
			case(VarT.UShort):
				var.data = *cast(ushort*)ptr;
				break;
			case(VarT.UInt):
				var.data = *cast(uint*)ptr;
				break;
			case(VarT.ULong):
				var.data = *cast(ulong*)ptr;
				break;
			case(VarT.Float):
				var.data = *cast(float*)ptr;
				break;
			case(VarT.Double):
				var.data = *cast(double*)ptr;
				break;
			case(VarT.String):
				char[] x = *cast(char[]*)ptr;
				var.data = x;
				break;
			case(VarT.DateTime):
				var.data = *cast(DateTime*)ptr;
				break;
			case(VarT.Date):
				var.data = *cast(Date*)ptr;
				break;
			case(VarT.Time):
				var.data = *cast(Time*)ptr;
				break;
			case(VarT.ClassStruct):
				var.clsBinding = (*pInfo).clsBinding;
				var.clsBinding.setPtr(*cast(void**)ptr);
				break;
			case(VarT.Array):
				var.arrayBinding = (*pInfo).arrayBinding;
				var.arrayBinding.set(ptr);
			break;
			default:
				return VariableBinding();
			}
			var.type = (*pInfo).type;
			return var;
		}
		return VariableBinding();
	}
}



struct VariableBinding
{
	VarT type = VarT.Null;
	union
	{
		IArrayVariableBinding arrayBinding;
		Variant data;
		IClassStructBinding clsBinding;
	}
}

interface IFunctionBinding
{
	VariableBinding exec(VariableBinding[] params);
}

struct VarPath
{
	static VarPath opCall(char[] varPath)
	{
		VarPath v;
		uint i = 0;
		while(i < varPath.length) {
			uint j = locate(varPath, '.', i);
			/*if(j == varPath.length) {
				v.path ~= varPath[i .. $];
				return v;
			}
			else v.path ~= varPath[i .. j]*/
			v.path ~= varPath[i .. j];
			i = j + 1;
		}
		return v;
	}
	
	char[] opIndex(size_t i)
	{
		return path[i];
	}
	
	size_t length() {return path.length;}
	
	char[][] path;
}

class ExecutionContext
{
	VariableBinding[char[]] vars;
	IFunctionBinding[char[]] fns;
	ULocale locale;
	UTimeZone timezone;
	
	this()
	{
		locale = ULocale.US;
	}
	
	void addVar(T)(char[] name, T t)
	{
		static if(is(T == VariableBinding)) {
			vars[name] = t;
			return;
		}
		
		VariableBinding var;
		var.type = getVarT!(T);
		if(var.type == VarT.Null) {
			assert(false, "Unsupported variable type " ~ T.stringof);
		}
		static if(is(T == class)) {
			var.clsBinding = new ClassStructBinding!(T)(t);
		}
		else static if(isDynamicArrayType!(T) && !is(T == char[])) {
			var.arrayBinding = new ArrayVariableBinding!(T)(t);
		}
		else {
			var.data = t;
		}
		vars[name] = var;
	}
	
	void addVarAsRoot(T)(T t)
	{
		auto clsBinding = new ClassStructBinding!(T)(t);
		foreach(name, i; clsBinding.VarInfo)
		{
			auto v = clsBinding.getVar(name);
			if(v.type != VarT.Null) {
				vars[name] = v;
			}
		}
	}
	
	VariableBinding getVar(char[] var)
	{
		auto pVar = (var in vars);
		if(!pVar) return VariableBinding();
		return *pVar;
	}
	
	VariableBinding getVar(VarPath varPath)
	{
		if(!varPath.path.length) return VariableBinding();
		
		
		auto pVar = (varPath.path[0] in vars);
		if(!pVar) return VariableBinding();
		VariableBinding var = *pVar;
		
		uint n = 1;
		while(varPath.path.length > n) {
			if(var.type != VarT.ClassStruct) return VariableBinding();
			var = var.clsBinding.getVar(varPath.path[n]);
			++n;
		}
		return var;
	}
	
	void removeVar(char[] name)
	{
		auto v = (name in vars);
		if(v) vars.remove(name);
	}
}

unittest
{
	auto ctxt = new ExecutionContext;
	
	char[][] items;
	items ~= "hello";
	items ~= "world";
	ctxt.addVar("items", items);
	
	auto v = ctxt.getVar("items");
	
	assert(v.arrayBinding.length == 2);
	assert(v.arrayBinding[0].data.get!(char[]) == "hello");
	assert(v.arrayBinding[1].data.get!(char[]) == "world");
	
	char[][] res;
	foreach(x; v.arrayBinding)
	{
		res ~= x.data.get!(char[]);
	}
	assert(res[0] == "hello");
	assert(res[1] == "world");
}