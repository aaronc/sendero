#line 1 "sendero/server/Http11.rl"
module http11_parser;

public import sendero.http.Request;
public import tango.net.http.HttpConst;

import tango.util.log.Config;
import tango.util.log.Log;

#line 76 "sendero/server/Http11.rl"



#line 13 "sendero/server/Http11.d"
static const byte[] _http_parser_actions = [
	0, 1, 0, 1, 2, 1, 3, 1, 
	4, 1, 5, 1, 6, 1, 7, 1, 
	8, 1, 9, 1, 11, 1, 12, 1, 
	13, 2, 0, 8, 2, 1, 2, 2, 
	4, 5, 2, 10, 7, 2, 12, 7, 
	3, 9, 10, 7
];

static const short[] _http_parser_key_offsets = [
	0, 0, 8, 17, 27, 29, 30, 31, 
	32, 33, 34, 36, 39, 41, 44, 45, 
	61, 62, 78, 80, 81, 87, 93, 99, 
	105, 115, 121, 127, 133, 141, 147, 153, 
	160, 166, 172, 178, 184, 190, 196, 205, 
	214, 223, 232, 241, 250, 259, 268, 277, 
	286, 295, 304, 313, 322, 331, 340, 349, 
	358, 359
];

static const char[] _http_parser_trans_keys = [
	36u, 95u, 45u, 46u, 48u, 57u, 65u, 90u, 
	32u, 36u, 95u, 45u, 46u, 48u, 57u, 65u, 
	90u, 42u, 43u, 47u, 58u, 45u, 57u, 65u, 
	90u, 97u, 122u, 32u, 35u, 72u, 84u, 84u, 
	80u, 47u, 48u, 57u, 46u, 48u, 57u, 48u, 
	57u, 13u, 48u, 57u, 10u, 13u, 33u, 124u, 
	126u, 35u, 39u, 42u, 43u, 45u, 46u, 48u, 
	57u, 65u, 90u, 94u, 122u, 10u, 33u, 58u, 
	124u, 126u, 35u, 39u, 42u, 43u, 45u, 46u, 
	48u, 57u, 65u, 90u, 94u, 122u, 13u, 32u, 
	13u, 32u, 35u, 37u, 127u, 0u, 31u, 32u, 
	35u, 37u, 127u, 0u, 31u, 48u, 57u, 65u, 
	70u, 97u, 102u, 48u, 57u, 65u, 70u, 97u, 
	102u, 43u, 58u, 45u, 46u, 48u, 57u, 65u, 
	90u, 97u, 122u, 32u, 35u, 37u, 127u, 0u, 
	31u, 48u, 57u, 65u, 70u, 97u, 102u, 48u, 
	57u, 65u, 70u, 97u, 102u, 32u, 35u, 37u, 
	59u, 63u, 127u, 0u, 31u, 48u, 57u, 65u, 
	70u, 97u, 102u, 48u, 57u, 65u, 70u, 97u, 
	102u, 32u, 35u, 37u, 63u, 127u, 0u, 31u, 
	48u, 57u, 65u, 70u, 97u, 102u, 48u, 57u, 
	65u, 70u, 97u, 102u, 32u, 35u, 37u, 127u, 
	0u, 31u, 32u, 35u, 37u, 127u, 0u, 31u, 
	48u, 57u, 65u, 70u, 97u, 102u, 48u, 57u, 
	65u, 70u, 97u, 102u, 32u, 36u, 95u, 45u, 
	46u, 48u, 57u, 65u, 90u, 32u, 36u, 95u, 
	45u, 46u, 48u, 57u, 65u, 90u, 32u, 36u, 
	95u, 45u, 46u, 48u, 57u, 65u, 90u, 32u, 
	36u, 95u, 45u, 46u, 48u, 57u, 65u, 90u, 
	32u, 36u, 95u, 45u, 46u, 48u, 57u, 65u, 
	90u, 32u, 36u, 95u, 45u, 46u, 48u, 57u, 
	65u, 90u, 32u, 36u, 95u, 45u, 46u, 48u, 
	57u, 65u, 90u, 32u, 36u, 95u, 45u, 46u, 
	48u, 57u, 65u, 90u, 32u, 36u, 95u, 45u, 
	46u, 48u, 57u, 65u, 90u, 32u, 36u, 95u, 
	45u, 46u, 48u, 57u, 65u, 90u, 32u, 36u, 
	95u, 45u, 46u, 48u, 57u, 65u, 90u, 32u, 
	36u, 95u, 45u, 46u, 48u, 57u, 65u, 90u, 
	32u, 36u, 95u, 45u, 46u, 48u, 57u, 65u, 
	90u, 32u, 36u, 95u, 45u, 46u, 48u, 57u, 
	65u, 90u, 32u, 36u, 95u, 45u, 46u, 48u, 
	57u, 65u, 90u, 32u, 36u, 95u, 45u, 46u, 
	48u, 57u, 65u, 90u, 32u, 36u, 95u, 45u, 
	46u, 48u, 57u, 65u, 90u, 32u, 36u, 95u, 
	45u, 46u, 48u, 57u, 65u, 90u, 32u, 0
];

