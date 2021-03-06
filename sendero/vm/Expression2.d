deprecated module sendero.vm.Expression2;

import sendero_base.Core;
import sendero_base.util.collection.Stack;

debug import tango.io.Stdout;

const ubyte[13] precedence = [
  0, 0, 0, 1, 1,
  2, 2, 2, 2, 3,
  3, 4, 4
];


struct Op {
	enum {
		Div,
		Mul,
		Mod,
		
		Add,
		Sub,
		
		Lt,
		LtEq,
		GtEq,
		Gt,
		
		Eq,
		NotEq,
		
		And,
		
		Or,
		
		Neg,
		Not,
		
		Root,
		Key,
		Index,
		Val,
		
		Dot,
		Param,
		Call
	}
	
	static Op opCall(int op)
	{
		Op o;
		o.op = op;
		return o;
	}
	
	debug(SenderoUnittest) {
		static Op num(real num)
		{
			Op o;
			o.op = Op.Val;
			o.val.type = VarT.Number;
			o.val.number_ = num;
			return o;
		}
		
	}
	
	int op;
	
	union
	{
		char[] key;
		size_t index;
		Var val;
	}
}


template BinOp(char[] op)
{
	const char[] BinOp =
		`auto r = stack.top; stack.pop;`
		`auto l = stack.top; stack.pop;`
		`if(l.type != VarT.Number && r.type != VarT.Number) stack.push(Var());`
		`else {`
			`Var res;`
			`res.type = VarT.Number;`
			`debug Stdout.format("Executing {} {} {}", l.number_,"` ~ op ~ `", r.number_);`
			`res.number_ = l.number_ ` ~ op ~ ` r.number_;`
			`debug Stdout.formatln(" = {}", res.number_);`
			`stack.push(res);`
		`}`;
}

template CmpOp(char[] op)
{
	const char[] CmpOp =
		`auto r = stack.top; stack.pop;`
		`auto l = stack.top; stack.pop;`
		`if(l.type != VarT.Number && r.type != VarT.Number) stack.push(Var());`
		`else {`
			`Var res;`
			`res.type = VarT.Bool;`
			`debug Stdout.format("Executing {} {} {}", l.number_,"` ~ op ~ `", r.number_);`
			`res.bool_ = l.number_ ` ~ op ~ ` r.number_;`
			`debug Stdout.formatln(" = {}", res.bool_);`
			`stack.push(res);`
		`}`;
}

void enforce(lazy bool test, lazy char[] msg)
{
	if(!test) throw new Exception(msg);
}

struct Expr
{
	
	Op[] instructions;
	
	Var exec(IObject ctxt)
	{
		scope stack = new Stack!(Var);
		
		foreach(op; instructions)
		{
		switch(op.op)
		{
		case Op.Root:
			stack.push(ctxt[op.key]);
			break;
		case Op.Key:
			debug assert(!stack.empty);
			if(stack.top.type != VarT.Object) {
				stack.pop;
				stack.push(Var()); //TODO error
			}
			else {
				auto val = stack.top.obj_[op.key];
				stack.pop;
				stack.push(val);
			}
			break;
		case Op.Dot:
			auto key = stack.top;
			stack.pop;
			auto obj = stack.top;
			stack.pop;
			switch(key.type)
			{
			case VarT.String:
				if(obj.type != VarT.Object) stack.push(Var());
				else(stack.push(obj.obj_[key.string_]));
				break;
			case VarT.Number:
				if(obj.type != VarT.Array) stack.push(Var());
				else(stack.push(obj.array_[cast(size_t)key.number_]));
				break;
			default:
				stack.push(Var()); // TODO error;
			}
			break;
		case Op.Val:
			stack.push(op.val);
			break;
		case Op.Add: mixin(BinOp!("+")); break;
		case Op.Sub: mixin(BinOp!("-")); break;
		case Op.Div: mixin(BinOp!("/")); break;
		case Op.Mul: mixin(BinOp!("*")); break;
		case Op.Mod: mixin(BinOp!("%")); break;
		case Op.Lt:  mixin(CmpOp!("<")); break;
		case Op.LtEq:  mixin(CmpOp!("<=")); break;
		case Op.GtEq:  mixin(CmpOp!(">=")); break;
		case Op.Gt:  mixin(CmpOp!(">")); break;
		default:
			assert(false);
		}
		}
		
		debug assert(!stack.empty);
		return stack.top;
	}
	
	void opCatAssign(Op op)
	{
		instructions ~= op;
	}
}

debug(SenderoUnittest)
{
	import sendero.vm.Object;
	
	unittest
	{
		auto ctxt = new Obj;
		Expr expr;
		expr ~= Op.num(5);
		expr ~= Op.num(7);
		expr ~= Op(Op.Add);
		auto res = expr.exec(ctxt);
		assert(res.type == VarT.Number && res.number_ == 12);
	}
}

/+
x.y + z[1 + 2] + func(1, 2 * 3, "x")

		Id(x)
			Id(y) 
	Dot
		Id(z)
				Val(1) Val(2) 
			Add
	Dot
Add
		Id(func)
				Val(1)
			Param
					Val(2) Val(3)
				Mul
			Param 
				Val("x")
			Param
	Call
Add 
+/