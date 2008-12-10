module sendero.vm.Bind;

import sendero_base.Core;
import sendero_base.Set;

import sendero.util.Reflection;

import tango.core.Traits;

import tango.time.Time;
import tango.time.Clock;

void bind(T)(ref Var var, T val)
{
	static if( is( typeof( set!(T) ) ) )
		set(var, val);
	else static if(is(T == DateTime))
	{
		var.type = VarT.Time;
		var.time_ = Clock.fromDate(val);
	}
	else static if(isDynamicArrayType!(T)) {
		var.type = VarT.Array;
		var.array_ = new ArrayVar!(T)(val);
	}
	else static if(isAssocArrayType!(T)) {
		var.type = VarT.Object;
		var.obj_ = new AssocArrayVar!(T)(val);
	}
	else static if(is(T == class))
	{
		var.type = VarT.Object;
		var.obj_ = new ClassBinding!(T)(val);
	}
	else static if(is(typeof(*val) == struct))
	{
		var.type = VarT.Object;
		var.obj_ = new ClassBinding!(T, true)(val);
	}
	else static assert(false, "Unable to bind variable of type " ~ T.stringof);
}


interface IDynArrayBinding
{
	IArray createInstance(void* ptr);
}

class ArrayVar(T) : IArray, IDynArrayBinding
{
	package this() { }
	package this(void* ptr)
	{
		auto pt = cast(T*)ptr;
		t = *pt;
	}
	this(T t) { this.t = t;}	
	private T t;
	
	IArray createInstance(void* ptr)
	{
		return new ArrayVar!(T)(ptr);
	}
	
	int opApply (int delegate (inout Var val) dg)
    {
	    int res;
	
	    foreach(x; t)
	    {
	        Var var;
	        bind(var, x);
	        if ((res = dg(var)) != 0)
	            break;
	    }
	
		return res;
    }
	
	Var opIndex(size_t i)
	{
		if(i > t.length) return Var();
		Var var;
		static if(is(T == struct))
			bind(var, cast(T*)&t[i]);
		else
			bind(var, t[i]);
		return var;
	}
	
	size_t length() { return t.length;}
	
	void opCatAssign(Var v) { }
}

interface IClassBinding
{
	IObject createInstance(void* ptr);
}

class AssocArrayVar(T) : IObject, IClassBinding
{
	static this()
	{
		static assert(is(typeof(T.init.keys[0]) == char[]));
	}
	
	private this(void* ptr)
	{
		auto pt = cast(T*)ptr;
		t = *pt;
	}
	
	this(T t) { this.t = t;}	
	private T t;
	
	IObject createInstance(void* ptr)
	{
		return new AssocArrayVar!(T)(ptr);
	}
	
	int opApply (int delegate (inout char[] key, inout Var val) dg)
    {
	    int res;
	
	    foreach(k, v; t)
	    {
	        Var var;
	        bind(var, v);
	        if ((res = dg(k, var)) != 0)
	            break;
	    }
	
		return res;
    }
	
	Var opIndex(char[] key)
	{
		auto pVal = (key in t);
		if(!pVal) return Var();
		Var var;
		bind(var, *pVal);
		return var;
	}
	
	size_t length() { return t.length;}
	
	void opIndexAssign(inout Var, char[] key)
	{
		debug assert(false);
	}
}

interface IVarFilter
{
	Var filter(Var v);
}

struct VarInfo
{
	ClassVarT type;
	union
	{
		IClassBinding clsBinding;
		IDynArrayBinding arrayBinding;
	}
	size_t offset;
	IVarFilter filter;
}

ClassVarT getClassVarT(X)()
{
	static if(is(X == bool)) {
		return ClassVarT.Bool;
	}
	else static if(is(X == ubyte)) {
		return ClassVarT.UByte;
	}
	else static if(is(X == byte)) {
		return ClassVarT.Byte;
	}
	else static if(is(X == ushort)) {
		return ClassVarT.UShort;
	}
	else static if(is(X == short)) {
		return ClassVarT.Short;
	}
	else static if(is(X == uint)) {
		return ClassVarT.UInt;
	}
	else static if(is(X == int)) {
		return ClassVarT.Int;
	}
	else static if(is(X == ulong)) {
		return ClassVarT.ULong;
	}
	else static if(is(X == long)) {
		return ClassVarT.Long;
	}
	else static if(is(X == float)) {
		return ClassVarT.Float;
	}
	else static if(is(X == double)) {
		return ClassVarT.Double;
	}
	else static if(is(X:char[])) {
		return ClassVarT.String;
	}
	else static if(isDynamicArrayType!(X)) {
		return ClassVarT.Array;
	}
	else static if(isAssocArrayType!(X)) {
		return ClassVarT.AssocArray;
	}
	else static if(is(X == DateTime))
	{
		return ClassVarT.DateTime;
	}
	else static if(is(X == Time))
	{
		return ClassVarT.Time;
	}
	/+else static if(is(X == JSONObject!(char)))
	{
		return ClassVarT.JSONObject;
	}+/
	else static if(is(X == class))
	{
		return ClassVarT.Class;
	}
	else static if(is(X == struct))
	{
		return ClassVarT.Struct;
	}
	else return ClassVarT.Null;
}

