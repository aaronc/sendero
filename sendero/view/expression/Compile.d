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

#line 190 "sendero/view/expression/Compile.rl"



#line 21 "sendero/view/expression/Compile.d"
static const byte[] _sendero_view_compile_actions = [
	0, 1, 0, 1, 1, 1, 4, 1, 
	5, 1, 6, 1, 7, 1, 8, 1, 
	9, 1, 10, 1, 11, 1, 12, 1, 
	13, 1, 15, 1, 16, 1, 19, 1, 
	21, 1, 22, 2, 2, 18, 2, 3, 
	20, 2, 14, 17
];

static const byte[] _sendero_view_compile_key_offsets = [
	0, 0, 14, 16, 33, 34, 35, 38, 
	39, 66, 68, 69, 70, 72, 75, 90, 
	91, 92, 94, 101, 102, 104, 105, 106
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
	124u, 42u, 42u, 47u, 0
];

static const byte[] _sendero_view_compile_single_lengths = [
	0, 6, 2, 15, 1, 1, 3, 1, 
	19, 2, 1, 1, 2, 1, 7, 1, 
	1, 2, 1, 1, 0, 1, 1, 2
];

static const byte[] _sendero_view_compile_range_lengths = [
	0, 4, 0, 1, 0, 0, 0, 0, 
	4, 0, 0, 0, 0, 1, 4, 0, 
	0, 0, 3, 0, 1, 0, 0, 0
];

static const ubyte[] _sendero_view_compile_index_offsets = [
	0, 0, 11, 14, 31, 33, 35, 39, 
	41, 65, 68, 70, 72, 75, 78, 90, 
	92, 94, 97, 102, 104, 106, 108, 110
];

static const byte[] _sendero_view_compile_indicies = [
	0, 2, 3, 4, 5, 8, 0, 6, 
	7, 7, 1, 10, 11, 9, 12, 13, 
	14, 15, 16, 17, 18, 19, 20, 21, 
	22, 23, 0, 24, 25, 12, 1, 0, 
	1, 0, 1, 27, 28, 29, 26, 31, 
	30, 32, 13, 2, 14, 15, 3, 4, 
	16, 17, 18, 19, 20, 33, 22, 23, 
	0, 24, 8, 25, 32, 6, 7, 7, 
	1, 10, 35, 34, 36, 30, 37, 36, 
	37, 38, 36, 40, 40, 39, 0, 2, 
	3, 4, 5, 0, 8, 0, 6, 7, 
	7, 1, 41, 1, 42, 41, 42, 43, 
	41, 45, 45, 45, 45, 44, 10, 46, 
	0, 1, 0, 1, 47, 31, 47, 48, 
	31, 0
];

static const byte[] _sendero_view_compile_trans_targs = [
	1, 0, 2, 9, 1, 15, 13, 18, 
	19, 2, 3, 2, 3, 4, 1, 5, 
	6, 1, 1, 1, 1, 7, 14, 20, 
	6, 21, 3, 1, 1, 1, 8, 22, 
	8, 10, 9, 9, 11, 12, 8, 3, 
	13, 16, 17, 1, 6, 18, 19, 23, 
	3
];

static const byte[] _sendero_view_compile_trans_actions = [
	0, 0, 3, 3, 13, 0, 1, 1, 
	3, 0, 5, 31, 0, 0, 25, 0, 
	15, 23, 19, 17, 21, 0, 0, 0, 
	0, 0, 29, 11, 7, 9, 41, 0, 
	0, 0, 0, 33, 0, 0, 27, 38, 
	0, 0, 0, 27, 35, 0, 0, 0, 
	27
];

static const int sendero_view_compile_start = 1;
static const int sendero_view_compile_first_final = 24;
static const int sendero_view_compile_error = 0;

static const int sendero_view_compile_en_main = 1;

#line 193 "sendero/view/expression/Compile.rl"

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
}


struct Parser
{
	size_t parsed;
	
	Expr parse(char[] src)
	{
		auto fsm = new Fsm;
	
		char* p = src.ptr;
		char* pe = p + src.length + 1;
		char* eof = pe;
		
#line 198 "sendero/view/expression/Compile.d"
	{
	 fsm.cs = sendero_view_compile_start;
	}
#line 276 "sendero/view/expression/Compile.rl"
		
#line 202 "sendero/view/expression/Compile.d"
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
#line 115 "sendero/view/expression/Compile.rl"
	{ p--; }
	break;
	case 18:
#line 148 "sendero/view/expression/Compile.rl"
	{p--;}
	break;
	case 19:
#line 158 "sendero/view/expression/Compile.rl"
	{p--;}
	break;
	case 20:
#line 163 "sendero/view/expression/Compile.rl"
	{p--;}
	break;
	case 21:
#line 168 "sendero/view/expression/Compile.rl"
	{ ++p; }
	break;
	case 22:
#line 175 "sendero/view/expression/Compile.rl"
	{ ++p; }
	break;
#line 388 "sendero/view/expression/Compile.d"
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
#line 277 "sendero/view/expression/Compile.rl"
		
		parsed = p - src.ptr;
		
		while(!fsm.opSt.empty) {
			auto op = fsm.opSt.top;
			fsm.opSt.pop;
			if(op >= precedence.length)
				throw new Exception("Ivalid operator on stack");
			debug Stdout.formatln("Pushing to instructions {}", op);
			fsm.expr ~= Op(op);
		}
		
		return fsm.expr;
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