module sendero.validation.Validation;

import tango.core.Traits;
import tango.util.Convert;
import tango.group.time;
import tango.text.Regex;

public import sendero.util.Reflection;

struct ValidationTrait
{
	static ValidationTrait opCall(char[] p, char[] v)
	{
		ValidationTrait t;
		t.property = p;
		t.value = v;
		return t;
	}
	
	char[] property;
	char[] value;
}

interface IValidationTraitsProvider
{
	ValidationTrait[] getTraits();
}

interface IValidator(T) : IValidationTraitsProvider
{
	bool opCall(T t);
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
		
		options.length = fields.length;
		
		registeredValidations[className] = this;
	}
	private uint[void*] ptrMap;
	
	struct ValidationOption
	{
		IValidationTraitsProvider validator;
		char[] errCode;
	}
	
	ValidationOption[][] options;
	
	void require(T)(inout T t, char[] errCode)
	{
		static if(isDynamicArrayType!(T))
		{
			addValidation!(T)(t, ArrayRequired!(T).inst, errCode);
		}
		else static if(is(T == DateTime))
		{
			addValidation!(T)(t, DateTimeRequired.inst, errCode);
		}
		else static if(is(T == Time))
		{
			addValidation!(T)(t, TimeRequired.inst, errCode);
		}
		else static assert(false);
	}
	
	void minLength(T)(uint val, inout T t, char[] errCode)
	{
		static if(isDynamicArrayType!(T))
		{
			addValidation!(T)(t, new MinLength!(T)(val), errCode);
		}
		else static assert(false);
	}
	
	void maxLength(T)(uint val, inout T t, char[] errCode)
	{
		static if(isDynamicArrayType!(T))
		{
			addValidation!(T)(t, new MaxLength!(T)(val), errCode);
		}
		else static assert(false);
	}
	
	void lengthRange(T)(uint min, uint max, inout T t, char[] errCode)
	{
		static if(isDynamicArrayType!(T))
		{
			addValidation!(T)(t, new LengthRange!(T)(min, max), errCode);
		}
		else static assert(false);
	}
	
	void format(char[] t, char[] regex, char[] errCode)
	{
		addValidation!(char[])(t, new Pattern(regex), errCode);
	}
	
	void custom(T)(inout T t, IValidator!(T) validator, char[] errCode)
	{
		auto pi = &t in ptrMap;
		assert(pi);
		ValidationOption opt;
		opt.validator = validator;
		opt.errCode = errCode;
		options[*pi] ~= opt;
	}
	alias custom addValidation;
	alias custom opCall;
	
	FieldInfo[] fields;
}

class ArrayRequired(T) : IValidator!(T)
{
	static this() {inst = new ArrayRequired!(T);}
	private static ArrayRequired!(T) inst;
	bool opCall(char[] t) {return t.length > 0;}
	ValidationTrait[] getTraits()
	{
		return [ValidationTrait("required", "")];
	}
}

class TimeRequired : IValidator!(Time)
{
	static this() {inst = new TimeRequired;}
	private static TimeRequired inst;
	bool opCall(Time t) {return t.ticks != 0;}
	ValidationTrait[] getTraits()
	{
		return [ValidationTrait("required", "")];
	}
}

class DateTimeRequired : IValidator!(DateTime)
{
	static this() {inst = new DateTimeRequired;}
	private static DateTimeRequired inst;
	bool opCall(DateTime dt)
	{
		return dt.date.month != 0 && dt.date.day != 0 && dt.date.year != 0;
	}
	ValidationTrait[] getTraits()
	{
		return [ValidationTrait("required", "")];
	}
}

class MinLength(T) : IValidator!(T)
{
	this(uint len) { this.len = len; }
	private uint len;
	bool opCall(char[] t) {return t.length >= len;}
	ValidationTrait[] getTraits()
	{
		return [ValidationTrait("minLength", to!(char[])(len))];
	}
}

class MaxLength(T) : IValidator!(T)
{
	this(uint len) { this.len = len; }
	private uint len;
	bool opCall(char[] t) {return t.length <= len;}
	ValidationTrait[] getTraits()
	{
		return [ValidationTrait("maxLength", to!(char[])(len))];
	}
}

class LengthRange(T) : IValidator!(T)
{
	this(uint min, uint max) { this.min = min; this.max = max; }
	private uint min, max;
	bool opCall(char[] t) {return t.length >= min && t.length <= max;}
	ValidationTrait[] getTraits()
	{
		return [ValidationTrait("minLength", to!(char[])(min))];
		return [ValidationTrait("maxLength", to!(char[])(max))];
	}
}

class Pattern : IValidator!(char[])
{
	this(char[] pattern) { regex = Regex(pattern); }
	Regex regex;
	bool opCall(char[] t) {return regex.test(t, 0) != 0;}
	ValidationTrait[] getTraits()
	{
		return [ValidationTrait("regex", regex.pattern)];
	}
}

