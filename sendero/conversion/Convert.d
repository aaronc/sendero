module sendero.conversion.Convert;

import tango.core.Traits;
import Integer = tango.text.convert.Integer;
import Float = tango.text.convert.Float;

import sendero.conversion.IConverter;
import sendero.conversion.ConversionErrors;

public import sendero.msg.Msg;
public import sendero.util.Reflection;

import sendero.util.Singleton;

/**
 * 
 * Embeds conversion support into a class.
 * 
 * Example:
 * ---
class Test
{
	char[] name;
	DateTime dateOfBirth;
	uint id;
	char[] email;
	
	void onConvert(C)(C c)
	{
		c.noFilter(email);
		c(dateOfBirth, ExactDateTimeConverter("MM-dd-yyyy"));
	}
	mixin Convert!(Test);
}
 * ---
 * 
 */
template Convert(X)
{
	static void initConversion(X x)
	{
		auto inspector = new ConversionInspector(cast(void*)x, ReflectionOf!(X).fields, X.stringof);
		x.onConvert(inspector);
		converter = new Converter!(X)(inspector.info);
	}
	
	static Converter!(X) converter;
	
	MsgMap convert(Param[char[]] params)
	{
		if(!converter) initConversion(this);
		return converter.convert(params, this);
	}
}

class ConversionInfo
{	
	static ConversionInfo[char[]] registeredConversions;
	
	struct Conversion
	{
		IAbstractConverter converter;
		char[] paramName;
	}
	Conversion[uint] converters;
	FieldInfo[] fields;
}

class ConversionInspector
{
	this(void* ptr, FieldInfo[] fields, char[] className)
	{
		foreach(f; fields)
		{
			ptrMap[ptr + f.offset] = f.ordinal;
		}
		
		info = new ConversionInfo;
		
		info.fields = fields;
		
		ConversionInfo.registeredConversions[className] = info;
		
		this.ptr = ptr;
		this.className = className;
	}
	private uint[void*] ptrMap;
	private void* ptr;
	private char[] className;
	
	ConversionInfo info;
	
	void add(T)(inout T t, IConverter!(T) converter, char[] paramName = null)
	{		
		auto pi = &t in ptrMap;
		assert(pi);
		if(!paramName.length) paramName = info.fields[*pi].name;
		ConversionInfo.Conversion cnv;
		cnv.converter = converter;
		cnv.paramName = paramName;
		info.converters[*pi] = cnv;
	}

	void opCall(T)(inout T t, IAbstractConverter cnv = null, char[] paramName = null)
	{
		if(cnv is null) {
			static if(isIntegerType!(T))
				cnv = IntegerConverter();
			else static if(isRealType!(T))
				cnv = FloatConverter();
			else static if(is(T == bool))
				cnv = BoolConverter();
			else throw new Exception("Cannot pass a null converter for type " ~ T.stringof ~ ".  "
				"Only numeric types and bool can be converted by default. "
				"For default string conversion use the noFilter method.");
		}
		auto cnvt = cast(IConverter!(T))cnv;
		if(cnvt is null) throw new Exception("You specified a converter for type "
			~ T.stringof ~ " in class " ~ className ~ " which does not implement the "
			"IConverter!(" ~ T.stringof ~ ") interface");
			//throw new Exception("error");
		//static if(!is(Cnv : IConverter!(T)))
		//	static assert(false, "class " ~ Cnv.stringof ~ " must implement the interface IConverter!(" ~ T.stringof ~ ") to be used as a converter for type " ~ T.stringof);
		
		add!(T)(t, cnvt, paramName);
	}
	
	void noFilter(inout char[] t, char[] paramName = null)
	{
		add!(char[])(t, NoFilter(), paramName);
	}
}

scope class ConverterInstance
{
	this(ConversionInfo info, void* ptr, Param[char[]] params)
	{
		this.info = info;
		this.params = params;
		this.ptr = ptr;
	}
	private ConversionInfo info;
	private Param[char[]] params;
	private void* ptr;
	
	MsgMap res;
	
	void visit(T)(T t_, uint index)
	{
		auto pCnv = index in info.converters;
		if(pCnv)
		{
			auto converter = cast(IConverter!(T))pCnv.converter;
			debug assert(converter);
			auto pp = pCnv.paramName in params;
			if(!pp) {
				//TODO add option to pass error when field was marked as required if validate on convert is called
				return;
			}
			
			auto err = converter.convert(*pp, t_);
			if(err) {
				res.add(info.fields[index].name, err);
				return;
			}
			T* pt = cast(T*)(ptr + info.fields[index].offset);
			*pt = t_;
		}
	}
}

