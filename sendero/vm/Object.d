module sendero.vm.Object;

import sendero_base.Core;
import sendero_base.Object;

import sendero.vm.Set;

class SenderoVMObject : SenderoObject
{
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