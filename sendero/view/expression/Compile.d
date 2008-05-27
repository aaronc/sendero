#line 1 "sendero/view/expression/Compile.rl"
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

#line 141 "sendero/view/expression/Compile.rl"



#line 21 "sendero/view/expression/Compile.d"
static const byte[] _sendero_view_compile_actions = [
	0, 1, 0, 1, 3, 1, 4, 1, 
	5, 1, 6, 1, 7, 1, 10, 2, 
	0, 10, 2, 1, 9, 2, 2, 11, 
	2, 6, 5, 2, 7, 10, 2, 8, 
	12, 3, 0, 2, 11, 3, 0, 8, 
	12, 3, 3, 8, 12, 3, 4, 8, 
	12, 3, 5, 8, 12, 3, 6, 1, 
	9, 3, 6, 2, 11, 3, 6, 8, 
	12, 3, 7, 1, 9, 3, 7, 2, 
	11, 3, 7, 8, 12, 3, 10, 2, 
	11, 3, 10, 8, 12, 4, 0, 10, 
	8, 12, 4, 1, 9, 2, 11, 4, 
	1, 9, 8, 12, 4, 2, 11, 8, 
	12, 4, 6, 5, 8, 12, 4, 7, 
	10, 8, 12, 5, 0, 2, 11, 8, 
	12, 5, 4, 2, 11, 8, 12, 5, 
	5, 2, 11, 8, 12, 5, 6, 1, 
	9, 2, 11, 5, 6, 1, 9, 8, 
	12, 5, 6, 2, 11, 8, 12, 5, 
	7, 1, 9, 2, 11, 5, 7, 1, 
	9, 8, 12, 5, 7, 2, 11, 8, 
	12, 5, 10, 2, 11, 8, 12, 6, 
	0, 10, 2, 11, 8, 12, 6, 1, 
	9, 2, 11, 8, 12, 6, 6, 5, 
	2, 11, 8, 12, 6, 7, 10, 2, 
	11, 8, 12, 7, 6, 1, 9, 2, 
	11, 8, 12, 7, 7, 1, 9, 2, 
	11, 8, 12
];

static const short[] _sendero_view_compile_key_offsets = [
	0, 0, 22, 26, 27, 27, 30, 47, 
	69, 76, 79, 90, 97, 112, 125, 144, 
	163, 170, 178, 197, 206, 218, 234, 248, 
	258
];

static const char[] _sendero_view_compile_trans_keys = [
	13u, 32u, 33u, 37u, 40u, 41u, 47u, 60u, 
	61u, 62u, 93u, 95u, 9u, 10u, 42u, 45u, 
	48u, 57u, 65u, 90u, 97u, 122u, 13u, 32u, 
	9u, 10u, 61u, 46u, 48u, 57u, 13u, 32u, 
	33u, 40u, 41u, 93u, 95u, 9u, 10u, 48u, 
	57u, 60u, 61u, 65u, 90u, 97u, 122u, 13u, 
	32u, 33u, 37u, 40u, 41u, 47u, 62u, 93u, 
	95u, 9u, 10u, 42u, 45u, 48u, 57u, 60u, 
	61u, 65u, 90u, 97u, 122u, 95u, 48u, 57u, 
	65u, 90u, 97u, 122u, 40u, 46u, 91u, 40u, 
	41u, 46u, 93u, 95u, 48u, 57u, 65u, 90u, 
	97u, 122u, 13u, 32u, 46u, 9u, 10u, 48u, 
	57u, 13u, 32u, 40u, 41u, 46u, 93u, 95u, 
	9u, 10u, 48u, 57u, 65u, 90u, 97u, 122u, 
	13u, 32u, 40u, 41u, 95u, 9u, 10u, 48u, 
	57u, 65u, 90u, 97u, 122u, 13u, 32u, 33u, 
	40u, 41u, 46u, 91u, 93u, 95u, 9u, 10u, 
	48u, 57u, 60u, 61u, 65u, 90u, 97u, 122u, 
	13u, 32u, 37u, 40u, 41u, 47u, 60u, 62u, 
	95u, 9u, 10u, 42u, 45u, 48u, 57u, 65u, 
	90u, 97u, 122u, 13u, 32u, 40u, 46u, 91u, 
	9u, 10u, 46u, 95u, 48u, 57u, 65u, 90u, 
	97u, 122u, 13u, 32u, 33u, 40u, 41u, 46u, 
	91u, 93u, 95u, 9u, 10u, 48u, 57u, 60u, 
	61u, 65u, 90u, 97u, 122u, 13u, 32u, 40u, 
	46u, 91u, 9u, 10u, 48u, 57u, 13u, 32u, 
	46u, 95u, 9u, 10u, 48u, 57u, 65u, 90u, 
	97u, 122u, 13u, 32u, 40u, 41u, 46u, 91u, 
	93u, 95u, 9u, 10u, 48u, 57u, 65u, 90u, 
	97u, 122u, 13u, 32u, 40u, 41u, 46u, 95u, 
	9u, 10u, 48u, 57u, 65u, 90u, 97u, 122u, 
	40u, 41u, 46u, 95u, 48u, 57u, 65u, 90u, 
	97u, 122u, 61u, 62u, 0
];