template Range(T)
{
	class GT : IValidator!(T)
	{
		this(T val) {this.val = val;}
		T val;
		bool opCall(T t) { return t > val; }
		ValidationTrait[] getTraits()
		{
			return [ValidationTrait("gt", to!(char[])(val))];
		}
	}
	
	IValidator!(T) gt(T val)
	{
		return new GT(val);
	}
	
	class GTE : IValidator!(T)
	{
		this(T val) {this.val = val;}
		T val;
		bool opCall(T t) { return t >= val; }
		ValidationTrait[] getTraits()
		{
			return [ValidationTrait("gte", to!(char[])(val))];
		}
	}
	
	IValidator!(T) gte(T val)
	{
		return new GTE(val);
	}

	class LT : IValidator!(T)
	{
		this(T val) {this.val = val;}
		T val;
		bool opCall(T t) { return t < val; }
		ValidationTrait[] getTraits()
		{
			return [ValidationTrait("lt", to!(char[])(val))];
		}
	}
	
	IValidator!(T) lt(T val)
	{
		return new LT(val);
	}
	
	class LTE : IValidator!(T)
	{
		this(T val) {this.val = val;}
		T val;
		bool opCall(T t) { return t <= val; }
		ValidationTrait[] getTraits()
		{
			return [ValidationTrait("lte", to!(char[])(val))];
		}
	}
	
	IValidator!(T) lte(T val)
	{
		return new LTE(val);
	}
	
	class GT_LT : IValidator!(T)
	{
		this(T min, T max) {this.min = min; this.max = max;}
		T min, max;
		bool opCall(T t) { return t > min && t < max; }
		ValidationTrait[] getTraits()
		{
			return [  ValidationTrait("gt", to!(char[])(min))
					, ValidationTrait("lt", to!(char[])(max))];
		}
	}
	
	IValidator!(T) gt_lt(T min, T max)
	{
		return new GT_LT(min, max);
	}
	
	class GTE_LT : IValidator!(T)
	{
		this(T min, T max) {this.min = min; this.max = max;}
		T min, max;
		bool opCall(T t) { return t >= min && t < max; }
		ValidationTrait[] getTraits()
		{
			return [  ValidationTrait("gte", to!(char[])(min))
					, ValidationTrait("lt", to!(char[])(max))];
		}
	}
	
	IValidator!(T) gte_lt(T min, T max)
	{
		return new GTE_LT(min, max);
	}
	
	class GT_LTE : IValidator!(T)
	{
		this(T min, T max) {this.min = min; this.max = max;}
		T min, max;
		bool opCall(T t) { return t > min && t <= max; }
		ValidationTrait[] getTraits()
		{
			return [  ValidationTrait("gt", to!(char[])(min))
					, ValidationTrait("lte", to!(char[])(max))];
		}
	}
	
	IValidator!(T) gt_lte(T min, T max)
	{
		return new GT_LTE(min, max);
	}
	
	class GTE_LTE : IValidator!(T)
	{
		this(T min, T max) {this.min = min; this.max = max;}
		T min, max;
		bool opCall(T t) { return t >= min && t <= max; }
		ValidationTrait[] getTraits()
		{
			return [  ValidationTrait("gte", to!(char[])(min))
					, ValidationTrait("lte", to!(char[])(max))];
		}
	}
	
	IValidator!(T) gte_lte(T min, T max)
	{
		return new GTE_LTE(min, max);
	}
}

/+alias Range!(int) Int;
alias Range!(uint) UInt;
alias Range!(long) Long;
alias Range!(float) Float;
alias Range!(double) Double;+/

static IValidator!(char[]) required()
{
	return ArrayRequired!(char[]).inst;
}

static IValidator!(char[]) minLength(uint len)
{
	return new MinLength!(char[])(len);
}

static IValidator!(char[]) maxLength(uint len)
{
	return new MaxLength!(char[])(len);
}

static IValidator!(char[]) lengthRange(uint min, uint max)
{
	return new LengthRange!(char[])(min, max);
}

static IValidator!(char[]) regex(char[] pattern)
{
	return new Pattern(pattern);
}

class ValidatorInstance
{
	this(ValidationInspector validation)
	{
		this.validation = validation;
	}
	private ValidationInspector validation;
	char[][] res;
	
	void visit(T)(T t, uint index)
	{
		foreach(opt; validation.options[index])
		{
			auto validator = cast(IValidator!(T))opt.validator;
			debug assert(validator);
			if(!validator(t))
				res ~= opt.errCode;
		}
	}
}

class Validator(X)
{
	this(ValidationInspector validation)
	{
		this.validation = validation;
	}
	private ValidationInspector validation;
	
	char[][] validate(X x)
	{
		auto inst = new ValidatorInstance(validation);
		ReflectionOf!(X).visitTuple(x, inst);
		return inst.res;
	}
}

template Validate(X)
{
	static void initValidation(X x)
	{
		auto inspector = new ValidationInspector(cast(void*)x, ReflectionOf!(X).fields, X.stringof);
		x.defineValidation(inspector);
		validator = new Validator!(X)(inspector);
	}
	
	static Validator!(X) validator;
	
	char[][] validate()
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
		v(name, required, "nameRequired");
		v(name, minLength(7), "nameMinLen7");
		v(name, maxLength(256), "nameMaxLen256");
		v(id, Range!(uint).gt(0), "idNotZero");
		v.require(dateOfBirth, "dateOfBirthRequired");
		v(email, regex("[A-Za-z0-9_\\-]+@([A-Za-z0-9_\\-]+\\.)+[A-Za-z]+"), "email");
	}
	mixin Validate!(Test);
}
	
unittest
{
	auto val1 = Range!(long).gt(5);
	assert(!val1(3));
	assert(val1(7));
	
	auto x = new Test;
	auto res = x.validate;
	foreach(err; res)
	{
		Stdout(err).newline;
	}
}
}