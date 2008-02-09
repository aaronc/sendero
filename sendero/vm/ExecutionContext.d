module sendero.vm.ExecutionContext;

public import sendero.json.JsonObject;

import sendero.util.Reflection;
import sendero.xml.XmlNode;

public import tango.core.Traits;
public import tango.group.time;
//public import tango.time.Date;
import tango.text.Util;
debug import tango.io.Stdout;

version(ICU) {
	import mango.icu.ULocale;
	import mango.icu.UTimeZone;
	alias ULocale Locale;
	alias UTimeZone Timezone;
}
else {
	alias char[] Locale;
	alias char[] Timezone;
}

enum VarT : ubyte { Null, Bool, Long, Double, String, DateTime, Array, Object, Function, Node, Binary, Stream }; //TODO change Bool to True, False???

alias VariableBinding Var;
alias void delegate(void delegate(void[])) Stream;

struct VariableBinding
{
    static VariableBinding opCall()
    {
    	VariableBinding b;
    	return b;
    }
	
	union
	{
		IArrayBinding arrayBinding;
		IObjectBinding objBinding;
		IFunctionBinding funcBinding;
		XmlNode xmlNode;
		Stream stream;
		bool bool_;		
		long long_;
		double double_;
		char[] string_;
		Time dateTime_;
		ubyte[] binary_;
	}
	
	VarT type = VarT.Null;
	byte tainted = 0;
	IPropertyService propertyService = null;
	
	package void set(X)(X val)
	{
		propertyService = null;
		static if(is(X == bool)) {
			type = cast(VarT)VarT.Bool;
			bool_ = val;
		}
		else static if(isIntegerType!(X)) {
			type = cast(VarT)VarT.Long;
			long_ = val;
		}
		else static if(isDoubleT!(X)) {
			type = cast(VarT)VarT.Double;
			double_ = val;
		}
		else static if(is(X:char[])) {
			type = cast(VarT)VarT.String;
			string_ = val;
		}
		else static if(isDynamicArrayType!(X)) {
			type = cast(VarT)VarT.Array;
			arrayBinding = new ArrayVariableBinding!(X)(val);
		}
		else static if(isAssocArrayType!(X)) {
			type = cast(VarT)VarT.Object;
			objBinding = new AssocArrayVariableBinding!(X)(val);
		}
		else static if(is(X == Time))
		{
			type = cast(VarT)VarT.DateTime;
			dateTime_ = val;
		}
	/*	else static if(is(X == Date))
		{
			type = cast(VarT)VarT.DateTime;
			dateTime_ = DateTime(val.year, val.month, val.day);
			dateTime_.addHours(val.hour);
			dateTime_.addMinutes(val.min);
			dateTime_.addSeconds(val.sec);
		}
		else static if(is(X == Time))
		{
			type = cast(VarT)VarT.DateTime;
			dateTime_ = DateTime(val);
		}*/
		else static if(is(X == JSONObject!(char)))
		{
			type = cast(VarT)VarT.Object;
			objBinding = new JSONObjectBinding(val);
		}
		else static if(is(X == XmlNode))
		{
			type = VarT.Node;
			xmlNode = val;
		}
		else static if(is(X == class))
		{
			type = cast(VarT)VarT.Object;
			objBinding = new ClassBinding!(X)(val);
		}
		else {
			debug assert(false, "Unable to bind variable");
			type = cast(VarT)VarT.Null;
		}
	}
	
	void opAssign(X)(X x)
	{
		set(x);
		tainted = true;
	}
	
	bool opEquals(inout Var v)
	{
		switch(type)
		{
		case VarT.String:
			if(v.type == VarT.String) return string_ == v.string_;
			return false;
		case VarT.Long:
		{
			switch(v.type)
			{
			case VarT.Long:
				return long_ == v.long_;
			case VarT.Double:
				return long_ == v.double_;
			default:
				return false;
			}
		}
		case VarT.Double:
		{
			switch(v.type)
			{
			case VarT.Long:
				return double_ == v.long_;
			case VarT.Double:
				return double_ == v.double_;
			default:
				return false;
			}
		}
		case VarT.Bool:
			if(v.type == VarT.Bool) return bool_ == v.bool_;
			return false;
		case VarT.DateTime:
			if(v.type == VarT.DateTime) return dateTime_ == v.dateTime_ ? true : false;
			return false;
		case VarT.Array:
			if(v.type == VarT.Array) return arrayBinding == v.arrayBinding;
			return false;
		case VarT.Object:
			if(v.type == VarT.Object) return objBinding == v.objBinding;
			return false;
		default:
			return false;
		}
	}
	
