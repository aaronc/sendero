module sendero.view.ExecContxt;

import sendero.vm.InheritingObject;
public import sendero_base.Core;

class ExecContext : SenderoInheritingObject, IExecContext
{
	static this()
	{
		global = new ExecContext;
		global.parentCtxt = null;
		//global.addFunction("now", new Now);
		//global.addFunction("getVar", new GetVar);
		//global.addFunction("strcat", new StringCat);
	}
	static ExecContext global;
	
	Function[char[]] fns;
	ExecContext parentCtxt;
	ExecContext[] imports;

	this(char[] locale)
	{
		this.locale_ = locale;
	}
	
	this(IObject parent = null)
	{
		super(parent);
		this.parentCtxt = global;
	}
	
	this(ExecContext parent)
	{
		this.parentCtxt = parent;
	}
	
	this(IObject parentObj, ExecContext parentCtxt)
	{
		super(parentObj);
		this.parentCtxt = parentCtxt;
	}
	
	void addFunction(char[] name, Function func)
	{
		fns[name] = func;
	}
	
	Function getFunction(char[] name)
	{
		auto pFn = (name in fns);
		if(pFn) return *pFn;
	
		if(parentCtxt) {
			auto fn = parentCtxt.getFunction(name);
			if(fn) return fn;
		}
		
		foreach(i; imports)
		{
			auto fn = i.getFunction(name);
			if(fn) return fn;
		}
		
		return null;
	}
	
	template GetProp(char[] prop)
	{
		const char[] GetProp =
			`if(` ~ prop ~ `_.length) return ` ~ prop ~ `_;`
			`else if(parentCtxt !is null) return parentCtxt.` ~ prop ~ `();`
			`else return null;`;
	}
	
	char[] locale() { mixin(GetProp!("locale")); }
	void locale(char[] val) { locale_ = val; }
	private char[] locale_;
	
	char[] timezone() { mixin(GetProp!("timezone")); }
	void timezone(char[] val) { timezone_ = val; }
	private char[] timezone_;
}