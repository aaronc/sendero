module sendero.validation.Validation;

import tango.core.Traits;
import tango.util.Convert;
import tango.group.time;
import tango.text.Regex;

import sendero.validation.Validations;
import sendero.validation.ValidationResult;

public import sendero.util.Reflection;

class ValidationInfo
{	
	static ValidationInfo[char[]] registeredValidations;
	
	struct Option
	{
		AbstractValidation validator;
	}
	Option[][] options;
}

class ValidationInspector
{
	static ValidationInspector[char[]] registeredValidations;
	
	this(void* ptr, FieldInfo[] fields, char[] className)
	{
		this.fields = fields;
		
		foreach(f; fields)
		{
			ptrMap[ptr + f.offset] = f.ordinal;
		}
		
		info = new ValidationInfo;
		
		info.options.length = fields.length;
		
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
	
	void lengthRange(T)(uint min, uint max, inout T t, char[] errCode)
	{
		add(t, new MinLengthValidation!(T)(val));
		add(t, new MaxLengthValidation!(T)(val));
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
	
	FieldInfo[] fields;
}

class ValidatorInstance
{
	this(ValidationInfo validation)
	{
		this.validation = validation;
	}
	private ValidationInfo validation;
	
	ValidationResult res;
	
	void visit(T)(T t, uint index)
	{
		foreach(opt; validation.options[index])
		{
			auto validator = cast(Validator!(T))opt.validator;
			debug assert(validator);
			if(!validator.validate(t))
				res ~= validator.error;
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
	
	ValidationResult validate(X x)
	{
		auto inst = new ValidatorInstance(validation);
		//ReflectionOf!(X).visitTuple(x, inst);
		//return inst.res;
	}
}

template Validate(X)
{
	static void initValidation(X x)
	{
		auto inspector = new ValidationInspector(cast(void*)x, ReflectionOf!(X).fields, X.stringof);
		x.defineValidation(inspector);
		validator = new Validator!(X)(inspector.info);
	}
	
	static Validator!(X) validator;
	
	ValidationResult validate()
	{
		if(!validator) initValidation(this);
		return validator.validate(this);
	}
}

version(Unittest)
{

import tango.io.Stdout;
	
class Test
{
	char[] name;
	DateTime dateOfBirth;
	uint id;
	char[] email = "person@test.com";
	
	void defineValidation(V)(V v)
	{
		v.require(name);
		v.minLength(7, name);
		v.maxLength(256, name);
		//v.minValue(id, Range!(uint).gt(0), "idNotZero");
		v.require(dateOfBirth);
		v.format("[A-Za-z0-9_\\-]+@([A-Za-z0-9_\\-]+\\.)+[A-Za-z]+", email);
	}
	mixin Validate!(Test);
}

unittest
{
//	auto val1 = Range!(long).gt(5);
//	assert(!val1(3));
//	assert(val1(7));
	
	auto x = new Test;
	auto res = x.validate;
	foreach(err; res)
	{
		Stdout(err).newline;
	}
}
}