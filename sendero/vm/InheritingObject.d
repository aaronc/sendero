module sendero.vm.InheritingObject;

import sendero_base.Core;
import sendero_base.Set;

import tango.util.container.HashMap;
import tango.util.container.Container;
import sendero_base.util.Hash;

class SenderoInheritingObject : IObject
{
	this(IObject parent = null)
	{
		this.parent = parent;
	}
	
	IObject parent;
	
	//Var[char[]] members;
	HashMap!(char[], Var, modHash, Container.reap, Heap) members;
	
	Var opIndex(char[] key)
	{
		auto pVar = key in members;
		if(pVar) return *pVar;
		else if(parent) return parent[key];
		else return Var();
	}
	
	void opIndexAssign(Var var, char[] key)
	{
		auto pVar = key in members;
		if(pVar) {
			*pVar = var;
		}
		else if(parent && parent[key].type != VarT.Null) {
			parent[key] = var;
		}
		else members[key] = var;
	}
	
	int opApply(int delegate(inout char[] key, inout Var val) dg)
	{
		int res;
		foreach(char[] k, ref Var v; members)
		{
			if((res = dg(k, v)) != 0) break;
			
		}
		
		if(parent) {
			foreach(char[] k, ref Var v; parent)
			{
				if(!(k in members))
					if((res = dg(k, v)) != 0) break;
				
			}
		}
		
		return res;
	}
	
	Var opCall(Var[] params, IExecContext ctxt)
	{
		return Var();
	}
	
	void toString(IExecContext ctxt, void delegate(char[]) utf8Writer, char[] flags = null)
	{
	}
	
	SenderoInheritingObject add(X)(char[] key, X x)
	{
		Var v;
		set(v, x);
		members[key] = v;
		return this;
	}	
}
alias SenderoInheritingObject ExecutionContext;

debug(SenderoUnittest)
{

void testInheritance()
{
	auto obj1 = new SenderoInheritingObject;
	auto obj2 = new SenderoInheritingObject(obj1);
	auto obj3 = new SenderoInheritingObject(obj2);
	
	obj1.add("x", 5).add("y", 7).add("name", "john");
	obj2.add("x", 3);
	obj3.add("name", "max");
	
	Var v;
	
	v = obj1["x"];
	assert(v.type == VarT.Number && v.number_ == 5);
	
	v = obj2["x"];
	assert(v.type == VarT.Number && v.number_ == 3);
	
	v = obj2["y"];
	assert(v.type == VarT.Number && v.number_ == 7);
	
	v.number_ = 8;
	obj2["y"] = v;
	
	v = obj2["y"];
	assert(v.type == VarT.Number && v.number_ == 8);
	
	v = obj1["y"];
	assert(v.type == VarT.Number && v.number_ == 8);
	
	v.number_ = 10;
	obj2["x"] = v;
	
	v = obj3["x"];
	assert(v.type == VarT.Number && v.number_ == 10);
	
	v = obj1["x"];
	assert(v.type == VarT.Number && v.number_ == 5);
	
	v = obj3["name"];
	assert(v.type == VarT.String && v.string_ == "max");
}
	
unittest
{
	testInheritance;
}
}