static const byte[] _sendero_view_compile_single_lengths = [
	0, 12, 2, 1, 0, 1, 7, 10, 
	1, 3, 5, 3, 7, 5, 9, 9, 
	5, 2, 9, 5, 4, 8, 6, 4, 
	0
];

static const byte[] _sendero_view_compile_range_lengths = [
	0, 5, 1, 0, 0, 1, 5, 6, 
	3, 0, 3, 2, 4, 4, 5, 5, 
	1, 3, 5, 2, 4, 4, 4, 3, 
	1
];

static const ubyte[] _sendero_view_compile_index_offsets = [
	0, 0, 18, 22, 24, 25, 28, 41, 
	58, 63, 67, 76, 82, 94, 104, 119, 
	134, 141, 147, 162, 170, 179, 192, 203, 
	211
];

static const byte[] _sendero_view_compile_indicies = [
	0, 0, 2, 3, 4, 5, 3, 7, 
	8, 3, 10, 9, 0, 3, 6, 9, 
	9, 1, 0, 0, 0, 11, 3, 1, 
	1, 13, 13, 12, 0, 0, 14, 15, 
	16, 19, 18, 0, 17, 14, 18, 18, 
	11, 0, 0, 2, 3, 4, 5, 3, 
	3, 10, 9, 0, 3, 6, 7, 9, 
	9, 1, 21, 21, 21, 21, 20, 23, 
	24, 25, 22, 26, 27, 13, 30, 29, 
	28, 29, 29, 12, 12, 12, 32, 12, 
	32, 31, 12, 12, 33, 34, 32, 37, 
	36, 12, 35, 36, 36, 31, 39, 39, 
	40, 41, 18, 39, 42, 18, 18, 38, 
	43, 43, 44, 45, 46, 24, 25, 49, 
	48, 43, 47, 44, 48, 48, 22, 39, 
	39, 50, 51, 52, 50, 50, 50, 9, 
	39, 50, 53, 9, 9, 20, 43, 43, 
	55, 56, 57, 43, 54, 59, 61, 60, 
	61, 61, 58, 43, 43, 62, 63, 64, 
	56, 57, 67, 66, 43, 65, 62, 66, 
	66, 54, 69, 69, 70, 71, 73, 69, 
	72, 68, 58, 58, 75, 77, 58, 76, 
	77, 77, 74, 69, 69, 78, 79, 71, 
	73, 82, 81, 69, 80, 81, 81, 68, 
	58, 58, 83, 84, 75, 36, 58, 85, 
	36, 36, 74, 86, 87, 59, 29, 88, 
	29, 29, 58, 3, 1, 0
];

static const byte[] _sendero_view_compile_trans_targs = [
	2, 0, 3, 1, 1, 4, 5, 7, 
	24, 8, 9, 1, 6, 11, 7, 1, 
	1, 10, 15, 14, 9, 8, 1, 1, 
	1, 1, 6, 6, 11, 13, 18, 6, 
	12, 6, 6, 12, 13, 18, 14, 16, 
	14, 14, 23, 6, 7, 1, 1, 10, 
	15, 14, 14, 14, 9, 17, 1, 1, 
	1, 1, 18, 19, 20, 13, 7, 1, 
	1, 10, 15, 14, 6, 6, 6, 12, 
	12, 6, 18, 21, 22, 13, 6, 6, 
	12, 13, 18, 18, 18, 22, 18, 18, 
	20
];