	bool opEquals(long x)
	{
		switch(type)
		{
		case VarT.Long:
			return long_ == x;
		case VarT.Double:
			return double_ == x;
		default:
			return false;
		}
	}	

	int opCmp(long x)
	{
		switch(type)
		{
		case VarT.Long:
			if(long_ < x) return -1; else if(long_ > x) return 1; else return 0;
		case VarT.Double:
			if(double_ < x) return -1; else if(double_ > x) return 1; else return 0;
		default:
			return 0;
		}
	}
	
	bool opEquals(real x)
	{
		switch(type)
		{
		case VarT.Long:
			return long_ == x;
		case VarT.Double:
			return double_ == x;
		default:
			return false;
		}
	}	

	int opCmp(real x)
	{
		switch(type)
		{
		case VarT.Long:
			if(long_ < x) return -1; else if(long_ > x) return 1; else return 0;
		case VarT.Double:
			if(double_ < x) return -1; else if(double_ > x) return 1; else return 0;
		default:
			return 0;
		}
	}
	
	int opCmp(inout Var v)
	{
		switch(type)
		{
		case VarT.String:
			if(v.type == VarT.String) {if(string_ < v.string_) return -1; else if(string_ > v.string_) return 1; else return 0;}
			else return 0;
		case VarT.Long:
		{
			switch(v.type)
			{
			case VarT.Long:
				if(long_ < v.long_) return -1; else if(long_ > v.long_) return 1; else return 0;
			case VarT.Double:
				if(long_ < v.double_) return -1; else if(long_ > v.double_) return 1; else return 0;
			default:
				return 0;
			}
		}
		case VarT.Double:
		{
			switch(v.type)
			{
			case VarT.Long:
				if(double_ < v.long_) return -1; else if(double_ > v.long_) return 1; else return 0;
			case VarT.Double:
				if(double_ < v.double_) return -1; else if(double_ > v.double_) return 1; else return 0;
			default:
				return 0;
			}
		}
		case VarT.Bool:
			if(v.type == VarT.Bool) {if(bool_ < v.bool_) return -1; else if(bool_ > v.bool_) return 1; else return 0;}
			return 0;
		case VarT.DateTime:
			if(v.type == VarT.DateTime) {if(dateTime_ < v.dateTime_) return -1; else if(dateTime_ > v.dateTime_) return 1; else return 0;}
			return 0;
		default:
			return 0;
		}
	}
	
	VariableBinding opAdd(VariableBinding v)
	{
		VariableBinding res = VariableBinding();
		switch(type)
		{
		case VarT.String:
			if(v.type == VarT.String) {res.set(string_ ~ v.string_); return res;}
			else return res;
		case VarT.Long:
		{
			switch(v.type)
			{
			case VarT.Long:
				res.set(cast(long)(long_ + v.long_)); return res; 
			case VarT.Double:
				res.set(cast(double)(long_ + v.double_)); return res;
			default:
				res.set(0); return res;
			}
		}
		case VarT.Double:
		{
			switch(v.type)
			{
			case VarT.Long:
				res.set(double_ + v.long_); return res;
			case VarT.Double:
				res.set(double_ + v.double_); return res;
			default:
				res.set(0); return res;
			}
		}
		case VarT.DateTime:
			res.set(dateTime_ + v.dateTime_.span); return res;
		default:
			return res;
		}
	}
	
	VariableBinding opSub(VariableBinding v)
	{
		VariableBinding res = VariableBinding();
		switch(type)
		{
		case VarT.Long:
		{
			switch(v.type)
			{
			case VarT.Long:
				res.set(long_ - v.long_); return res; 
			case VarT.Double:
				res.set(long_ - v.double_); return res;
			default:
				res.set(0); return res;
			}
		}
		case VarT.Double:
		{
			switch(v.type)
			{
			case VarT.Long:
				res.set(double_ - v.long_); return res;
			case VarT.Double:
				res.set(double_ - v.double_); return res;
			default:
				res.set(0); return res;
			}
		}
		case VarT.DateTime:
			res.set(dateTime_ - v.dateTime_); return res;
		default:
			return res;
		}
	}
	
