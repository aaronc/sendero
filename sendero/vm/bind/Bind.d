module sendero.vm.bind.Bind;

import sendero_base.Core;
import sendero_base.Set;

import tango.core.Traits;

void bind(T)(ref Var var, T val)
{
	static if( is( typeof( set!(T) ) ) )
		set(var, val);
	else static if(isDynamicArrayType!(T)) {
		var.type = VarT.Array;
		var.array_ = new ArrayVariableBinding!(T)(val);
	}
	else static if(isAssocArrayType!(T)) {
		var.type = VarT.Object;
		var.obj_ = new AssocArrayVariableBinding!(T)(val);
	}
	else static if(is(X == class))
	{
		var.type = VarT.Object;
		var.obj_ = new ClassBinding!(T)(val);
	}
	else static assert(false, "Unable to bind variable of type " ~ T.stringof);
}


interface IDynArrayBinding
{
	IArray createInstance(void* ptr);
}

class ArrayVariableBinding(T) : IArray, IDynArrayBinding
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
		return new ArrayVariableBinding!(T)(ptr);
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
		bind(var, t[i]);
		return var;
	}
	
	size_t length() { return t.length;}
	
	void opCatAssign(Var v) { }
}

class AssocArrayVariableBinding(T) : IObjectBinding, IClassBinding
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
	
	IObjectBinding createInstance(void* ptr)
	{
		return new AssocArrayVariableBinding!(T)(ptr);
	}
	
	int opApply (int delegate (inout char[] key, inout VariableBinding val) dg)
    {
	    int res;
	
	    foreach(k, v; t)
	    {
	        VariableBinding var;
	        var.set(v);
	        if ((res = dg(k, var)) != 0)
	            break;
	    }
	
		return res;
    }
	
	VariableBinding opIndex(char[] key)
	{
		auto pVal = (key in t);
		if(!pVal) return VariableBinding();
		VariableBinding var;
		var.set(*pVal);
		return var;
	}
	
	size_t length() { return t.length;}
	
	void opIndexAssign(inout VariableBinding, char[] key)
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
	IPropertyService propertyService;
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
	else static if(is(X == Date))
	{
		return ClassVarT.Date;
	}
	else static if(is(X == Time))
	{
		return ClassVarT.Time;
	}
	else static if(is(X == JSONObject!(char)))
	{
		return ClassVarT.JSONObject;
	}
	else static if(is(X == class))
	{
		return ClassVarT.ClassStruct;
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
		else static if(isDynamicArrayType!(T) && !is(T == char[])) {
			info.arrayBinding = new ArrayVariableBinding!(T);
		}
		else static if(isAssocArrayType!(T)) {
			info.clsBinding = new AssocArrayVariableBinding!(T);
		}
		bindings[index] = info;
	}
}

enum ClassVarT : ubyte {  Bool, Byte, Short, Int, Long, UByte, UShort, UInt, ULong, Float, Double, String, DateTime, Date, Time, ClassStruct, Array, AssocArray, JSONObject, Null };

class ClassBinding(T) : IObjectBinding, IClassBinding
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
	private static VariableBinding[char[]] validationInfo;
	
	private this(void* ptr)
	{
		t = cast(T)ptr;
	}
	
	private T t;
	this(T t)
	{
		this.t = t;
	}
	
	IObjectBinding createInstance(void* ptr)
	{
		return new ClassBinding!(T)(ptr);
	}
	
	private void getVar(inout VarInfo varInfo, inout VariableBinding var)
	{
		if(!t) { var.type = VarT.Null; return;}
		
		void* ptr = cast(void*)t + varInfo.offset;
		switch(varInfo.type)
		{
		case(ClassVarT.Bool):
			var.set(*cast(bool*)ptr);
			break;
		case(ClassVarT.Byte):
			var.set(*cast(byte*)ptr);
			break;
		case(ClassVarT.Short):
			var.set(*cast(short*)ptr);
			break;
		case(ClassVarT.Int):
			var.set(*cast(int*)ptr);
			break;
		case(ClassVarT.Long):
			var.set(*cast(long*)ptr);
			break;
		case(ClassVarT.UByte):
			var.set(*cast(ubyte*)ptr);
			break;
		case(ClassVarT.UShort):
			var.set(*cast(ushort*)ptr);
			break;
		case(ClassVarT.UInt):
			var.set(*cast(uint*)ptr);
			break;
		case(ClassVarT.ULong):
			var.set(*cast(ulong*)ptr);
			break;
		case(ClassVarT.Float):
			var.set(*cast(float*)ptr);
			break;
		case(ClassVarT.Double):
			var.set(*cast(double*)ptr);
			break;
		case(ClassVarT.String):
			var.set(*cast(char[]*)ptr);
			break;
		case(ClassVarT.DateTime):
			var.set(*cast(DateTime*)ptr);
			break;
		case(ClassVarT.Date):
			var.set(*cast(Date*)ptr);
			break;
		case(ClassVarT.Time):
			var.set(*cast(Time*)ptr);
			break;
		case(ClassVarT.ClassStruct):
			var.type = VarT.Object;
			var.objBinding = varInfo.clsBinding.createInstance(*cast(void**)ptr);
			break;
		case(ClassVarT.Array):
			var.type = VarT.Array;
			var.arrayBinding = varInfo.arrayBinding.createInstance(ptr);
			break;
		case(ClassVarT.AssocArray):
			var.type = VarT.Object;
			var.objBinding = varInfo.clsBinding.createInstance(ptr);
			break;
		default:
			debug assert(false, "Unhandled class bind type");
			var.type = VarT.Null; 
			break;
		}
		var.propertyService = varInfo.propertyService;
//		if(varInfo.filter) { var = varInfo.filter(var); }
	}
	
	VariableBinding opIndex(char[] varName)
	{
		if(!initialized) init;
		
		auto pInfo = (varName in bindInfo);
		if(pInfo) {
			VariableBinding var;
			getVar(*pInfo, var);
			return var;
		}
		return VariableBinding();
	}
	
	int opApply (int delegate (inout char[] key, inout VariableBinding val) dg)
	{
		if(!initialized) init;
		
		int res;
		
	    foreach(name, varInfo; bindInfo)
	    {
	        VariableBinding var;
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
	
	void opIndexAssign(inout VariableBinding, char[] key)
	{
		debug assert(false);
	}
}