static const ubyte[] _sendero_view_compile_trans_actions = [
	0, 0, 0, 0, 9, 11, 1, 0, 
	0, 1, 0, 30, 21, 0, 30, 61, 
	73, 37, 37, 30, 18, 0, 13, 7, 
	3, 5, 57, 69, 1, 33, 21, 100, 
	30, 145, 163, 37, 115, 100, 95, 18, 
	139, 157, 37, 13, 13, 24, 27, 15, 
	15, 13, 18, 53, 65, 1, 81, 49, 
	41, 45, 90, 18, 0, 21, 81, 105, 
	110, 85, 85, 81, 169, 77, 127, 41, 
	81, 121, 182, 95, 30, 100, 189, 196, 
	85, 175, 169, 203, 211, 37, 133, 151, 
	1
];

static const int sendero_view_compile_start = 1;
static const int sendero_view_compile_first_final = 25;
static const int sendero_view_compile_error = 0;

static const int sendero_view_compile_en_main = 1;
static const int sendero_view_compile_en_main_Expression_end_call = 9;

#line 144 "sendero/view/expression/Compile.rl"


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
	
#line 222 "sendero/view/expression/Compile.d"
	{
	 fsm.cs = sendero_view_compile_start;
	}
#line 183 "sendero/view/expression/Compile.rl"
	
#line 226 "sendero/view/expression/Compile.d"
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
#line 22 "sendero/view/expression/Compile.rl"
	{fsm.tokenStart = p;}
	break;
	case 1:
#line 24 "sendero/view/expression/Compile.rl"
	{
	auto token = fsm.tokenStart[0 .. p - fsm.tokenStart];
	
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
	break;
	case 2:
#line 50 "sendero/view/expression/Compile.rl"
	{ Stdout.formatln("Found number: {}", fsm.tokenStart[0 .. p - fsm.tokenStart]); }
	break;
	case 3:
#line 52 "sendero/view/expression/Compile.rl"
	{
 	if(fsm.cur.state != State.Access)
 		error(`Unexpected token "."`);
	debug Stdout("Found dot step").newline;
}
	break;
	case 4:
#line 57 "sendero/view/expression/Compile.rl"
	{ Stdout("Found index step").newline; }
	break;
	case 5:
#line 58 "sendero/view/expression/Compile.rl"
	{ fsm.parenExpr = Fsm.ParenExpr.Func; Stdout("Found function call").newline; }
	break;
	case 6:
#line 60 "sendero/view/expression/Compile.rl"
	{ fsm.parenExpr = Fsm.ParenExpr.Expr; }
	break;
	case 7:
#line 61 "sendero/view/expression/Compile.rl"
	{
		auto paren = fsm.parenExpr;
		fsm.parenExpr = Fsm.ParenExpr.None;
		switch(paren)
		{
		case Fsm.ParenExpr.Expr:
		case Fsm.ParenExpr.Func:
			{ fsm.cs = 9; if (true) goto _again;}
		default:
			error("Missing opening parentheses");
			break;
		}
}
	break;
	case 8:
#line 75 "sendero/view/expression/Compile.rl"
	{
	debug Stdout("Found space").newline;
	fsm.exprStack.push(fsm.cur);
	fsm.cur.state = State.None;
}
	break;
	case 9:
#line 113 "sendero/view/expression/Compile.rl"
	{p--;}
	break;
	case 10:
#line 123 "sendero/view/expression/Compile.rl"
	{p--;}
	break;
	case 11:
#line 128 "sendero/view/expression/Compile.rl"
	{p--;}
	break;
	case 12:
#line 133 "sendero/view/expression/Compile.rl"
	{p--;}
	break;
#line 382 "sendero/view/expression/Compile.d"
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
#line 184 "sendero/view/expression/Compile.rl"
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