static const byte[] _http_parser_single_lengths = [
	0, 2, 3, 4, 2, 1, 1, 1, 
	1, 1, 0, 1, 0, 1, 1, 4, 
	1, 4, 2, 1, 4, 4, 0, 0, 
	2, 4, 0, 0, 6, 0, 0, 5, 
	0, 0, 4, 4, 0, 0, 3, 3, 
	3, 3, 3, 3, 3, 3, 3, 3, 
	3, 3, 3, 3, 3, 3, 3, 3, 
	1, 0
];

static const byte[] _http_parser_range_lengths = [
	0, 3, 3, 3, 0, 0, 0, 0, 
	0, 0, 1, 1, 1, 1, 0, 6, 
	0, 6, 0, 0, 1, 1, 3, 3, 
	4, 1, 3, 3, 1, 3, 3, 1, 
	3, 3, 1, 1, 3, 3, 3, 3, 
	3, 3, 3, 3, 3, 3, 3, 3, 
	3, 3, 3, 3, 3, 3, 3, 3, 
	0, 0
];

static const short[] _http_parser_index_offsets = [
	0, 0, 6, 13, 21, 24, 26, 28, 
	30, 32, 34, 36, 39, 41, 44, 46, 
	57, 59, 70, 73, 75, 81, 87, 91, 
	95, 102, 108, 112, 116, 124, 128, 132, 
	139, 143, 147, 153, 159, 163, 167, 174, 
	181, 188, 195, 202, 209, 216, 223, 230, 
	237, 244, 251, 258, 265, 272, 279, 286, 
	293, 295
];

static const byte[] _http_parser_indicies = [
	0, 0, 0, 0, 0, 1, 2, 3, 
	3, 3, 3, 3, 1, 4, 5, 6, 
	7, 5, 5, 5, 1, 8, 9, 1, 
	10, 1, 11, 1, 12, 1, 13, 1, 
	14, 1, 15, 1, 16, 15, 1, 17, 
	1, 18, 17, 1, 19, 1, 20, 21, 
	21, 21, 21, 21, 21, 21, 21, 21, 
	1, 22, 1, 23, 24, 23, 23, 23, 
	23, 23, 23, 23, 23, 1, 26, 27, 
	25, 29, 28, 30, 1, 32, 1, 1, 
	31, 33, 1, 35, 1, 1, 34, 36, 
	36, 36, 1, 34, 34, 34, 1, 37, 
	38, 37, 37, 37, 37, 1, 8, 9, 
	39, 1, 1, 38, 40, 40, 40, 1, 
	38, 38, 38, 1, 41, 43, 44, 45, 
	46, 1, 1, 42, 47, 47, 47, 1, 
	42, 42, 42, 1, 8, 9, 49, 50, 
	1, 1, 48, 51, 51, 51, 1, 48, 
	48, 48, 1, 52, 54, 55, 1, 1, 
	53, 56, 58, 59, 1, 1, 57, 60, 
	60, 60, 1, 57, 57, 57, 1, 2, 
	61, 61, 61, 61, 61, 1, 2, 62, 
	62, 62, 62, 62, 1, 2, 63, 63, 
	63, 63, 63, 1, 2, 64, 64, 64, 
	64, 64, 1, 2, 65, 65, 65, 65, 
	65, 1, 2, 66, 66, 66, 66, 66, 
	1, 2, 67, 67, 67, 67, 67, 1, 
	2, 68, 68, 68, 68, 68, 1, 2, 
	69, 69, 69, 69, 69, 1, 2, 70, 
	70, 70, 70, 70, 1, 2, 71, 71, 
	71, 71, 71, 1, 2, 72, 72, 72, 
	72, 72, 1, 2, 73, 73, 73, 73, 
	73, 1, 2, 74, 74, 74, 74, 74, 
	1, 2, 75, 75, 75, 75, 75, 1, 
	2, 76, 76, 76, 76, 76, 1, 2, 
	77, 77, 77, 77, 77, 1, 2, 78, 
	78, 78, 78, 78, 1, 2, 1, 1, 
	0
];

static const byte[] _http_parser_trans_targs = [
	2, 0, 3, 38, 4, 24, 28, 25, 
	5, 20, 6, 7, 8, 9, 10, 11, 
	12, 13, 14, 15, 16, 17, 57, 17, 
	18, 19, 14, 18, 19, 14, 5, 21, 
	22, 5, 21, 22, 23, 24, 25, 26, 
	27, 5, 28, 20, 29, 31, 34, 30, 
	31, 32, 34, 33, 5, 35, 20, 36, 
	5, 35, 20, 36, 37, 39, 40, 41, 
	42, 43, 44, 45, 46, 47, 48, 49, 
	50, 51, 52, 53, 54, 55, 56
];

