module sendero.vm.bind.Bind;

import sendero_base.Core;
import sendero_base.Set;

import tango.core.Traits;

void bind(T)(ref Var var, T val)
{
	static if( is( typeof( set!(T) ) ) )
		set(var, val);
	else static if(isDynamicArrayType!(T)) {
		var.type = VarT.Array;
		var.array_ = new ArrayVariableBinding!(T)(val);
	}
	else static if(is(X == class))
	{
		var.type = cast(VarT)VarT.Object;
		static assert(false, T.stringof);
		//objBinding = new ClassBinding!(X)(val);
	}
	else static assert(false, "Unable to bind variable of type " ~ T.stringof);
}


interface IDynArrayBinding
{
	IArray createInstance(void* ptr);
}

class ArrayVariableBinding(T) : IArray, IDynArrayBinding
{
	package this() { }
	package this(void* ptr)
	{
		auto pt = cast(T*)ptr;
		t = *pt;
	}
	this(T t) { this.t = t;}	
	private T t;
	
	IArray createInstance(void* ptr)
	{
		return new ArrayVariableBinding!(T)(ptr);
	}
	
	int opApply (int delegate (inout Var val) dg)
    {
	    int res;
	
	    foreach(x; t)
	    {
	        Var var;
	        bind(var, x);
	        if ((res = dg(var)) != 0)
	            break;
	    }
	
		return res;
    }
	
	Var opIndex(size_t i)
	{
		if(i > t.length) return Var();
		Var var;
		bind(var, t[i]);
		return var;
	}
	
	size_t length() { return t.length;}
	
	void opCatAssign(Var v) { }
}