	VariableBinding opMul(VariableBinding v)
	{
		VariableBinding res = VariableBinding();
		switch(type)
		{
		case VarT.Long:
		{
			switch(v.type)
			{
			case VarT.Long:
				res.set(long_ * v.long_); return res; 
			case VarT.Double:
				res.set(long_ * v.double_); return res;
			default:
				res.set(0); return res;
			}
		}
		case VarT.Double:
		{
			switch(v.type)
			{
			case VarT.Long:
				res.set(double_ * v.long_); return res;
			case VarT.Double:
				res.set(double_ * v.double_); return res;
			default:
				res.set(0); return res;
			}
		}
		default:
			return res;
		}
	}
	
	VariableBinding opDiv(VariableBinding v)
	{
		VariableBinding res = VariableBinding();
		switch(type)
		{
		case VarT.Long:
		{
			switch(v.type)
			{
			case VarT.Long:
				res.set(long_ / v.long_); return res; 
			case VarT.Double:
				res.set(long_ / v.double_); return res;
			default:
				res.set(0); return res;
			}
		}
		case VarT.Double:
		{
			switch(v.type)
			{
			case VarT.Long:
				res.set(double_ / v.long_); return res;
			case VarT.Double:
				res.set(double_ / v.double_); return res;
			default:
				res.set(0); return res;
			}
		}
		default:
			return res;
		}
	}
	
	VariableBinding opMod(VariableBinding v)
	{
		VariableBinding res = VariableBinding();
		switch(type)
		{
		case VarT.Long:
		{
			switch(v.type)
			{
			case VarT.Long:
				res.set(long_ % v.long_); return res; 
			case VarT.Double:
				res.set(long_ % v.double_); return res;
			default:
				res.set(0); return res;
			}
		}
		case VarT.Double:
		{
			switch(v.type)
			{
			case VarT.Long:
				res.set(double_ % v.long_); return res;
			case VarT.Double:
				res.set(double_ % v.double_); return res;
			default:
				res.set(0); return res;
			}
		}
		default:
			return res;
		}
	}
	
	VariableBinding opIndex(char[] key)
	{
		VariableBinding var;
		if(type == VarT.Object) {
			auto v = objBinding[key];
			if(v.type == VarT.Null) {
				v = ObjectPropertyService.global.getProperty(key, *this);
			}
			var = v;
		}
		else if(propertyService) {
			auto v = propertyService.getProperty(key, var);
			var = v;
		}
		
		if(var.type == VarT.Null) {
			if(type == VarT.DateTime) {
				auto v = DateTimePropertyService.global.getProperty(key, *this);
				var = v;
			}
			else if(type == VarT.Array) {
				auto v = ArrayPropertyService.global.getProperty(key, *this);
				var = v;
			}
			else return VariableBinding();
		}
	}
}

template isDoubleT( T )
{
    const bool isDoubleT = 	is( T == float )  ||
    					 	is( T == double );
}

interface IObjectBinding
{
	VariableBinding opIndex(char[] key);
	int opApply (int delegate (inout char[] key, inout VariableBinding val) dg);
	void opIndexAssign(inout VariableBinding, char[] key);
	size_t length();
	/*void get(inout Var v);
	void set(inout Var v);
	void opCall(inout Var v);*/
}

interface IClassBinding
{
	IObjectBinding createInstance(void* ptr);
}

interface IArrayBinding
{
	int opApply (int delegate (inout VariableBinding val) dg);
	VariableBinding opIndex(size_t i);
	size_t length();
	//void opCatAssign(inout VariableBinding var);
	//void opIndexAssign(inout VariableBinding var, size_t i);
}

interface IDynArrayBinding
{
	IArrayBinding createInstance(void* ptr);
}

interface IFunctionBinding
{
	VariableBinding exec(VariableBinding[] params, ExecutionContext parentCtxt);
}

interface IPropertyService
{
	VariableBinding getProperty(char[] name, inout VariableBinding var);
}

class ArrayVariableBinding(T) : IArrayBinding, IDynArrayBinding
{
	private this() { }
	private this(void* ptr)
	{
		auto pt = cast(T*)ptr;
		t = *pt;
	}
	this(T t) { this.t = t;}	
	private T t;
	
	IArrayBinding createInstance(void* ptr)
	{
		return new ArrayVariableBinding!(T)(ptr);
	}
	
