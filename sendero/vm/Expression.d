module sendero.vm.Expression;

public import sendero_base.Core;

debug import tango.io.Stdout;

debug(SenderoViewDebug) debug = SenderoVMDebug;
debug(SenderoVMDebug) {
	import sendero.Debug;
	
	Logger log;
	static this()
	{
		log = Log.lookup("debug.SenderoVM");
	}
}

interface IExpression(ExecCtxt)
{
	Var opCall(ExecCtxt);
	debug(SenderoVMDebug) char[] toString();
}

class FunctionCall(ExecCtxt) : IExpression!(ExecCtxt)
{
	this(Function func, IExpression!(ExecCtxt)[] params)
	{
		this.func = func;
		this.params = params;
	}
	
	private Function func;
	private IExpression!(ExecCtxt)[] params;
	
	Var opCall(ExecCtxt ctxt)
	{
		debug(SenderoVMDebug) mixin(FailTrace!("FunctionCall!(" ~ ExecCtxt.stringof ~ ").opCall"));
		Var[] funcParams;
		
		auto n = params.length;
		funcParams.length = n;
		debug(SenderoVMDebug) log.trace(MName ~ " funcParams.length = {}", n);
			
		for(size_t i = 0; i < n; ++i)
		{
			debug(SenderoVMDebug) log.trace(MName ~ " params[{}].toString = {}", i, params[i].toString);
			funcParams[i] = params[i](ctxt);
			debug(SenderoVMDebug) log.trace(MName ~ " funcParams[{}].type = {}", i, funcParams[i].type);
		}
		
		return func(funcParams, ctxt);
	}
	
	debug(SenderoUnittest)
	{
		static class Func
		{
			Var opCall(Var[] params, IExecContext ctxt)
			{
				if(params.length) {
					return params[0];
				}
				else return Var();
			}
		}
		
		unittest
		{
			FunctionCall call;
			Var p, res;
			auto ctxt = new ExecCtxt;
			set(p, 37);
			auto func = &(new Func).opCall;
			
			call = new FunctionCall(func, []);
			res = call(ctxt);
			assert(res.type == VarT.Null);
			
			call = new FunctionCall(func, [new Literal!(ExecCtxt)(p)]);
			res = call(ctxt);
			assert(res.type == VarT.Number && res.number_ == 37);
		}
	}
	
	debug(SenderoVMDebug) char[] toString()
	{
		return typeof(this).stringof;
	}
}

class LateBindingFunctionCall(ExecCtxt) : IExpression!(ExecCtxt)
{
	this(char[] funcName, IExpression!(ExecCtxt)[] params)
	{
		this.funcName = funcName;
		this.params = params;
	}
	
	private char[] funcName;
	private IExpression!(ExecCtxt)[] params;
	
	Var opCall(ExecCtxt ctxt)
	{
		debug(SenderoVMDebug) mixin(FailTrace!("LateBindingFunctionCall!(" ~ ExecCtxt.stringof ~ ").opCall"));
		Var[] funcParams;
		
		auto n = params.length;
		funcParams.length = n;
		debug(SenderoVMDebug) log.trace(MName ~ " funcName = {}, funcParams.length = {}", funcName, n);
			
		for(size_t i = 0; i < n; ++i)
		{
			debug(SenderoVMDebug) log.trace(MName ~ " params[{}].toString = {}", i, params[i].toString);
			funcParams[i] = params[i](ctxt);
			debug(SenderoVMDebug) log.trace(MName ~ " funcParams[{}].type = {}", i, funcParams[i].type);
		}
		
		auto func = ctxt.getFunction(funcName);
		if(func is null) {
			debug(SenderoVMDebug) log.trace(MName ~ " unable to find funcName = {}", funcName);
			return Var();		
		}
		else{
			debug(SenderoVMDebug) log.trace(MName ~ " found funcName = {}", funcName);
			return func(funcParams, ctxt);
		}
	}
	
	debug(SenderoVMDebug) char[] toString()
	{
		return typeof(this).stringof;
	}
}

class Negative(ExecCtxt) : IExpression!(ExecCtxt)
{
	this(IExpression!(ExecCtxt) expr)
	{
		this.expr = expr;
	}
	
	IExpression!(ExecCtxt) expr;
	
	Var opCall(ExecCtxt ctxt)
	{
		auto var = expr(ctxt);
		if(var.type != VarT.Number)
			return Var();
		
		Var res;
		res.type = VarT.Number;
		res.number_ = - var.number_;
		return res;
	}
	
	debug(SenderoVMDebug) char[] toString()
	{
		return typeof(this).stringof;
	}
}

class BinaryOp(char[] op, ExecCtxt) : BinaryExpression!(ExecCtxt)
{
	this(IExpression!(ExecCtxt) lhs, IExpression!(ExecCtxt) rhs)
	{
		super(lhs, rhs);
	}
	
	static assert((op == "+") || (op == "-") || (op == "/") || (op == "*") || (op == "%"));
	
