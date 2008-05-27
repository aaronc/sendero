#line 1 "sendero/view/expression/Compile.rl"
module sendero.view.expression.Compile;

import tango.io.Stdout;

#line 44 "sendero/view/expression/Compile.rl"



#line 9 "sendero/view/expression/Compile.d"
static const byte[] _sendero_view_compile_actions = [
	0, 1, 0, 1, 1
];

static const byte[] _sendero_view_compile_key_offsets = [
	0, 0, 8
];

static const char[] _sendero_view_compile_trans_keys = [
	32u, 95u, 9u, 13u, 65u, 90u, 97u, 122u, 
	95u, 48u, 57u, 65u, 90u, 97u, 122u, 0
];

static const byte[] _sendero_view_compile_single_lengths = [
	0, 2, 1
];

static const byte[] _sendero_view_compile_range_lengths = [
	0, 3, 3
];

static const byte[] _sendero_view_compile_index_offsets = [
	0, 0, 6
];

static const byte[] _sendero_view_compile_indicies = [
	0, 2, 0, 2, 2, 1, 4, 4, 
	4, 4, 3, 0
];

static const byte[] _sendero_view_compile_trans_targs = [
	1, 0, 2, 1, 2
];

static const byte[] _sendero_view_compile_trans_actions = [
	0, 0, 1, 3, 0
];

static const int sendero_view_compile_start = 1;
static const int sendero_view_compile_first_final = 3;
static const int sendero_view_compile_error = 0;

static const int sendero_view_compile_en_main = 1;

#line 47 "sendero/view/expression/Compile.rl"

class Fsm
{
	int cs = 0;
	int* stack;
	int top;
	char* tokenStart;
}

void parse(char[] src)
{
	auto fsm = new Fsm;
	char* p = src.ptr;
	char* pe = p + src.length + 1;
	char* eof = pe;
	
#line 69 "sendero/view/expression/Compile.d"
	{
	 fsm.cs = sendero_view_compile_start;
	}
#line 63 "sendero/view/expression/Compile.rl"
	
#line 73 "sendero/view/expression/Compile.d"
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
#line 10 "sendero/view/expression/Compile.rl"
	{fsm.tokenStart = p;}
	break;
	case 1:
#line 11 "sendero/view/expression/Compile.rl"
	{Stdout(fsm.tokenStart[0 .. p - fsm.tokenStart]);}
	break;
#line 152 "sendero/view/expression/Compile.d"
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
#line 64 "sendero/view/expression/Compile.rl"
}

debug(SenderoUnittest)
{

unittest
{
	parse("test one test ");
}

}