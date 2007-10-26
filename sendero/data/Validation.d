module sendero.data.Validation;

import sendero.util.Reflection;
import sendero.util.ExecutionContext;

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
	static this()
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
		this.rules = visitor.rules;
	}
	const static Validation[char[]] rules;
}

class ValidationVarBinding : IObjectBinding
{
	VariableBinding opIndex(char[] var)
	{
		if(var == "val")
		{
			return val;
		}
		else if(var == "msg")
		{
			return msg;
		}
		else return VariableBinding();
	}
	
	void setPtr(void* ptr) {}
	
	VariableBinding msg;
	VariableBinding val;
	
	int opApply (int delegate (inout char[] key, inout VariableBinding val) dg)
	{
		int res;
		
		char[] name;
		name = "msg";
	    if ((res = dg(name, msg)) != 0)
	    	return res;
	    
	    name = "val";
	    if ((res = dg(name, val)) != 0)
	    	return res;
	    
	    return res;
	}
	
	size_t length()
	{
		return 2;
	}
}

class ValidationOptionsBinding : IObjectBinding
{
	this(Validation rules)
	{
		foreach(name, rule; rules)
		{
			auto valBinding = new ValidationVarBinding;
			VariableBinding msg, val;
			msg.set(rule.msg);
			switch(name)
			{
			case "minLen", "maxLen":
				val.set(rule.uint_);
				break;
			case "minVal", "maxVal":
				val.set(rule.long_);
				break;
			default:
				val.type = VarT.Null;
				break;
			}
			valBinding.msg = msg;
			valBinding.val = val;
			
			VariableBinding res;
			res.type = VarT.Object;
			res.objBinding = valBinding;
			this.rules[name] = res;
		}
	}
	
	private VariableBinding[char[]] rules;
	
	void setPtr(void* ptr) {}
	
	int opApply (int delegate (inout char[] key, inout VariableBinding val) dg)
	{
		int res;
		
	    foreach(name, var; rules)
	    {
	        if ((res = dg(name, var)) != 0)
	            break;
	    }
	
		return res;
	}
	
	VariableBinding opIndex(char[] name)
	{
		auto pVal = (name in rules);
		if(!pVal) return VariableBinding();
		return *pVal;
	}
	
	size_t length()
	{
		return rules.length;
	}
}