	Var opCall(ExecCtxt ctxt)
	{
		auto v1 = lhs(ctxt);
		auto v2 = rhs(ctxt);
		
		if(v1.type != VarT.Number && v2.type != VarT.Number)
			return Var();
		
		Var res;
		res.type = VarT.Number;
		
		mixin("res.number_ = v1.number_ " ~ op ~ " v2.number_;");
		
		return res;
		
	}
	
	debug(SenderoVMDebug) char[] toString()
	{
		return typeof(this).stringof;
	}
}

bool isEqual(char[] op)(Var v1, Var v2)
{
	switch(v1.type)
	{
	case VarT.Number:
		if(v2.type == VarT.Number) {
			mixin(`return v1.number_ ` ~ op ~ ` v2.number_ ? true : false;`);
		}
		else {
			return false;
		}
		break;
	case VarT.Bool:
		if(v2.type == VarT.Bool) {
			mixin(`return v1.bool_ ` ~ op ~ ` v2.bool_ ? true : false;`);
		}
		else {
			return false;
		}
		break;
	case VarT.Time:
		if(v2.type == VarT.Time) {
			mixin(`return cast(bool)(v1.time_ ` ~ op ~ ` v2.time_) ? true : false;`);
		}
		else {
			return false;
		}
		break;
	case VarT.String:
		if(v2.type == VarT.String) {
			mixin(`return cast(bool)(v1.string_ ` ~ op ~ ` v2.string_) ? true : false;`);
		}
		else {
			return false;
		}
	default:
		return false;
		break;
	}
}

class EqOp(char[] op, ExecCtxt) : BinaryExpression!(ExecCtxt)
{
	this(IExpression!(ExecCtxt) lhs, IExpression!(ExecCtxt) rhs)
	{
		super(lhs, rhs);
	}
	
	static assert((op == "==") || (op == "!="));
	
	Var opCall(ExecCtxt ctxt)
	{
		auto v1 = lhs(ctxt);
		auto v2 = rhs(ctxt);
		Var res;
		res.type = VarT.Bool;
		res.bool_ = isEqual!(op)(v1, v2);
		return res;
	}
	
	debug(SenderoVMDebug) char[] toString()
	{
		return typeof(this).stringof;
	}
}

class CmpOp(char[] op, ExecCtxt) : BinaryExpression!(ExecCtxt)
{
	this(IExpression!(ExecCtxt) lhs, IExpression!(ExecCtxt) rhs)
	{
		super(lhs, rhs);
	}
	
	static assert((op == "<") || (op == "<=") || (op == ">=") || (op == ">"));
	
	static bool compare(Var v1, Var v2)
	{
		switch(v1.type)
		{
		case VarT.Number:
			if(v2.type == VarT.Number) {
				mixin(`return v1.number_ ` ~ op ~ ` v2.number_ ? true : false;`);
			}
			else {
				return false;
			}
			break;
		case VarT.Time:
			if(v2.type == VarT.Time) {
				mixin(`return v1.time_ ` ~ op ~ ` v2.time_ ? true : false;`);
			}
			else {
				return false;
			}
		default:
			return false;
		}
	}
	
	Var opCall(ExecCtxt ctxt)
	{
		auto v1 = lhs(ctxt);
		auto v2 = rhs(ctxt);
		Var res;
		res.type = VarT.Bool;
		res.bool_ = compare(v1, v2);
		return res;
	}
	
	debug(SenderoVMDebug) char[] toString()
	{
		return typeof(this).stringof;
	}
}

class LogicalOp(char[] op, ExecCtxt) : BinaryExpression!(ExecCtxt)
{
	this(IExpression!(ExecCtxt) lhs, IExpression!(ExecCtxt) rhs)
	{
		super(lhs, rhs);
	}
	
	Var opCall(ExecCtxt ctxt)
	{
		static assert((op == "||") || (op == "&&"));
		
		auto b1 = varToBool(lhs(ctxt));
		auto b2 = varToBool(rhs(ctxt));
		
		Var res; res.type = VarT.Bool;
		mixin(`res.bool_ = b1 ` ~ op ~ ` b2;`);
		return res;
	}
	
	debug(SenderoVMDebug) char[] toString()
	{
		return typeof(this).stringof;
	}
}

bool varToBool(Var var)
{
	switch(var.type)
	{
	case VarT.Bool:
		return var.bool_;
	case VarT.Number:
		return var.number_ != 0 ? true : false;
	case VarT.Time:
		return var.time_.ticks != 0 ? true : false;
	case VarT.Array:
		return var.array_.length > 0 ? true : false;
	case VarT.String:
		return var.string_.length > 0 ? true : false;
	case VarT.Binary:
	case VarT.XmlNode:
	case VarT.Object:
		return true;
	case VarT.Null:
	default:
		return false;
	}
}

abstract class BinaryExpression(ExecCtxt) : IExpression!(ExecCtxt)
{
	this(IExpression!(ExecCtxt) lhs, IExpression!(ExecCtxt) rhs)
	{
		this.lhs = lhs;
		this.rhs = rhs;
	}
	
	IExpression!(ExecCtxt) lhs;
	IExpression!(ExecCtxt) rhs;
	
	debug(SenderoVMDebug) char[] toString()
	{
		return typeof(this).stringof;
	}
}

