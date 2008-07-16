#line 1 "sendero/view/expression/Compile.rl"
module sendero.view.expression.Compile;

import sendero_base.Core;
import sendero.vm.Expression2;

import sendero_base.util.collection.Stack;
import Integer = tango.text.convert.Integer;
import Float = tango.text.convert.Float;

debug import tango.io.Stdout;

void error(char[] msg)
{
	throw new Exception(msg);
}

#line 236 "sendero/view/expression/Compile.rl"



#line 21 "sendero/view/expression/Compile.d"
static const byte[] _sendero_view_compile_actions = [
	0, 1, 0, 1, 1, 1, 4, 1, 
	5, 1, 6, 1, 7, 1, 8, 1, 
	9, 1, 10, 1, 11, 1, 12, 1, 
	13, 1, 15, 1, 16, 1, 17, 1, 
	20, 1, 22, 1, 23, 1, 24, 1, 
	25, 1, 26, 2, 2, 19, 2, 3, 
	21, 2, 14, 18
];

static const byte[] _sendero_view_compile_key_offsets = [
	0, 0, 0, 0, 0, 14, 16, 33, 
	34, 35, 38, 39, 66, 68, 69, 70, 
	72, 75, 90, 91, 92, 94, 101, 102, 
	104, 105, 106, 108, 109, 110, 111, 111
];

static const char[] _sendero_view_compile_trans_keys = [
	32u, 34u, 39u, 40u, 47u, 96u, 9u, 13u, 
	48u, 57u, 65u, 90u, 95u, 122u, 34u, 92u, 
	32u, 33u, 37u, 38u, 41u, 42u, 43u, 44u, 
	45u, 47u, 60u, 61u, 62u, 93u, 124u, 9u, 
	13u, 61u, 38u, 40u, 46u, 91u, 42u, 32u, 
	33u, 34u, 37u, 38u, 39u, 40u, 41u, 42u, 
	43u, 44u, 45u, 47u, 60u, 61u, 62u, 93u, 
	96u, 124u, 9u, 13u, 48u, 57u, 65u, 90u, 
	95u, 122u, 39u, 92u, 42u, 42u, 42u, 47u, 
	46u, 48u, 57u, 32u, 34u, 39u, 40u, 47u, 
	61u, 96u, 9u, 13u, 48u, 57u, 65u, 90u, 
	95u, 122u, 42u, 42u, 42u, 47u, 95u, 48u, 
	57u, 65u, 90u, 97u, 122u, 96u, 61u, 62u, 
	124u, 42u, 42u, 47u, 36u, 36u, 123u, 0
];

static const byte[] _sendero_view_compile_single_lengths = [
	0, 0, 0, 0, 6, 2, 15, 1, 
	1, 3, 1, 19, 2, 1, 1, 2, 
	1, 7, 1, 1, 2, 1, 1, 0, 
	1, 1, 2, 1, 1, 1, 0, 0
];

static const byte[] _sendero_view_compile_range_lengths = [
	0, 0, 0, 0, 4, 0, 1, 0, 
	0, 0, 0, 4, 0, 0, 0, 0, 
	1, 4, 0, 0, 0, 3, 0, 1, 
	0, 0, 0, 0, 0, 0, 0, 0
];

static const ubyte[] _sendero_view_compile_index_offsets = [
	0, 0, 1, 2, 3, 14, 17, 34, 
	36, 38, 42, 44, 68, 71, 73, 75, 
	78, 81, 93, 95, 97, 100, 105, 107, 
	109, 111, 113, 116, 118, 120, 122, 123
];

static const byte[] _sendero_view_compile_indicies = [
	0, 1, 2, 3, 4, 5, 6, 7, 
	10, 3, 8, 9, 9, 2, 12, 13, 
	11, 14, 15, 16, 17, 18, 19, 20, 
	21, 22, 23, 24, 25, 3, 26, 27, 
	14, 2, 3, 2, 3, 2, 29, 30, 
	31, 28, 33, 32, 34, 15, 4, 16, 
	17, 5, 6, 18, 19, 20, 21, 22, 
	35, 24, 25, 3, 26, 10, 27, 34, 
	8, 9, 9, 2, 12, 37, 36, 38, 
	32, 39, 38, 39, 40, 38, 42, 42, 
	41, 3, 4, 5, 6, 7, 3, 10, 
	3, 8, 9, 9, 2, 43, 2, 44, 
	43, 44, 45, 43, 47, 47, 47, 47, 
	46, 12, 48, 3, 2, 3, 2, 49, 
	33, 49, 50, 33, 52, 51, 54, 53, 
	55, 53, 53, 2, 0
];