static const byte[] _http_parser_trans_actions = [
	1, 0, 11, 0, 1, 1, 1, 1, 
	13, 13, 1, 0, 0, 0, 0, 0, 
	0, 0, 19, 0, 0, 28, 23, 3, 
	5, 7, 31, 7, 0, 9, 25, 1, 
	1, 15, 0, 0, 0, 0, 0, 0, 
	0, 37, 0, 37, 0, 21, 21, 0, 
	0, 0, 0, 0, 40, 17, 40, 17, 
	34, 0, 34, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0
];

static const int http_parser_start = 1;
static const int http_parser_first_final = 57;
static const int http_parser_error = 0;

static const int http_parser_en_main = 1;

#line 79 "sendero/server/Http11.rl"

HttpStatus parse(char[] buffer, Request req)
{
	auto log = Log.lookup("http11_parser");

	char* mark;
	char* field_start, query_start, body_start;
	size_t field_len;
	
	int cs = 0;
	char* p = buffer.ptr;
	char* pe = p + buffer.length + 1;
	char* eof = pe;
	
	req.reset;
	
	HttpMethod method;
	char[] url, getStr, postStr;
	
	
#line 207 "sendero/server/Http11.d"
	{
	cs = http_parser_start;
	}
#line 99 "sendero/server/Http11.rl"
	
#line 211 "sendero/server/Http11.d"
	{
	int _klen;
	uint _trans;
	byte* _acts;
	uint _nacts;
	char* _keys;

	if ( p == pe )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = &_http_parser_trans_keys[_http_parser_key_offsets[cs]];
	_trans = _http_parser_index_offsets[cs];

	_klen = _http_parser_single_lengths[cs];
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

	_klen = _http_parser_range_lengths[cs];
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
	_trans = _http_parser_indicies[_trans];
	cs = _http_parser_trans_targs[_trans];

	if ( _http_parser_trans_actions[_trans] == 0 )
		goto _again;

	_acts = &_http_parser_actions[_http_parser_trans_actions[_trans]];
	_nacts = cast(uint) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
#line 13 "sendero/server/Http11.rl"
	{mark = p; }
	break;
	case 1:
#line 15 "sendero/server/Http11.rl"
	{ field_start = p; }
	break;
	case 2:
#line 16 "sendero/server/Http11.rl"
	{ /* FIXME stub */ }
	break;
	case 3:
#line 17 "sendero/server/Http11.rl"
	{ 
    field_len = p-field_start;
  }
	break;
	case 4:
#line 21 "sendero/server/Http11.rl"
	{ mark = p; }
	break;
	case 5:
#line 22 "sendero/server/Http11.rl"
	{ 
    req.headers[field_start[0..field_len]] = mark[0.. p - mark];
    switch(field_start[0..field_len])
    {
    case "Cookie":
		req.cookies = parseCookies(mark[0.. p - mark]);
    	break;
	default: 
		break;
    }
    log.info("write_value:{}:{}", field_start[0..field_len], mark[0.. p - mark]);
  }
	break;
	case 6:
#line 34 "sendero/server/Http11.rl"
	{ 
      log.info("request_method:{}", mark[0.. p - mark]);
      switch(mark[0.. p - mark])
      {
      case "GET": method = HttpMethod.Get; break;
      case "POST": method = HttpMethod.Post; break;
      case "PUT": method = HttpMethod.Put; break;
      case "DELETE": method = HttpMethod.Delete; break;
      default: return HttpResponses.MethodNotAllowed;
      }
  }
	break;
	case 7:
#line 45 "sendero/server/Http11.rl"
	{ 
      log.info("request_uri:{}", mark[0.. p - mark]);
  }
	break;
	case 8:
#line 48 "sendero/server/Http11.rl"
	{ 
     log.info("fragment:{}", mark[0.. p - mark]);
     postStr = mark[0.. p - mark];
  }
	break;
	case 9:
#line 53 "sendero/server/Http11.rl"
	{query_start = p; }
	break;
	case 10:
#line 54 "sendero/server/Http11.rl"
	{ 
      log.info("query_string:{}", query_start[0.. p - query_start]);
      getStr = query_start[0.. p - query_start];
  }
	break;
	case 11:
#line 59 "sendero/server/Http11.rl"
	{	
      log.info("http_version:{}", mark[0.. p - mark]);
  }
	break;
	case 12:
#line 63 "sendero/server/Http11.rl"
	{
      log.info("request_path:{}", mark[0.. p - mark]);
      url = mark[0.. p - mark];
  }
	break;
	case 13:
#line 68 "sendero/server/Http11.rl"
	{ 
    body_start = p + 1; 
      log.info("done:{}", (p + 1)[0 .. pe - p - 1]);
    {p++; if (true) goto _out; }
  }
	break;
#line 366 "sendero/server/Http11.d"
		default: break;
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	_out: {}
	}
#line 100 "sendero/server/Http11.rl"
	
	req.parse(method, url, getStr, postStr);
	
	if(cs == http_parser_error) return HttpResponses.BadRequest;
	else return HttpResponses.Accepted;
}