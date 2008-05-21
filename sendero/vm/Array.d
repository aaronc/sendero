module sendero.vm.Array;

import sendero_base.Core;

class SenderoVMArray : IArray
{
	Var[] values;
	
	int opApply (int delegate (inout Var val) dg)
	{
		int res;
		foreach(ref Var v; values)
		{
			if((res = dg(v)) != 0) break;
		}
		return res;
	}
	
	Var opIndex(size_t i)
	{
		if(i > values.length) return Var();
		return values[i];
	}
	
	size_t length()
	{
		return values.length;
	}
	
	void opCatAssign(Var v)
	{
		values ~= v;
	}
}
alias SenderoVMArray Array;