	int opApply (int delegate (inout VariableBinding val) dg)
    {
	    int res;
	
	    foreach(x; t)
	    {
	        VariableBinding var;
	        var.set(x);
	        if ((res = dg(var)) != 0)
	            break;
	    }
	
		return res;
    }
	
	VariableBinding opIndex(size_t i)
	{
		if(i > t.length) return VariableBinding();
		VariableBinding var;
        var.set(t[i]);
		return var;
	}
	size_t length() { return t.length;}
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

class ClassPropertyService : IPropertyService
{
	private this() {}
	
	VariableBinding getProperty(char[] name, inout VariableBinding var)
	{
		switch(name)
		{
		default:
			break;
		}
		
		return VariableBinding();
	}
}

void getJSONValue(JSONValue!(char) val, inout VariableBinding var)
{
	with(JSONValueType)
	{
		switch(val.type)
		{
		case String:
			var.set(val.getString);
			break;
		case Number:
			var.set(cast(double)val.getNumber);
			break;
		case Object:
			var.set(val.getObject);
			break;
		case Array:
			var.type = VarT.Array;
			var.arrayBinding = new JSONArrayWrapper(val);
			break;
		case True:
			var.set(cast(bool)true);
			break;
		case False:
			var.set(cast(bool)false);
			break;
		case Null:
		default:
			var.type = VarT.Null;
			break;
		}
	}
}

class JSONObjectBinding : IObjectBinding
{
	this(JSON json) { this.json = json; }
	private JSON json;
	
	VariableBinding opIndex(char[] varName)
	{
		if(!json) return VariableBinding();
		
		auto pVal = (varName in json.members);
		if(!pVal) return VariableBinding();
		
		VariableBinding var;
		getJSONValue(*pVal, var);	
		return var;
	}
	
	int opApply (int delegate (inout char[] key, inout VariableBinding val) dg)
	{
		int res;
		if(!json) return 0;
	
		foreach(key, val; json.members)
		{
			VariableBinding var;
		    getJSONValue(val, var);
	        if ((res = dg(key, var)) != 0)
	            break;
	    }
		
		return res;
	}
	
	size_t length()
	{
		if(!json) return 0;
		return json.members.length;
	}
	
	void opIndexAssign(inout VariableBinding, char[] key)
	{
		debug assert(false);
	}
}

class JSONArrayWrapper : IArrayBinding
{
	this(JSONValue!(char) val)
	{
		debug assert(val.type == JSONValueType.Array);
		this.arr = val.getArray;
		debug assert(arr.length);
	}
	
	JSONValue!(char)[] arr;
	
	void set(void*) {}
	
	int opApply (int delegate (inout VariableBinding var) dg)
    {
	    int res;
	
	    foreach(x; arr)
	    {
	    	VariableBinding var;
	    	getJSONValue(x, var);
	        if ((res = dg(var)) != 0)
	            break;
	    }
	
		return res;
    }
	
	VariableBinding opIndex(size_t i)
	{
		if(i > arr.length) return VariableBinding();
		VariableBinding var;
		getJSONValue(arr[i], var);
		return var;
	}
	
	size_t length() { return arr.length;}
}

class ExecutionContext
{
	static this()
	{
		global = new ExecutionContext;
		global.parent = null;
	}
	static ExecutionContext global;
	
	VariableBinding[char[]] vars;
	Locale locale;
	Timezone timezone;
	XmlNode contextNode;
	
	FunctionBindingContext[] runtimeImports;
	
	IFunctionBinding getRuntimeFunction(char[] fnName)
	{
		foreach(i; runtimeImports)
		{
			auto fn = i.getFunction(fnName);
			if(fn) return fn;
		}
		return null;
	}
	
	ExecutionContext parent;
	
	version(ICU) {
		this(Locale locale = ULocale.US)
		{
			this.locale = locale;
			this.parent = global;
			this.timezone = UTimeZone.Default;
		}
		
		this(ExecutionContext parent, Locale locale = ULocale.US)
		{
			this.locale = locale;
			this.parent = parent;
			this.timezone = UTimeZone.Default;
		}
	}
	else {
		this(Locale locale = "en-US")
		{
			this.locale = locale;
			this.parent = global;
		}
		
		this(ExecutionContext parent, Locale locale = "en-US")
		{
			this.locale = locale;
			this.parent = parent;
		}
	}
	
	final void addVar(T)(char[] name, T t)
	{
		static if(is(T == VariableBinding)) {
			vars[name] = t;
			return;
		}
		
		VariableBinding var;
		var.set(t);
		vars[name] = var;
	}
	