static const byte[] _sendero_view_compile_trans_targs = [
	31, 3, 0, 4, 5, 12, 4, 18, 
	16, 21, 22, 5, 6, 5, 6, 7, 
	4, 8, 9, 4, 4, 4, 4, 10, 
	17, 23, 9, 24, 6, 4, 4, 4, 
	11, 25, 11, 13, 12, 12, 14, 15, 
	11, 6, 16, 19, 20, 4, 9, 21, 
	22, 26, 6, 28, 29, 28, 29, 30
];

static const byte[] _sendero_view_compile_trans_actions = [
	41, 29, 0, 0, 3, 3, 13, 0, 
	1, 1, 3, 0, 5, 33, 0, 0, 
	25, 0, 15, 23, 19, 17, 21, 0, 
	0, 0, 0, 0, 31, 11, 7, 9, 
	49, 0, 0, 0, 0, 35, 0, 0, 
	27, 46, 0, 0, 0, 27, 43, 0, 
	0, 0, 27, 39, 39, 0, 0, 37
];

static const int sendero_view_compile_start = 1;
static const int sendero_view_compile_first_final = 31;
static const int sendero_view_compile_error = 0;

static const int sendero_view_compile_en_Expression = 2;
static const int sendero_view_compile_en_Expression_expression_main = 4;
static const int sendero_view_compile_en_Msg = 27;
static const int sendero_view_compile_en_main = 1;

#line 239 "sendero/view/expression/Compile.rl"

/+
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
+/

enum OpT {
	Add = Op.Add,
	Sub = Op.Sub,
	Mul = Op.Mul,
	Div = Op.Div,
	Mod = Op.Mod,
	
	//ExprParen,
	//FuncParen,
	Paren,
	Dot,
	Index
};

void doOp(Fsm fsm, OpT op)
{
	debug Stdout.formatln("Found operator: {}", op);
	if(!fsm.opSt.empty && fsm.opSt.top <= precedence.length) {
		if(precedence[fsm.opSt.top] > precedence[op]) {
			debug Stdout.formatln("Pushing to stack {}", op);
			fsm.opSt.push(op);
		}
		else {
			debug Stdout.formatln("Pushing to instructions {}", fsm.opSt.top);
			fsm.expr ~= Op(fsm.opSt.top);
			fsm.opSt.pop;
			debug Stdout.formatln("Pushing to stack {}", op);
			fsm.opSt.push(op);
		} 
	}
	else {
		debug Stdout.formatln("Pushing to stack {}", op);
		fsm.opSt.push(op);
	}
}

enum ParserT { Expr, Msg };

class Fsm
{
	this()
	{
		opStack = new Stack!(OpT);
	}

	int cs = 0;
	int* stack;
	int top;
	char* tokenStart;
	
	Expr expr;
	Stack!(OpT) opStack;
	alias opStack opSt;	
	
	ParserT type = ParserT.Expr;
}


struct Parser
{
	size_t parsed;
	
