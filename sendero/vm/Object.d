module sendero.vm.Object;

import sendero_base.Core;

import sendero.vm.Set;

class SenderoVMObject : IObject
{
	Var[char[]] members;
	
	Var opIndex(char[] key)
	{
		auto pVar = key in members;
		if(pVar) return *pVar;
		else return Var();
	}
	
	void opIndexAssign(Var var, char[] key)
	{
		members[key] = var;
	}
	
	int opApply(int delegate(inout char[] key, inout Var val) dg)
	{
		int res;
		foreach(char[] k, ref Var v; members)
		{
			if((res = dg(k, v)) != 0) break;
			
		}
		return res;
	}
	
	Var opCall(Var[] params, IObject ctxt)
	{
		return Var();
	}
	
	void toString(Var[] flags, IObject ctxt, void delegate(char[]) write)
	{
	}
	
	SenderoVMObject add(X)(char[] key, X x)
	{
		Var v;
		set(v, x);
		members[key] = v;
		return this;
	}	
}
alias SenderoVMObject Obj;

debug(SenderoUnittest)
{

}