class Converter(X)
{
	this(ConversionInfo conversion)
	{
		this.conversion = conversion;
	}
	private ConversionInfo conversion;
	
	MsgMap convert(Param[char[]] params, X x)
	{
		scope inst = new ConverterInstance(conversion, cast(void*) x, params);
		ReflectionOf!(X).visitTuple(x, inst);
		return inst.res;
	}
}

class NoFilter : IConverter!(char[])
{
	mixin Singleton!(NoFilter);
	
	private this() {}
	
	Error convert(Param p, inout char[] t)
	{
		if(p.type != ParamT.Value) return null;
		t = p.val;
		return null;
	}
}

class BoolConverter : IConverter!(bool)
{
	mixin Singleton!(NoFilter);
	
	private this() {}
	
	Error convert(Param p, inout bool t)
	{
		if(p.type != ParamT.Value) {
			t = false;
			return null;
		}
		if(p.val == "false") t = false;
		else t = true;
		return null;
	}
}

class IntegerConverter : IConverter!(ubyte), IConverter!(byte),
						 IConverter!(ushort), IConverter!(short),
						 IConverter!(uint), IConverter!(int),
						 IConverter!(ulong), IConverter!(long)
{
	mixin Singleton!(IntegerConverter);
	
	private this() {
		error = IntegerConversionError();
	}
	private Error error;
	
	template IntConvert(char[] Int) {
		const char[] IntConvert =
		"Error convert(Param p, inout " ~ Int ~ " t)"
		"{"
			"if(p.type != ParamT.Value) return null;"
			"t = Integer.parse(p.val);"
			"return error;"
		"}";
	}
	
	mixin(IntConvert!("ubyte"));
	mixin(IntConvert!("byte"));
	mixin(IntConvert!("ushort"));
	mixin(IntConvert!("short"));
	mixin(IntConvert!("uint"));
	mixin(IntConvert!("int"));
	mixin(IntConvert!("ulong"));
	mixin(IntConvert!("long"));
}

class FloatConverter : IConverter!(float), IConverter!(double), IConverter!(real)
{
	mixin Singleton!(FloatConverter);

	private this() {
		error = NumberConversionError();
	}
	private Error error;

	template FloatConvert(char[] Float) {
		const char[] FloatConvert =
		"Error convert(Param p, inout " ~ Float ~ " t)"
		"{"
			"if(p.type != ParamT.Value) return null;"
			"t = Float.parse(p.val);"
			"return error;"
		"}";
	}

	mixin(FloatConvert!("float"));
	mixin(FloatConvert!("double"));
	mixin(FloatConvert!("real"));
}

version(Unittest)
{
	
import sendero.conversion.DateTime;

import tango.io.Stdout;
	
class Test
{
	char[] name;
	DateTime dateOfBirth;
	uint id;
	char[] email;
	
	void onConvert(C)(C c)
	{
		c.noFilter(email);
		c(dateOfBirth, ExactDateTimeConverter("MM-dd-yyyy"));
	}
	mixin Convert!(Test);
}

void printMsgInfo(Msg m)
{
	Stdout("\t")(m.toString)(" ");
	Stdout("\t");
	foreach(id; m.idTree)
		Stdout(id)(" ");
	
	Stdout("\t");
	foreach(cls; m.clsTree)
		Stdout(cls)(" ");
	
	Stdout.newline;
}

unittest
{
	auto x = new Test;
	
	Param[char[]] params;
	addParam(params, ["email"], "test@test.org");
	addParam(params, ["dateOfBirth"], "01/01/1980");
	
	auto res = x.convert(params);
	foreach(k, msgs; res)
	{
		Stdout(k)(":").newline;
		foreach(m; msgs)
			printMsgInfo(m);
	}
	printMsgInfo(new Error);
}
}