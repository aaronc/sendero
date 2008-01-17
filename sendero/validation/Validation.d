module sendero.validation.Validation;

import tango.core.Traits;
import tango.util.Convert;
import tango.group.time;
import tango.text.Regex;

import sendero.util.Reflection;

struct ValidationTrait
{
	static ValidationTrait opCall(char[] p, char[] v)
	{
		//auto t = new ValidationTrait;
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

/+interface ICallbackValidator(X)
{
	char[][] opCall(X x);
	ValidationTrait[] getTraits();
}+/

static IValidator!(char[]) required()
{
	return StringRequired.inst;
}

static IValidator!(char[]) minLength(uint len)
{
	return new MinLength(len);
}

static IValidator!(char[]) maxLength(uint len)
{
	return new MaxLength(len);
}

static IValidator!(char[]) lengthBetween(uint min, uint max)
{
	return new LengthBetween(min, max);
}

static IValidator!(char[]) regex(char[] pattern)
{
	return new Pattern(pattern);
}

/+
static IValidator!(char[]) named_pattern(char[] pattern, char[] name)
{
	return new NamedPattern(pattern, name);
}
+/

class T
{
	static IValidator!(Time) required()
	{
		return TimeRequired.inst;
	}
}

class DT
{
	static IValidator!(DateTime) required()
	{
		return DateTimeRequired.inst;
	}
}

class StringRequired : IValidator!(char[])
{
	static this() {inst = new StringRequired;}
	private static StringRequired inst;
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

class MinLength : IValidator!(char[])
{
	this(uint len) { this.len = len; }
	private uint len;
	bool opCall(char[] t) {return t.length >= len;}
	ValidationTrait[] getTraits()
	{
		return [ValidationTrait("minLength", to!(char[])(len))];
	}
}

class MaxLength : IValidator!(char[])
{
	this(uint len) { this.len = len; }
	private uint len;
	bool opCall(char[] t) {return t.length <= len;}
	ValidationTrait[] getTraits()
	{
		return [ValidationTrait("maxLength", to!(char[])(len))];
	}
}

class LengthBetween : IValidator!(char[])
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

/+
class NamedPattern : IValidator!(char[])
{
	this(char[] pattern, char[] name) { regex = Regex(pattern); this.name = name; }
	Regex regex;
	char[] name;
	bool opCall(char[] t) {return regex.test(t, 0) != 0;}
	ValidationTrait[] getTraits()
	{
		return [ValidationTrait("regex", name)];
	}
}
+/

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

alias Range!(int) Int;
alias Range!(uint) UInt;
alias Range!(long) Long;
alias Range!(float) Float;
alias Range!(double) Double;

class Validation
{
	static Validation[char[]] registeredValidations;
	
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
	void validate(T)(inout T t, IValidator!(T) v, char[] errCode)
	{
		auto pi = &t in ptrMap;
		assert(pi);
		ValidationOption opt;
		opt.validator = v;
		opt.errCode = errCode;
		options[*pi] ~= opt;
	}
	alias validate opCall;
	
	FieldInfo[] fields;
	
/+	void*[] callbacks;
	
	void callback(X)(ICallbackValidator!(X) v)
	{
		callbacks ~= cast(void*)v;
	}+/
}

class Validator(X)
{
/+	void validate(T)(inout T t, IValidator!(T) v, char[] errCode)
	{
		
	}
	alias add opCall;
	
	void callback(X)(ICallbackValidator!(X) v)
	{
		
	}+/
	
	this(Validation validation)
	{
		this.validation = validation;
	}
	private Validation validation;
	
	char[][] validate(X x)
	{
		auto inst = new ValidatorInstance(validation);
		ReflectionOf!(X).visitTuple(x, inst);
		return inst.res;
	}
	
	class ValidatorInstance
	{
		this(Validation validation)
		{
			this.validation = validation;
		}
		private Validation validation;
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
}

template Validate(X)
{
	static void initValidation(X x)
	{
		auto inspector = new Validation(cast(void*)x, ReflectionOf!(X).fields, X.stringof);
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
	
class X
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
		v(id, UInt.gt(0), "idNotZero");
		v(dateOfBirth, DT.required, "dateOfBirthRequired");
		v(email, regex("[A-Za-z0-9_\\-]+@([A-Za-z0-9_\\-]+\\.)+[A-Za-z]+"), "email");
	}
	mixin Validate!(X);
}
	
unittest
{
	auto val1 = Range!(long).gt(5);
	assert(!val1(3));
	assert(val1(7));
	
	auto x = new X;
	auto res = x.validate;
	foreach(err; res)
	{
		Stdout(err).newline;
	}
}
}