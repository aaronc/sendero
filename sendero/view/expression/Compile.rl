module sendero.view.expression.Compile;

import sendero_base.Core;
import sendero.vm.Expression;

import sendero_base.util.collection.Stack;
import Integer = tango.text.convert.Integer;
import Float = tango.text.convert.Float;

debug import tango.io.Stdout;

void error(char[] msg)
{
	throw new Exception(msg);
}

%%{
machine sendero_view_compile;

access fsm.;

action do_start_token {fsm.tokenStart = fpc;}

action do_end_id {
	auto token = fsm.tokenStart[0 .. fpc - fsm.tokenStart];
	
	debug Stdout.formatln("Found identifier: {}", token);
	
	Var var;
	var.type = VarT.String;
	var.string_ = token;
	auto step = new Literal(var);
	
	switch(fsm.cur.state)
	{
	case State.Access:
		fsm.cur.acc.accessSteps ~= step;
		break;
	case State.None:
		fsm.cur.state = State.Access;
		fsm.cur.acc = new VarAccess;
		fsm.cur.acc.accessSteps ~= step;
		break;
	default:
		error(`Unexpected identifier "` ~ token ~ `"`);
		break;
	}		
}

action do_end_number { Stdout.formatln("Found number: {}", fsm.tokenStart[0 .. fpc - fsm.tokenStart]); }

action do_dot_step {
 	if(fsm.cur.state != State.Access)
 		error(`Unexpected token "."`);
	debug Stdout("Found dot step").newline;
}
action do_index_step { Stdout("Found index step").newline; }
action do_function_call { fsm.parenExpr = Fsm.ParenExpr.Func; Stdout("Found function call").newline; }

action do_open_paren { fsm.parenExpr = Fsm.ParenExpr.Expr; }
action do_close_paren {
		auto paren = fsm.parenExpr;
		fsm.parenExpr = Fsm.ParenExpr.None;
		switch(paren)
		{
		case Fsm.ParenExpr.Expr:
		case Fsm.ParenExpr.Func:
			fgoto end_call;
		default:
			error("Missing opening parentheses");
			break;
		}
}

action do_space {
	if(fsm.cur.state) {
		fsm.exprStack.push(fsm.cur);
		fsm.cur.state = State.None;
		debug Stdout("Found space").newline;
	}
}

Expression = 
start:(
	[a-zA-Z_] @do_start_token -> identifier |
	[0-9] @do_start_token -> number |
	
	"(" @do_open_paren -> start |
	
	"]" -> end_call |
	
	")" @do_close_paren |
	
	"," -> start |
	
	"+" -> start |
	"-" -> start |
	"/" -> start |
	"*" -> start |
	"%" -> start |
	
	"==" -> start |
	"!=" -> start |
	"<" -> start |
	"<=" -> start |
	"=>" -> start |
	">" -> start |
	
	space+ @do_space -> start
),

identifier: (
	[a-zA-Z_0-9] -> identifier |
	
	[^a-zA-Z_0-9] @do_end_id @{fhold;} -> end_call
),

end_call: (
	"." @do_dot_step -> start |
	
	"[" @do_index_step -> start |
	
	"(" @do_function_call -> start |
	
	[^\.[(] @{fhold;} -> start
),

number: (
	[0-9\.] -> number |
	[^0-9\.] @do_end_number @{fhold;} -> start
)

;

main := Expression;
	
	
}%%

%% write data;


struct ExprState
{
	enum { None = 0, Access, Binary };
	int state = None;
	
	union
	{
		VarAccess acc;
		BinaryExpression binary;
	}
}
alias ExprState State;

class Fsm
{
	this()
	{
		exprStack = new Stack!(ExprState);
	}

	int cs = 0;
	int* stack;
	int top;
	char* tokenStart;
	enum ParenExpr { None, Expr, Func }; 
	ParenExpr parenExpr;
	ExprState cur;
	Stack!(ExprState) exprStack;
}

void parse(char[] src)
{
	auto fsm = new Fsm;
	char* p = src.ptr;
	char* pe = p + src.length + 1;
	char* eof = pe;
	%% write init;
	%% write exec;
}

debug(SenderoUnittest)
{

unittest
{
	parse("test.one[test2]  test3(param1) test4[step](param2)[5] ");
	
	bool caught = false;
	try
	{
		parse(" test)");
	}
	catch(Exception ex)
	{
		caught = true;
	}
	assert(caught);
}

}