class VarBindingVisitor
{
	VarInfo[uint] bindings;
	
	void visit(T)(T x, uint index)
	{
		VarInfo info;
		info.type = getClassVarT!(T);
		if(info.type == ClassVarT.Null) return;
		static if(is(T == class)) {
			info.clsBinding = new ClassBinding!(T);
		}
		else static if(is(T == struct)) {
			info.clsBinding = new ClassBinding!(T, true);
		}
		else static if(isDynamicArrayType!(T) && !is(T == char[])) {
			info.arrayBinding = new ArrayVar!(T);
		}
		else static if(isAssocArrayType!(T)) {
			info.clsBinding = new AssocArrayVar!(T);
		}
		bindings[index] = info;
	}
}

enum ClassVarT : ubyte {  Bool, Byte, Short, Int, Long, UByte, UShort, UInt, ULong, Float, Double, String, DateTime, Time, Class, Struct, Array, AssocArray, Null };

class ClassBinding(T, bool isStruct = false) : IObject, IClassBinding
{
	static void init()
	{
		auto v = new VarBindingVisitor;
		T t;
		static if(!isStruct) t = new T;
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
	private static Var[char[]] validationInfo;
	
	private this(void* ptr)
	{
		t = cast(T)ptr;
	}
	
	private T t;
	this(T t)
	{
		this.t = t;
	}
	
	IObject createInstance(void* ptr)
	{
		return new ClassBinding!(T, isStruct)(ptr);
	}
	
	private void getVar(inout VarInfo varInfo, inout Var var)
	{
		static if(!isStruct)
			if(t is null) { var.type = VarT.Null; return;}
		
		void* ptr = cast(void*)t + varInfo.offset;
		switch(varInfo.type)
		{
		case(ClassVarT.Bool):
			set(var, *cast(bool*)ptr);
			break;
		case(ClassVarT.Byte):
			set(var, *cast(byte*)ptr);
			break;
		case(ClassVarT.Short):
			set(var, *cast(short*)ptr);
			break;
		case(ClassVarT.Int):
			set(var, *cast(int*)ptr);
			break;
		case(ClassVarT.Long):
			set(var, *cast(long*)ptr);
			break;
		case(ClassVarT.UByte):
			set(var, *cast(ubyte*)ptr);
			break;
		case(ClassVarT.UShort):
			set(var, *cast(ushort*)ptr);
			break;
		case(ClassVarT.UInt):
			set(var, *cast(uint*)ptr);
			break;
		case(ClassVarT.ULong):
			set(var, *cast(ulong*)ptr);
			break;
		case(ClassVarT.Float):
			set(var, *cast(float*)ptr);
			break;
		case(ClassVarT.Double):
			set(var, *cast(double*)ptr);
			break;
		case(ClassVarT.String):
			set(var, *cast(char[]*)ptr);
			break;
		case(ClassVarT.DateTime):
			bind(var, *cast(DateTime*)ptr);
			break;
		case(ClassVarT.Time):
			set(var, *cast(Time*)ptr);
			break;
		case(ClassVarT.Class):
			var.type = VarT.Object;
			var.obj_ = varInfo.clsBinding.createInstance(*cast(void**)ptr);
			break;
		case(ClassVarT.Struct):
			var.type = VarT.Object;
			var.obj_ = varInfo.clsBinding.createInstance(ptr);
			break;
		case(ClassVarT.Array):
			var.type = VarT.Array;
			var.array_ = varInfo.arrayBinding.createInstance(ptr);
			break;
		case(ClassVarT.AssocArray):
			var.type = VarT.Object;
			var.obj_ = varInfo.clsBinding.createInstance(ptr);
			break;
		default:
			debug assert(false, "Unhandled class bind type");
			var.type = VarT.Null; 
			break;
		}
//		if(varInfo.filter) { var = varInfo.filter(var); }
	}
	
	Var opIndex(char[] varName)
	{
		if(!initialized) init;
		
		auto pInfo = (varName in bindInfo);
		if(pInfo) {
			Var var;
			getVar(*pInfo, var);
			return var;
		}
		return Var();
	}
	
	int opApply (int delegate (inout char[] key, inout Var val) dg)
	{
		if(!initialized) init;
		
		int res;
		
	    foreach(name, varInfo; bindInfo)
	    {
	        Var var;
	        getVar(varInfo, var);
	        if ((res = dg(name, var)) != 0)
	            break;
	    }
	    
	    return res;
	}
	
	size_t length()
	{
		if(!initialized) init;
		return bindInfo.length;
	}
	
	void opIndexAssign(Var, char[] key)
	{
		debug assert(false);
	}
	
	Var opCall(Var[] params, IExecContext ctxt) { return Var(); }
	void toString(IExecContext ctxt, void delegate(char[]) utf8Writer, char[] flags = null) { }
}