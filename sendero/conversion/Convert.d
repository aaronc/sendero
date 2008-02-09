module sendero.conversion.Convert;

import tango.core.Traits;
import tango.util.Convert;
import tango.group.time;
import tango.text.Regex;

import sendero.conversion.IConverter;

public import sendero.util.Reflection;

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
	}
	private uint[void*] ptrMap;
	
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

	void opCall(T, Cnv)(inout T t, Cnv cnv, char[] paramName = null)
	{
		static if(!is(Cnv : IConverter!(T)))
			static assert(false, "class " ~ Cnv.stringof ~ " must implement the interface IConverter!(" ~ T.stringof ~ ") to be used as a converter for type " ~ T.stringof);
		add!(T)(t, cnv, paramName);
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
			debug Stdout("index")(index).newline;
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
	static NoFilter opCall()
	{
		if(!inst) inst = new NoFilter;
		return inst;
	}
	private static NoFilter inst;
	
	private this() {}
	
	Error convert(Param p, inout char[] t)
	{
		if(p.type != ParamT.Value) return null;
		t = p.val;
		return null;
	}
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