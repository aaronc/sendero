module sendero.data.Validation;

import sendero.util.Reflection;

struct ValidationOption
{
	union
	{
		uint uint_;
		long long_;
	}
	char[] msg;
}

alias ValidationOption[char[]] Validation;

template ValInit_()
{
	const char[] ValInit_ = "auto n = get(x);"
		"if(!n) return;"
		"ValidationOption opt;"
		"opt.msg = msg;";
}

interface IValidator
{
	void setRequired(void* x, char[] msg);
	
	void setMinLen(void* x, uint len, char[] msg);
	
	void setMaxLen(void* x, uint len, char[] msg);
	
	void setMinVal(void* x, long val, char[] msg);
	
	void setMaxVal(void* x, long val, char[] msg);
}

private class ValidationVisitor : IValidator
{
	private char[][void*] ptrMap;
	private Validation[char[]] rules;
	
	this(char[][void*] ptrMap)
	{
		this.ptrMap = ptrMap;
	}
	
	private char[] get(void* x)
	{
		auto pName = (x in ptrMap);
		if(!pName) {
			return null;
		}
		return *pName;
	}
	
	void setRequired(void* x, char[] msg)
	{
		mixin(ValInit_!());
		rules[n]["required"] = opt;
	}
	
	void setMinLen(void* x, uint len, char[] msg)
	{
		mixin(ValInit_!());
		opt.uint_ = len;
		rules[n]["minLen"] = opt;
	}
	
	void setMaxLen(void* x, uint len, char[] msg)
	{
		mixin(ValInit_!());
		opt.uint_ = len;
		rules[n]["maxLen"] = opt;
	}
	
	void setMinVal(void* x, long val, char[] msg)
	{
		mixin(ValInit_!());
		opt.long_ = val;
		rules[n]["minVal"] = opt;
	}
	
	void setMaxVal(void* x, long val, char[] msg)
	{
		mixin(ValInit_!());
		opt.long_ = val;
		rules[n]["maxVal"] = opt;
	}
}

class ValidationOptionsFor(T)
{
	static void init()
	{
		auto t = new T;
		
		void* start = cast(void*)t;
		char[][void*] ptrMap;
		
		foreach(f; ReflectionOf!(T).fields)
		{
			ptrMap[start + f.offset] = f.name;
		}
		
		auto visitor = new ValidationVisitor(ptrMap);
		
		T.defineValidation(t, visitor);
		this.rules_ = visitor.rules;
		initialized_ = true;
	}
	static Validation[char[]] rules_;
	static bool initialized_; 
	static Validation[char[]] rules()
	{
		if(!initialized_) init;
		return rules_;
	}
	
}