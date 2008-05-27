module sendero.vm.Set;

import sendero_base.Core;

import tango.core.Traits;

void set(X)(inout Var var, X val)
{
	static if(is(X == bool)) {
		var.type = VarT.Bool;
		var.bool_ = val;
	}
	else static if(isIntegerType!(X) || isRealType!(X)) {
		var.type = VarT.Number;
		var.number_ = val;
	}
	else static if(is(X:char[])) {
		var.type = VarT.String;
		var.string_ = val;
	}
	else static if(is(X : IObject)) {
		var.type = VarT.Object;
		var.obj_ = val;
	}
	else static if(is(X : IArray)) {
		var.type = VarT.Array;
		var.array_ = val;
	}
	else static if(is(X : Time))
	{
		var.type = VarT.Time;
		var.time_ = val;
	}
	else {
		static assert(false, "Unable to bind variable of type " ~ X.stringof);
	}
}

debug(SenderoUnittest)
{
import sendero.vm.Object;
import sendero.vm.Array;
import tango.time.Clock;
	
unittest
{
	Var v;
	
	set(v, true);
	assert(v.type == VarT.Bool);
	assert(v.bool_ == true);
	
	set(v, 5);
	assert(v.type == VarT.Number);
	assert(v.number_ == 5);
	
	set(v, 7.3157);
	assert(v.type == VarT.Number);
	assert(v.number_ - 7.3157 < 1e-9);
	
	set(v, "Hello");
	assert(v.type == VarT.String);
	assert(v.string_ == "Hello");
	
	auto obj = (new Obj).add("x", 3);
	set(v, obj);
	assert(v.type == VarT.Object);
	assert(v.obj_["x"].type == VarT.Number && v.obj_["x"].number_ == 3);
	
	auto arr = new Array;
	arr ~= v;
	set(v, arr);
	assert(v.type == VarT.Array);
	assert(v.array_[0].type == VarT.Object);
	
	auto now = Clock.now;
	set(v, now);
	assert(v.type == VarT.Time);
	assert(v.time_ == now);
}
}