	final void addVarAsRoot(T)(T t)
	{
		/*auto clsBinding = new ClassStructBinding!(T)(t);
		foreach(name, i; clsBinding.VarInfo)
		{
			auto v = clsBinding.getVar(name);
			if(v.type != VarT.Null) {
				vars[name] = v;
			}
		}*/
		VariableBinding var;
		var.set(t);
		debug assert(var.type == VarT.Object, "Variable of type " ~ T.stringof ~ " cannot be bound as a root variable");
		if(var.type != VarT.Object) return;
		auto obj = var.objBinding;
		foreach(key, val; obj)
		{
			vars[key] = val;
		}
	}
	
	final VariableBinding getVar(char[] var)
	{
		auto pVar = (var in vars);
		if(!pVar) {
			if(parent) return parent.getVar(var);
			return VariableBinding();
		}
		return *pVar;
	}
	
	final VariableBinding getVar(VarPath varPath)
	{
		if(!varPath.path.length) return VariableBinding();
		
		auto pVar = (varPath.path[0] in vars);
		if(!pVar) {
			if(parent) return parent.getVar(varPath);
			return VariableBinding();
		}
		VariableBinding var = *pVar;
		
		uint n = 1;
		while(varPath.path.length > n) {
			if(var.type == VarT.Object) {
				auto v = var.objBinding[varPath.path[n]];
				if(v.type == VarT.Null) {
					v = ObjectPropertyService.global.getProperty(varPath.path[n], var);
				}
				var = v;
			}
			else if(var.propertyService) {
				auto v = var.propertyService.getProperty(varPath.path[n], var);
				var = v;
			}
			
			if(var.type == VarT.Null) {
				if(var.type == VarT.DateTime) {
					auto v = DateTimePropertyService.global.getProperty(varPath.path[n], var);
					var = v;
				}
				else if(var.type == VarT.Array) {
					auto v = ArrayPropertyService.global.getProperty(varPath.path[n], var);
					var = v;
				}
				else return VariableBinding();
			}			
			++n;
		}
		return var;
	}
	
	final void removeVar(char[] name)
	{
		auto v = (name in vars);
		if(v) vars.remove(name);
	}
	
	VariableBinding lastReturnVal;
	ScopeAction scopeAction;
}

enum ScopeAction : int {None = 0, Return, Yield, SecureYield, Break, Continue, Throw};

class FunctionBindingContext
{
	static this()
	{
		global = new FunctionBindingContext;
		global.parent = null;
		global.addFunction("now", new Now);
		global.addFunction("getVar", new GetVar);
		global.addFunction("strcat", new StringCat);
	}
	static FunctionBindingContext global;
	
	IFunctionBinding[char[]] fns;
	FunctionBindingContext parent;
	FunctionBindingContext[] imports;
	
	this()
	{
		this.parent = global;
	}
	
	this(FunctionBindingContext parent)
	{
		this.parent = parent;
	}
	
	void addFunction(char[] name, IFunctionBinding func)
	{
		fns[name] = func;
	}
	
	IFunctionBinding getFunction(char[] name)
	{
		auto pFn = (name in fns);
		if(pFn) return *pFn;
	
		if(parent) {
			auto fn = parent.getFunction(name);
			if(fn) return fn;
		}
		
		foreach(i; imports)
		{
			auto fn = i.getFunction(name);
			if(fn) return fn;
		}
		
		return null;
	}
}

class ObjectPropertyService : IPropertyService
{
	static this()
	{
		global = new ObjectPropertyService;
	}
	static ObjectPropertyService global;
	
	this() {}
	
	VariableBinding getProperty(char[] name, inout VariableBinding var)
	{
		if(var.type != VarT.Object) return VariableBinding();
		
		auto obj = var.objBinding;
		
		VariableBinding res;
		switch(name)
		{
		case "length":
			res.set(obj.length);
			break;
		default:
			res.type = VarT.Null;
			break;
		}
		return res;
	}
}

class DateTimePropertyService : IPropertyService
{
	static this()
	{
		global = new DateTimePropertyService;
	}
	static DateTimePropertyService global;
	
	this() {}
	
