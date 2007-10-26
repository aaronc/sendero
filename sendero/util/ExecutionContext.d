module sendero.util.ExecutionContext;

public import sendero.json.JsonObject;

import sendero.util.Reflection;
import sendero.data.Validation;
import sendero.util.LocalText;

public import tango.core.Type;
public import tango.util.time.Date;
public import tango.util.time.DateTime;
import tango.core.Traits;
import tango.core.Variant;
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

enum VarT : ubyte {  Bool, Long, ULong, Double, String, DateTime, Array, Object, Null };

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
	
	private ExecutionContext parent;
	
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
	
	void addVar(T)(char[] name, T t)
	{
		static if(is(T == VariableBinding)) {
			vars[name] = t;
			return;
		}
		
		VariableBinding var;
		var.set(t);
		vars[name] = var;
	}
	
	void addVarAsRoot(T)(T t)
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
	
	VariableBinding getVar(char[] var)
	{
		auto pVar = (var in vars);
		if(!pVar) {
			if(parent) return parent.getVar(var);
			return VariableBinding();
		}
		return *pVar;
	}
	
	VariableBinding getVar(VarPath varPath)
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
			else if(var.type == VarT.DateTime) {
				auto v = DateTimePropertyService.global.getProperty(varPath.path[n], var);
				var = v;
			}
			else if(var.type == VarT.Array) {
				auto v = ArrayPropertyService.global.getProperty(varPath.path[n], var);
				var = v;
			}
			else return VariableBinding();
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

interface IFunctionBinding
{
	VariableBinding exec(VariableBinding[] params, ExecutionContext parentCtxt);
}

class FunctionBindingContext
{
	static this()
	{
		global = new FunctionBindingContext;
		global.parent = null;
		global.addFunction("now", new Now);
		global.addFunction("getVar", new GetVar);
	}
	static FunctionBindingContext global;
	
	IFunctionBinding[char[]] fns;
	private FunctionBindingContext parent;
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
		
		return new NullFunction;
	}
}

template isLongT( T )
{
    const bool isLongT = is( T == byte )  ||
                         is( T == short ) ||
                         is( T == int )   ||
                         is( T == long )  ||
                         is( T == ubyte )  ||
                         is( T == ushort ) ||
                         is( T == uint );
}

template isDoubleT( T )
{
    const bool isDoubleT = 	is( T == float )  ||
    					 	is( T == double );
}

struct VariableBinding
{
	VarT type = VarT.Null;
	IPropertyService propertyService = null;
	union
	{
		IArrayBinding arrayBinding;
		IObjectBinding objBinding;
		bool bool_;		
		long long_;
		ulong ulong_;
		double double_;
		char[] string_;
		DateTime DateTime_;
		JSONObject!(char) json_;
	}
	
	void set(X)(X val)
	{
		propertyService = null;
		static if(is(X == bool)) {
			type = VarT.Bool;
			bool_ = val;
		}
		else static if(isLongT!(X)) {
			type = VarT.Long;
			long_ = val;
		}
		else static if(is(X == ulong)) {
			type = VarT.ULong;
			ulong_ = val;
		}
		else static if(isDoubleT!(X)) {
			type = VarT.Double;
			double_ = val;
		}
		else static if(is(X:char[])) {
			type = VarT.String;
			string_ = val;
		}
		else static if(isDynamicArrayType!(X)) {
			type = VarT.Array;
			arrayBinding = new ArrayVariableBinding!(X)(val);
		}
		else static if(isAssocArrayType!(X)) {
			type = VarT.Object;
			objBinding = new AssocArrayVariableBinding!(X)(val);
		}
		else static if(is(X == DateTime))
		{
			type = VarT.DateTime;
			DateTime_ = val;
		}
		else static if(is(X == Date))
		{
			type = VarT.DateTime;
			DateTime_ = DateTime(val.year, val.month, val.day);
			DateTime_.addHours(val.hour);
			DateTime_.addMinutes(val.min);
			DateTime_.addSeconds(val.sec);
		}
		else static if(is(X == Time))
		{
			type = VarT.DateTime;
			DateTime_ = DateTime(val);
		}
		else static if(is(X == JSONObject!(char)))
		{
			type = VarT.Object;
			objBinding = new JSONObjectBinding(val);
		}
		else static if(is(X == class))
		{
			type = VarT.Object;
			objBinding = new ClassBinding!(X)(val);
		}
		else type = VarT.Null;
	}
}

interface IObjectBinding
{
	VariableBinding opIndex(char[] key);
	int opApply (int delegate (inout char[] key, inout VariableBinding val) dg);
	void setPtr(void* ptr);
	size_t length();
}

interface IArrayBinding
{
	void set(void* ptr);
	int opApply (int delegate (inout VariableBinding val) dg);
	VariableBinding opIndex(size_t i);
	size_t length();
}

interface IPropertyService
{
	VariableBinding getProperty(char[] name, inout VariableBinding var);
}

class ObjectPropertyService : IPropertyService
{
	static this()
	{
		global = new ObjectPropertyService;
	}
	static ObjectPropertyService global;
	
