module sendero.validation.Validation;

import tango.core.Traits;
import tango.util.Convert;
import tango.group.time;
import tango.text.Regex;

public import sendero.validation.Validations;

public import sendero.util.Reflection;
public import sendero.msg.Msg;

class ValidationInfo
{	
	static ValidationInfo[char[]] registeredValidations;
	
	struct Option
	{
		AbstractValidation validator;
	}
	Option[][] options;
	FieldInfo[] fields;
}

class ValidationInspector
{
	this(void* ptr, FieldInfo[] fields, char[] className)
	{
		foreach(f; fields)
		{
			ptrMap[ptr + f.offset] = f.ordinal;
		}
		
		info = new ValidationInfo;
		
		info.options.length = fields.length;
		info.fields = fields;
		
		ValidationInfo.registeredValidations[className] = info;
	}
	private uint[void*] ptrMap;
	
	ValidationInfo info;
	
	void require(T)(inout T t)
	{
		add!(T)(t, new ExistenceValidation!(T));
	}
	
	void minLength(uint val, inout char[] t)
	{
		add!(char[])(t, new MinLengthValidation(val));
	}
	
	void maxLength(uint val, inout char[] t)
	{
		add!(char[])(t, new MaxLengthValidation(val));
	}
	
	void minValue(T)(T val, inout T t)
	{
		add!(T)(t, new MinValueValidation!(T)(val));
	}
	
	void maxValue(T)(T val, inout T t)
	{
		add!(T)(t, new MaxValueValidation!(T)(val));
	}
	
	void lengthRange(T)(uint min, uint max, inout T t, char[] errCode)
	{
		add(t, new MinLengthValidation!(T)(min));
		add(t, new MaxLengthValidation!(T)(max));
	}
	
	void format(char[] testRegex, inout char[] t)
	{
		add!(char[])(t, new FormatValidation(testRegex));
	}
	
	void add(T)(inout T t, Validation!(T) validator)
	{
		auto pi = &t in ptrMap;
		assert(pi);
		ValidationInfo.Option opt;
		opt.validator = validator;
		info.options[*pi] ~= opt;
	}
	alias add custom;
	alias add opCall;
}

scope class ValidatorInstance
{
	this(ValidationInfo info)
	{
		this.info = info;
	}
	private ValidationInfo info;
	
	MsgMap res;
	
	void visit(T)(T t, uint index)
	{
		foreach(opt; info.options[index])
		{
			auto validator = cast(Validation!(T))opt.validator;
			debug assert(validator);
			if(!validator.validate(t))
				res.add(info.fields[index].name, validator.error);
		}
	}
}

class Validator(X)
{
	this(ValidationInfo validation)
	{
		this.validation = validation;
	}
	private ValidationInfo validation;
	
	MsgMap validate(X x)
	{
		scope inst = new ValidatorInstance(validation);
		ReflectionOf!(X).visitTuple(x, inst);
		return inst.res;
	}
}

template Validate(X)
{
	static void initValidation(X x)
	{
		auto inspector = new ValidationInspector(cast(void*)x, ReflectionOf!(X).fields, X.stringof);
		x.onValidate(inspector);
		validator = new Validator!(X)(inspector.info);
	}
	
	static Validator!(X) validator;
	
	MsgMap validate()
	{
		if(!validator) initValidation(this);
		return validator.validate(this);
	}
}

version(Unittest)
{

import tango.io.Stdout;
import sendero.msg.Error;
	
class Test
{
	char[] name;
	DateTime dateOfBirth;
	uint id;
	char[] email = "persontest.com";
	
	void onValidate(V)(V v)
	{
		v.require(name);
		v.minLength(7, name);
		v.maxLength(256, name);
		v.minValue!(uint)(2, id);
		v.require(dateOfBirth);
		v.format("[A-Za-z0-9_\\-]+@([A-Za-z0-9_\\-]+\\.)+[A-Za-z]+", email);
	}
	mixin Validate!(Test);
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
//	auto val1 = Range!(long).gt(5);
//	assert(!val1(3));
//	assert(val1(7));
	
	auto x = new Test;
	x.name = "bob";
	auto res = x.validate;
	foreach(k, msgs; res)
	{
		Stdout(k)(":").newline;
		foreach(m; msgs)
			printMsgInfo(m);
	}
	printMsgInfo(new Error);
}
}