	VariableBinding getProperty(char[] name, inout VariableBinding var)
	{
		if(var.type != VarT.DateTime) return VariableBinding();
		
		//auto dateTime = var.dateTime_;
		auto dt = Clock.toDate(var.dateTime_);
		
		VariableBinding res;
		switch(name)
		{
		case "year":
			res.set(dt.date.year);
			break;
		case "month":
			res.set(dt.date.month);
			break;
		case "day":
			res.set(dt.date.day);
			break;
		case "hour":
			res.set(dt.time.hours);
			break;
		case "minute":
			res.set(dt.time.minutes);
			break;
		case "second":
			res.set(dt.time.seconds);
			break;
		default:
			res.type = VarT.Null;
			break;
		}
		return res;
	}
}


class ArrayPropertyService : IPropertyService
{
	static this()
	{
		global = new ArrayPropertyService;
	}
	static ArrayPropertyService global;
	
	//private this() {}
	
	VariableBinding getProperty(char[] name, inout VariableBinding var)
	{
		if(var.type != VarT.Array) return VariableBinding();
		
		auto obj = var.objBinding;
		
		VariableBinding res;
		switch(name)
		{
		case "length":
			res.set(obj.length);
			break;
		default:
			res.type = VarT.Null;
			break;
		}
		return res;
	}
}

enum ExpressionT : ubyte { Null, Var, Value, FuncCall, TextExpr, Binary, VarAccess};

struct Expression
{
	ExpressionT type;
	union
	{
		VariableBinding val;
		VarPath var;
		VarAccess varAccess;
		FunctionCall func;
		BinaryExpression binaryExpr;
	}
	
	VariableBinding exec(ExecutionContext ctxt)
	{
		switch(type)
		{
		case ExpressionT.Var:
			return ctxt.getVar(var);
		case ExpressionT.Value:
			return val;
		case ExpressionT.FuncCall:
			return func.exec(ctxt);
		case ExpressionT.Binary:
			return binaryExpr.exec(ctxt);
		case ExpressionT.VarAccess:
			return varAccess.get(ctxt);
		default:
			return VariableBinding();
		}
	}
}

enum BinaryExpressionT : ubyte {
	Or = 1, And = 2, Mul = 3, Div = 4, Mod = 5, Add = 6, Sub = 7, 
	Eq = 8, Gr = 9, GrEq = 10, LtEq = 11, Lt = 12, NotEq = 13,
	In = 27};
alias BinaryExpressionT OperatorT;

struct BinaryExpression
{
	static BinaryExpression opCall()
	{
		BinaryExpression be;
		be.expr.length = 2;
		return be;
	}
	ubyte type;
	Expression[] expr;
	VariableBinding exec(ExecutionContext ctxt)
		in
		{
			assert(expr.length == 2);
		}
		body
		{
			auto v1 = expr[0].exec(ctxt);
			auto v2 = expr[1].exec(ctxt);
			VariableBinding res = VariableBinding();
			with(BinaryExpressionT) {
				switch(type)
				{
				case Eq:
					res.set(v1 == v2);
					return res;
				case NotEq:
					res.set(v1 != v2);
					return res;
				case Gr:
					res.set(v1 > v2);
					return res;
				case Lt:
					res.set(v1 < v2);
					return res;
				case GrEq:
					res.set(v1 >= v2);
					return res;
				case LtEq:
					res.set(v1 <= v2);
					return res;
				case Add:
					return v1 + v2;
				case Sub:
					return v1 - v2;
				case Mul:
					return v1 * v2;
				case Div:
					return v1 / v2;
				case Mod:
					return v1 % v2;
				/*case Or:
					return v1 || v2;
				case And:
					return v1 && v2;*/
				default:
					return VariableBinding();
				}
			}
			return VariableBinding();
		}
}

struct AccessStep
{
	union
	{
		Expression expr;
		char[] identifier;
	}
	bool expression = false;
}

struct VarAccess
{
	char[] rootName;
	AccessStep[] access;
	
	VariableBinding get(ExecutionContext ctxt)
	{
		return VariableBinding();
	}
	
	void set(inout VariableBinding var, ExecutionContext ctxt)
	{
		return VariableBinding();
	}
}

struct FunctionCall
{
	IFunctionBinding func;
	Expression[] params;
	
	static FunctionCall opCall()
	{
		FunctionCall res;
		res.func = null;
		res.params.length = 0;
		return res;
	}
	