	Fsm parse_(char[] src, ParserT type)
	{
		auto fsm = new Fsm;
		fsm.type = type;
	
		char* p = src.ptr;
		char* pe = p + src.length + 1;
		char* eof = pe;
		
#line 211 "sendero/view/expression/Compile.d"
	{
	 fsm.cs = sendero_view_compile_start;
	}
#line 326 "sendero/view/expression/Compile.rl"
		
#line 215 "sendero/view/expression/Compile.d"
	{
	int _klen;
	uint _trans;
	byte* _acts;
	uint _nacts;
	char* _keys;

	if ( p == pe )
		goto _test_eof;
	if (  fsm.cs == 0 )
		goto _out;
_resume:
	_keys = &_sendero_view_compile_trans_keys[_sendero_view_compile_key_offsets[ fsm.cs]];
	_trans = _sendero_view_compile_index_offsets[ fsm.cs];

	_klen = _sendero_view_compile_single_lengths[ fsm.cs];
	if ( _klen > 0 ) {
		char* _lower = _keys;
		char* _mid;
		char* _upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( (*p) < *_mid )
				_upper = _mid - 1;
			else if ( (*p) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _sendero_view_compile_range_lengths[ fsm.cs];
	if ( _klen > 0 ) {
		char* _lower = _keys;
		char* _mid;
		char* _upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( (*p) < _mid[0] )
				_upper = _mid - 2;
			else if ( (*p) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += ((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _sendero_view_compile_indicies[_trans];
	 fsm.cs = _sendero_view_compile_trans_targs[_trans];

	if ( _sendero_view_compile_trans_actions[_trans] == 0 )
		goto _again;

	_acts = &_sendero_view_compile_actions[_sendero_view_compile_trans_actions[_trans]];
	_nacts = cast(uint) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
#line 24 "sendero/view/expression/Compile.rl"
	{fsm.tokenStart = p;}
	break;
	case 1:
#line 25 "sendero/view/expression/Compile.rl"
	{fsm.tokenStart = p + 1;}
	break;
	case 2:
#line 27 "sendero/view/expression/Compile.rl"
	{
	Op op;
	op.key = fsm.tokenStart[0 .. p - fsm.tokenStart];
	
	if(fsm.opSt.empty || fsm.opSt.top != OpT.Dot) {
		op.op = Op.Root;
	}
	else {
		op.op = Op.Key;
	}
	fsm.expr ~= op;
	
	fsm.opSt.pop;
	
	debug Stdout.formatln("Found identifier: {}", op.key);
}
	break;
	case 3:
#line 44 "sendero/view/expression/Compile.rl"
	{
	auto token = fsm.tokenStart[0 .. p - fsm.tokenStart];
	Op op;
	op.op = Op.Val;
	op.val.type = VarT.Number;
	op.val.number_ = Float.parse(token);
	fsm.expr.instructions ~= op;
	Stdout.formatln("Found number: {}", token);
}
	break;
	case 4:
#line 54 "sendero/view/expression/Compile.rl"
	{
	Stdout.formatln("Found string: {}", fsm.tokenStart[0 .. p - fsm.tokenStart]);
}
	break;
	case 5:
#line 59 "sendero/view/expression/Compile.rl"
	{
	fsm.opSt.push(OpT.Dot);
	debug Stdout("Found dot step").newline;
}
	break;
	case 6:
#line 63 "sendero/view/expression/Compile.rl"
	{ Stdout("Found index step").newline; }
	break;
	case 7:
#line 64 "sendero/view/expression/Compile.rl"
	{
	fsm.opSt.push(OpT.Paren);
	Stdout("Found function call").newline;
}
	break;
	case 8:
#line 69 "sendero/view/expression/Compile.rl"
	{
	fsm.opSt.push(OpT.Paren);
}
	break;
	case 9:
#line 72 "sendero/view/expression/Compile.rl"
	{
	while(!fsm.opSt.empty && fsm.opSt.top != OpT.Paren) {
		fsm.expr ~= Op(fsm.opSt.top);
		fsm.opSt.pop;
	}
	//fgoto end_call;
}
	break;
	case 10:
#line 80 "sendero/view/expression/Compile.rl"
	{
	while(!fsm.opSt.empty && fsm.opSt.top != OpT.Paren) {
		fsm.expr ~= Op(fsm.opSt.top);
		fsm.opSt.pop;
	}
}
	break;
	case 11:
#line 87 "sendero/view/expression/Compile.rl"
	{	doOp(fsm, OpT.Add); }
	break;
	case 12:
#line 88 "sendero/view/expression/Compile.rl"
	{	doOp(fsm, OpT.Sub); }
	break;
	case 13:
#line 90 "sendero/view/expression/Compile.rl"
	{	doOp(fsm, OpT.Mul); }
	break;
	case 14:
#line 91 "sendero/view/expression/Compile.rl"
	{	doOp(fsm, OpT.Div); }
	break;
	case 15:
#line 92 "sendero/view/expression/Compile.rl"
	{	doOp(fsm, OpT.Mod); }
	break;
	case 16:
#line 94 "sendero/view/expression/Compile.rl"
	{ debug Stdout("Found comment.").newline; }
	break;
	case 17:
#line 99 "sendero/view/expression/Compile.rl"
	{p--; { fsm.cs = 4; if (true) goto _again;}}
	break;
	case 18:
#line 119 "sendero/view/expression/Compile.rl"
	{ p--; }
	break;
	case 19:
#line 152 "sendero/view/expression/Compile.rl"
	{p--;}
	break;
	case 20:
#line 162 "sendero/view/expression/Compile.rl"
	{p--;}
	break;
	case 21:
#line 167 "sendero/view/expression/Compile.rl"
	{p--;}
	break;
	case 22:
#line 172 "sendero/view/expression/Compile.rl"
	{ ++p; }
	break;
	case 23:
#line 179 "sendero/view/expression/Compile.rl"
	{ ++p; }
	break;
	case 24:
#line 203 "sendero/view/expression/Compile.rl"
	{ debug Stdout.formatln("Found embedded expr"); }
	break;
	case 25:
#line 212 "sendero/view/expression/Compile.rl"
	{ debug Stdout.formatln("Starting to parse msg: `{}`", src);}
	break;
	case 26:
#line 220 "sendero/view/expression/Compile.rl"
	{
	p--;
	switch(fsm.type)
	{
	case ParserT.Msg:
		{ fsm.cs = 27; if (true) goto _again;}
		break;
	default:
		debug assert(false);
	case ParserT.Expr:
		{ fsm.cs = 2; if (true) goto _again;}
		break;
	}
}
	break;
#line 426 "sendero/view/expression/Compile.d"
		default: break;
		}
	}

_again:
	if (  fsm.cs == 0 )
		goto _out;
	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	_out: {}
	}
#line 327 "sendero/view/expression/Compile.rl"
		
		parsed = p - src.ptr;
		
		while(!fsm.opSt.empty) {
			auto op = fsm.opSt.top;
			fsm.opSt.pop;
			if(op >= precedence.length)
				throw new Exception("Ivalid operator on stack");
			debug Stdout.formatln("Pushing to instructions {}", op);
			fsm.expr ~= Op(op);
		}
		
		return fsm;
	}
	
	Expr parse(char[] src)
	{
		auto fsm = parse_(src , ParserT.Expr);
		return fsm.expr;
	}
	
	void parseMsg(char[] src)
	{
		auto fsm = parse_(src , ParserT.Msg);
	}
}

debug(SenderoUnittest)
{

import sendero.vm.Object;

void test(char[] src, real expected)
{
	Parser p;
	auto expr = p.parse(src);
	auto ctxt = new Obj;
	auto res = expr.exec(ctxt);
	assert(res.type == VarT.Number && res.number_ - expected < 1e-6, src ~ " " ~ Float.toString(res.number_));
	Stdout.newline;
}

void testMsg(char[] src)
{
	Parser p;
	p.parseMsg(src);
	Stdout.newline;
}

unittest
{
	Parser p;

	p.parse("x + y");
	
	Stdout.newline;
	
	p.parse("test.one[/* a comment */ test2] + test3(param1) /*another comment*/ - test4[step](param2)[5]['a str'] ");
	
	Stdout.newline;
	
	p.parse("`test1` + \"test \\\"2\" + 'test3'");
	
	Stdout.newline;
	
	bool caught = false;
	try
	{
		p.parse(" test)");
	}
	catch(Exception ex)
	{
		caught = true;
	}
//	assert(caught);

	p.parse("test; STRING");

	assert(p.parsed == 4);

	test("4 + 5", 9);
	test("8/2", 4);
	test("1/2 + 2", 2.5);
	test("1/4 * 3 - 8 / 2 * 7", 21);
	
	
	testMsg(" A ${'message'}.");
}

}

/+

+ -
* /

5 + 7 * 3 / 7 + 1

lhs mhs rhs
if(lhs) {
	if(lhs.op.precedence < cur.precendence) {
		*pRhs = curAtom;
		lhs = new BinaryExpression(cur)(lhs, null);
		pRhs = &lhs.rhs;
	}
	else {
		if(pRhs.op.precendence < cur.precedence) {
			*pRhs = new BinaryExpression(curAtom, null);
		}
		else {
			pRhs = &lhs.rhs.rhs;
		}
	}
}
else {
	lhs = new BinaryExpression(curAtom, null);
	pRhs = &lhs.rhs;
}


+/