	private this() {}
	
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

class ArrayPropertyService : IPropertyService
{
	static this()
	{
		global = new ArrayPropertyService;
	}
	static ArrayPropertyService global;
	
	private this() {}
	
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


class ArrayVariableBinding(T) : IArrayBinding
{
	
	this() { }
	this(T t) { this.t = t;}	
	private T t;
	
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

class AssocArrayVariableBinding(T) : IObjectBinding
{
	static this()
	{
		static assert(is(typeof(T.init.keys[0]) == char[]));
	}
	
	this() { }
	this(T t) { this.t = t;}	
	private T t;
	
	void setPtr(void* ptr)
	{
		auto pt = cast(T*)ptr;
		t = *pt;
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
}

struct VarInfo
{
	ClassVarT type;
	IPropertyService propertyService;
	union
	{
		IObjectBinding objBinding;
		IArrayBinding arrayBinding;
	}
	size_t offset;
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
			info.assocArrayBinding = new ArrayVariableBinding!(T);
		}
		bindings[index] = info;
	}
}

enum ClassVarT : ubyte {  Bool, Byte, Short, Int, Long, UByte, UShort, UInt, ULong, Float, Double, String, DateTime, Date, Time, ClassStruct, Array, AssocArray, JSONObject, Null };

class ClassBinding(T) : IObjectBinding
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
			
				auto pValidation = (f.name in ValidationOptionsFor!(T).rules);
				if(pValidation) {
					auto propService = new ClassPropertyService;
					propService.validation = *pValidation;
					(*pInfo).propertyService = propService;
				}
				
				bindInfo[f.name] = *pInfo;
			}
		}
		initialized = true;
	}
	
	private static bool initialized; 
	private static VarInfo[char[]] bindInfo;
	private static VariableBinding[char[]] validationInfo;
	
	private T t;
	this(T t)
	{
		this.t = t;
	}
	
	void setPtr(void* ptr)
	{
		t = cast(T)ptr;
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
			var.objBinding = varInfo.objBinding;
			var.objBinding.setPtr(*cast(void**)ptr);
			break;
		case(ClassVarT.Array):
			var.type = VarT.Array;
			var.arrayBinding = varInfo.arrayBinding;
			var.arrayBinding.set(ptr);
			break;
		case(ClassVarT.AssocArray):
			var.type = VarT.Object;
			var.objBinding = varInfo.objBinding;
			var.objBinding.setPtr(ptr);
			break;
		default:
			debug assert(false, "Unhandled class bind type");
			var.type = VarT.Null; 
			return;
		}
		var.propertyService = varInfo.propertyService;
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
}

class ClassPropertyService : IPropertyService
{
	private this() {}
	
	private Validation validation;
	private VariableBinding validationProperty;
	
	VariableBinding getProperty(char[] name, inout VariableBinding var)
	{
		switch(name)
		{
		case "validation":
			if(validationProperty.type == VarT.Null) {
				if(validation.length) {
					validationProperty.type = VarT.Object;
					validationProperty.objBinding = new ValidationOptionsBinding(validation);
				}
			}
			return validationProperty;
		default:
			break;
		}
		
		return VariableBinding();
	}
}

class DateTimePropertyService : IPropertyService
{
	static this()
	{
		global = new DateTimePropertyService;
	}
	static DateTimePropertyService global;
	
	private this() {}
	
	VariableBinding getProperty(char[] name, inout VariableBinding var)
	{
		if(var.type != VarT.DateTime) return VariableBinding();
		
		auto dateTime = var.DateTime_;
		
		VariableBinding res;
		switch(name)
		{
		case "year":
			res.set(dateTime.year);
			break;
		case "month":
			res.set(dateTime.month);
			break;
		case "day":
			res.set(dateTime.day);
			break;
		case "hour":
			res.set(dateTime.hour);
			break;
		case "minute":
			res.set(dateTime.minute);
			break;
		case "second":
			res.set(dateTime.second);
			break;
		case "millisecond":
			res.set(dateTime.millisecond);
			break;
		default:
			res.type = VarT.Null;
			break;
		}
		return res;
	}
}

enum ExpressionT : ubyte { Null, Var, Value, FuncCall, TextExpr};

struct Expression
{
	ExpressionT type;
	union
	{
		VarPath var;
		VariableBinding val;
		FunctionCall func;
		Message textExpr;
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
		case ExpressionT.TextExpr:
			VariableBinding var;
			var.set(textExpr.exec(ctxt));
			return var;
		default:
			return VariableBinding();
		}
	}
}

struct FunctionCall
{
	IFunctionBinding func;
	Expression[] params;
	
	VariableBinding exec(ExecutionContext ctxt)
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
		var.set(DateTime.now);
		return var;
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

class NullFunction : IFunctionBinding
{
	VariableBinding exec(VariableBinding[] params, ExecutionContext parentCtxt)
	{
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
	
	void setPtr(void* ptr)
	{
		json = cast(JSON)ptr;
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
}