	VariableBinding exec(ExecutionContext ctxt)
		in
		{
			assert(func);
		}
		body
		{		
			VariableBinding[] funcParams;
			
			auto n = params.length;
			funcParams.length = n;
				
			for(size_t i = 0; i < n; ++i)
			{
				funcParams[i] = params[i].exec(ctxt);
			}
			return func.exec(funcParams, ctxt);
		}
}

struct VarPath
{
	static VarPath opCall(char[] varPath)
	{
		VarPath v;
		uint i = 0;
		while(i < varPath.length) {
			uint j = locate(varPath, '.', i);
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

class Now : IFunctionBinding
{
	VariableBinding exec(VariableBinding[] params, ExecutionContext parentCtxt)
	{
		VariableBinding var;
		var.set(Clock.now);
		return var;
	}
}

class NotFn : IFunctionBinding
{
	VariableBinding exec(VariableBinding[] params, ExecutionContext parentCtxt)
	{
		VariableBinding var;
		if(!params.length) {var.set(true); return var;}
		var.set(cast(bool)(var != cast(long)true));
		return var;
	}
}

class NegativeFn : IFunctionBinding
{
	VariableBinding exec(VariableBinding[] params, ExecutionContext parentCtxt)
	{
		if(!params.length) return VariableBinding();
		VariableBinding neg;
		neg.set(cast(long)-1);
		auto res = params[0] * neg;
		return res;
	}
}

class GetVar : IFunctionBinding
{
	VariableBinding exec(VariableBinding[] params, ExecutionContext parentCtxt)
	{
		if(params.length < 1 || params[0].type != VarT.String) return VariableBinding();
		auto varPath = VarPath(params[0].string_);
		return parentCtxt.getVar(varPath);
	}
}

class StringCat : IFunctionBinding
{
	VariableBinding exec(VariableBinding[] params, ExecutionContext parentCtxt)
	{
		char[] res;
		foreach(p; params)
		{
			if(p.type != VarT.String) return VariableBinding();
			res ~= p.string_;
		}
		VariableBinding var;
		var.type = cast(VarT)VarT.String;
		var.string_ = res;
		return var;
	}
}

class LateBindingFunction : IFunctionBinding
{
	this(char[] fnName)
	{
		this.fnName = fnName;
	}
	char[] fnName;
	
	VariableBinding exec(VariableBinding[] params, ExecutionContext parentCtxt)
	{
		auto fn = parentCtxt.getRuntimeFunction(fnName);
		if(fn) return fn.exec(params, parentCtxt);
		else return VariableBinding();
	}
}

class VarPathBindingFunction : IFunctionBinding
{	
	this(VarPath path)
	{
		this.path = path;
	}
	VarPath path;
	
	VariableBinding exec(VariableBinding[] params, ExecutionContext parentCtxt)
	{
		auto fn = parentCtxt.getVar(path);
		if(fn.type == VarT.Function) return fn.funcBinding.exec(params, parentCtxt);
		else return fn;
	}
}

class VarAccessBindingFunction : IFunctionBinding
{	
	this(VarAccess access)
	{
		this.access = access;
	}
	VarAccess access;
	
	VariableBinding exec(VariableBinding[] params, ExecutionContext parentCtxt)
	{
		auto fn = access.get(parentCtxt);
		if(fn.type == VarT.Function) return fn.funcBinding.exec(params, parentCtxt);
		else return fn;
	}
}

class NullFunction : IFunctionBinding
{
	VariableBinding exec(VariableBinding[] params, ExecutionContext parentCtxt)
	{
		return VariableBinding();
	}
}

version(Unittest)
{
import tango.io.Stdout;
unittest
{	
	auto ctxt = new ExecutionContext;
	
	char[][] items;
	items ~= "hello";
	items ~= "world";
	
	char[][char[]] assoc;
	assoc["one"] = "sdgh";
	assoc["two"] = "asfdg";
	
	ctxt.addVar("items", items);
	ctxt.addVar("assoc", assoc);
	
	auto v = ctxt.getVar("items");
	
	assert(v.arrayBinding.length == 2);
	assert(v.arrayBinding[0].string_ == "hello");
	assert(v.arrayBinding[1].string_ == "world");
	
	char[][] res;
	foreach(x; v.arrayBinding)
	{
		res ~= x.string_;
	}
	assert(res[0] == "hello");
	assert(res[1] == "world");
	
	v = ctxt.getVar("assoc");
	assert(v.objBinding["one"].string_ == "sdgh");
	assert(v.objBinding["two"].string_ == "asfdg");
	
	Stdout.formatln("Var.sizeof = {}", Var.sizeof);
}
}