class VarAccess(ExecCtxt) : IExpression!(ExecCtxt)
{
	this()
	{
		
	}
	
	this(IExpression!(ExecCtxt)[] accessSteps)
	{
		this.accessSteps = accessSteps;
	}
	
	IExpression!(ExecCtxt)[] accessSteps;
	
	Var opCall(ExecCtxt ctxt)
	{
		//debug(SenderoVMDebug) const char[] MName = "VarAccess!(" ~ ExecCtxt.stringof ~ ").opCall";
		debug(SenderoVMDebug) mixin(FailTrace!("VarAccess!(" ~ ExecCtxt.stringof ~ ").opCall"));
		
		Var val;
		val.type = VarT.Object;
		val.obj_ = ctxt;
		foreach(step; accessSteps)
		{
			debug(SenderoVMDebug) log.trace(MName ~ " step = {}", step.toString);
			auto stepVal = step(ctxt);
			switch(stepVal.type)
			{
			case VarT.Number:
				debug(SenderoVMDebug) log.trace(MName ~ " VarT.Number step = {}", stepVal.number_);
				if(val.type == VarT.Array) {
					val = val.array_[cast(size_t)stepVal.number_];
				}
				else return Var();
				break;
			case VarT.String:
				debug(SenderoVMDebug) log.trace(MName ~ " VarT.String step = {}", stepVal.string_);
				if(val.type == VarT.Object) {
					val = val.obj_[stepVal.string_];
				}
				else return Var();
				break;
			default:
				return Var();
				break;
			}
		}
		return val;
	}
	
	debug(SenderoUnittest) unittest
	{
		auto ctxt = new Obj;
		ctxt.add("x", 5).add("obj", (new Obj).add("y", 7));
		auto a = new Array;
		Var v;
		set(v, 175);
		a ~= v;
		ctxt.add("arr", a);
		
		Var res, s1, s2_0, s2_1, s3_0, s3_1;
		VarAccess!(IObject) varAcc;
		
		set(s1, "x");
		varAcc = new VarAccess!(IObject)([new Literal!(IObject)(s1)]);
		res = varAcc(ctxt);
		assert(res.type == VarT.Number && res.number_ == 5);
		
		set(s2_0, "obj"); set(s2_1, "y");
		varAcc = new VarAccess!(IObject)([new Literal!(IObject)(s2_0), new Literal!(IObject)(s2_1)]);
		res = varAcc(ctxt);
		assert(res.type == VarT.Number && res.number_ == 7);
		
		set(s3_0, "arr"); set(s3_1, 0);
		varAcc = new VarAccess!(IObject)([new Literal!(IObject)(s3_0), new Literal!(IObject)(s3_1)]);
		res = varAcc(ctxt);
		assert(res.type == VarT.Number && res.number_ == 175);
	}
	
	debug(SenderoVMDebug) char[] toString()
	{
		return typeof(this).stringof;
	}
}

class VarPath(ExecCtxt) : IExpression!(ExecCtxt)
{
	this(char[][] path)
	{
		this.path = path;
	}
	
	char[][] path;
	
	Var opCall(ExecCtxt ctxt)
	{
		auto obj = ctxt;
		Var var;
		
		foreach(step; path)
		{
			if(!obj) return Var();
			
			var = obj[step];
			
			if(var.type != VarT.Object) obj = null;
			else obj = var.obj_;
		}
		
		return var;
	}
	
	debug(SenderoVMDebug) char[] toString()
	{
		return typeof(this).stringof;
	}
}

class Literal(ExecCtxt) : IExpression!(ExecCtxt)
{
	this(Var v)
	{
		this.literal = v;
	}
	
	Var literal;
	Var opCall(ExecCtxt ctxt)
	{
		return literal;
	}
	
	debug(SenderoVMDebug) char[] toString()
	{
		return typeof(this).stringof;
	}
}

debug(SenderoUnittest)
{
	import sendero_base.Set;
	import sendero.vm.Object;
	import sendero.vm.Array;
	
	unittest
	{
		Var v1, v2, v3, res;
		set(v1, 5);
		set(v2, 10);
		set(v3, 0);
		auto l1 = new Literal!(IObject)(v1);
		auto l2 = new Literal!(IObject)(v2);
		auto l3 = new Literal!(IObject)(v3);
		auto ctxt = new Obj;
		
		auto add = new BinaryOp!("+", IObject)(l1, l2);
		res = add(ctxt);		
		assert(res.type == VarT.Number && res.number_ == 15);
		
		auto geq = new CmpOp!(">=", IObject)(l1, l2);
		res = geq(ctxt);
		assert(res.type == VarT.Bool && res.bool_ == false);
		
		auto eq = new EqOp!("!=", IObject)(l1, l2);
		res = eq(ctxt);
		assert(res.type == VarT.Bool && res.bool_ == true);
		
		auto or = new LogicalOp!("||", IObject)(l1, l3);
		res = or(ctxt);
		assert(res.type == VarT.Bool && res.bool_ == true);
		
		auto and = new LogicalOp!("&&", IObject)(l1, l3);
		res = and(ctxt);
		assert(res.type == VarT.Bool && res.bool_ == false);
	}	
}