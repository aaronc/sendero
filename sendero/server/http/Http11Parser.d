#line 1 "sendero/server/http/Http11Parser.rl"
module sendero.server.http.Http11Parser;

//public import sendero.http.Request;
//public import tango.net.http.HttpConst;
import tango.util.log.Log;
import tango.core.Thread;
import Int = tango.text.convert.Integer;
import Text = tango.text.Util;

version (Win32) extern (C) int memicmp (char *, char *, uint);
version (Posix) extern (C) int strncasecmp (char *, char*, uint);

import sendero.server.model.IHttpServiceProvider;
import sendero.server.model.ITcpServiceProvider;

void snake_upcase_char(char* c)
{
	if (*c >= 'a' && *c <= 'z') *c &= ~0x20;
}

#line 96 "sendero/server/http/Http11Parser.rl"



#line 25 "sendero/server/http/Http11Parser.d"
static const byte[] _http_parser_actions = [
	0, 1, 0, 1, 2, 1, 3, 1, 
	4, 1, 5, 1, 6, 1, 7, 1, 
	8, 1, 9, 1, 11, 1, 12, 1, 
	13, 1, 14, 2, 0, 8, 2, 1, 
	2, 2, 4, 5, 2, 10, 7, 2, 
	12, 7, 3, 9, 10, 7
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
	0, 0, 19, 0, 0, 30, 23, 3, 
	5, 7, 33, 7, 0, 9, 27, 1, 
	1, 15, 0, 0, 0, 0, 0, 0, 
	0, 39, 0, 39, 0, 21, 21, 0, 
	0, 0, 0, 0, 42, 17, 42, 17, 
	36, 0, 36, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0
];

static const byte[] _http_parser_eof_actions = [
	0, 25, 25, 25, 25, 25, 25, 25, 
	25, 25, 25, 25, 25, 25, 25, 25, 
	25, 25, 25, 25, 25, 25, 25, 25, 
	25, 25, 25, 25, 25, 25, 25, 25, 
	25, 25, 25, 25, 25, 25, 25, 25, 
	25, 25, 25, 25, 25, 25, 25, 25, 
	25, 25, 25, 25, 25, 25, 25, 25, 
	25, 25
];

static const int http_parser_start = 1;
static const int http_parser_first_final = 57;
static const int http_parser_error = 0;

static const int http_parser_en_main = 1;

#line 99 "sendero/server/http/Http11Parser.rl"

class Http11Handler : ITcpRequestHandler, IHttpRequestData
{
	static this()
	{
		log = Log.lookup("sendero.server.http.Http11Parser");
	}
	static Logger log;
	
	final static bool isMatch (char[] testToken, char[] match)
	{
	        auto length = testToken.length;
	        if (length > match.length)
	            length = match.length;
	
	        if (length is 0)
	            return false;
	
	        version (Win32)
	                 return memicmp (testToken.ptr, match.ptr, length) is 0;
	        version (Posix)
	                 return strncasecmp (testToken.ptr, match.ptr, length) is 0;
	}
	/+
	
	
	final static char[] caseNormalizeHeaderName(char[] headerName)
	{
		void upcaseChar(ref char c)
		{
			if(c >= 'a' && c <= 'z') c &= ~0x20;
		}
	
		void lowercaseChar(ref char c)
		{
			if(c >= 'A' && c <= 'Z') c &= ~0x20;
		}
	
		version(SenderoHttpNonDestructive)
		{
			auto res = headerName.dup;
		}
		else alias headerName res;
		
		auto len = headerName.length;
		debug assert(len);
		else if(!len) return;
		
		upcaseChar(headerName[0]);
		
		bool up = true;
		for(size_t i = 0; i < len; ++i)
		{
			if(headerName[i] == '-') up = true;
			else if(up) {
				upcaseChar(headerName[i]);
				up = false;
			}
			else lowercaseChar(headerName[i]);
		}
	}+/

	this(IHttpRequestHandler req)
	{
		this.req = req;
		this.parseFiber_ = new Fiber(&parse);
	}
	
	protected IHttpRequestHandler req;
	protected Fiber parseFiber_;
	protected StagedReadBuffer data_;
	protected StagedReadBuffer curBuffer_;
	protected ITcpCompletionPort completionPort_;
	//protected void[][] response_;
	protected SyncTcpResponse response_;
	protected uint expectedContentLength_ = 0;
	protected bool chunked_ = false;
	
	void parse()
	{
		char* mark;
		char* field_start, query_start;
		char* body_start = null;
		size_t field_len;
		
		if(data_ is null) {
				throw new Exception("Http parsing initiated before any data has been received", __FILE__, __LINE__);
		}
		
		int cs = 0;
		char* p;
		char* pe;
		char* eof;		
	
		HttpRequestLineData reqLine;
		
		void parseHeaders() {
			p = cast(char*)data_.getReadable.ptr;
			pe = p + data_.getReadable.length;
			eof = pe;
			
			
#line 312 "sendero/server/http/Http11Parser.d"
	{
	cs = http_parser_start;
	}
#line 201 "sendero/server/http/Http11Parser.rl"
			
#line 316 "sendero/server/http/Http11Parser.d"
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
#line 25 "sendero/server/http/Http11Parser.rl"
	{mark = p; }
	break;
	case 1:
#line 27 "sendero/server/http/Http11Parser.rl"
	{ field_start = p; }
	break;
	case 2:
#line 28 "sendero/server/http/Http11Parser.rl"
	{ snake_upcase_char(p);}
	break;
	case 3:
#line 29 "sendero/server/http/Http11Parser.rl"
	{ 
    field_len = p-field_start;
  }
	break;
	case 4:
#line 33 "sendero/server/http/Http11Parser.rl"
	{ mark = p; }
	break;
	case 5:
#line 34 "sendero/server/http/Http11Parser.rl"
	{
  	auto fieldName = field_start[0..field_len];
  	auto fieldVal = mark[0.. p - mark];
  	debug log.trace("Parsed Http Header:{}:{}", fieldName, fieldVal); 
    req.handleHeader(fieldName, fieldVal); 
   	switch(fieldName)
   	{
	case "TRANSFER-ENCODING":
		if(isMatch(fieldVal, "chunked")) chunked_ = true;
		break;
   	case "CONTENT-LENGTH":
   		expectedContentLength_ = Int.parse(fieldVal);
    	debug log.trace("Parsed Content-Length:{}:{}", fieldName, expectedContentLength_);
    	break;
    default:
    	break;
    }
  }
	break;
	case 6:
#line 53 "sendero/server/http/Http11Parser.rl"
	{ 
      debug log.trace("Parsed Http Request Method:{}", mark[0.. p - mark]);
      reqLine.method = mark[0.. p - mark];
  }
	break;
	case 7:
#line 58 "sendero/server/http/Http11Parser.rl"
	{ 
      debug log.trace("Parsed Http RequestURI:{}", mark[0.. p - mark]);
      reqLine.uri = mark[0.. p - mark];
  }
	break;
	case 8:
#line 63 "sendero/server/http/Http11Parser.rl"
	{ 
     debug log.trace("Parsed Http Request Fragment:{}", mark[0.. p - mark]);
     reqLine.fragment = mark[0.. p - mark];
  }
	break;
	case 9:
#line 68 "sendero/server/http/Http11Parser.rl"
	{query_start = p; }
	break;
	case 10:
#line 69 "sendero/server/http/Http11Parser.rl"
	{ 
      debug log.trace("Parsed Http Query String:{}", query_start[0.. p - query_start]);
      reqLine.queryString = query_start[0.. p - query_start];
  }
	break;
	case 11:
#line 74 "sendero/server/http/Http11Parser.rl"
	{	
      debug log.trace("Parsed Http Version:{}", mark[0.. p - mark]);
      reqLine.httpVersion = mark[0.. p - mark];
  }
	break;
	case 12:
#line 79 "sendero/server/http/Http11Parser.rl"
	{
      debug log.trace("Parsed Http Request Path:{}", mark[0.. p - mark]);
      reqLine.path = mark[0.. p - mark];
  }
	break;
	case 13:
#line 84 "sendero/server/http/Http11Parser.rl"
	{ 
    body_start = p + 1; 
      debug log.trace("Finished Parsing Http Request:{}", (p + 1)[0 .. pe - p - 1]);
    {p++; if (true) goto _out; }
  }
	break;
#line 472 "sendero/server/http/Http11Parser.d"
		default: break;
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	if ( p == eof )
	{
	byte* __acts = &_http_parser_actions[_http_parser_eof_actions[cs]];
	uint __nacts = cast(uint) *__acts++;
	while ( __nacts-- > 0 ) {
		switch ( *__acts++ ) {
	case 14:
#line 90 "sendero/server/http/Http11Parser.rl"
	{
		assert(false);
	}
	break;
#line 493 "sendero/server/http/Http11Parser.d"
		default: break;
		}
	}
	}

	_out: {}
	}
#line 202 "sendero/server/http/Http11Parser.rl"
		}
		
		void badRequest() {
			//assert(false);
			req.signalFatalError;
			//response_ = req.processRequest(completionPort_);
		}
		
		parseHeaders;
		if(body_start is null || cs == http_parser_error) {
			size_t lastBufferLength;
			size_t retryCount = 0;
			while(retryCount < 5) {
					lastBufferLength = data_.readable;
					completionPort_.keepReading;
					Fiber.yield;
					if(data_.readable == lastBufferLength ) return badRequest;
					parseHeaders;
					if(body_start !is null || cs != http_parser_error) break;
					++retryCount;
			}
			if(body_start is null || cs == http_parser_error) return badRequest;
			/+if(data_.length > 1) {
				char[8192] buffer;
				void[] buf;
				foreach(b; data_) buf ~= b;
				data_ = [buf];
				parseHeaders;
				if(body_start is null || cs == http_parser_error) return fail;
			}
			else return fail;+/
			//return fail;
		}
		
		req.handleRequestLine(reqLine);
		if(chunked_) {
			/+while(1) {
				size_t chunkSize;
				foreach(char c; buf)
				{
					if(/*in hex range*/) {
						// check if is 0
						// add to chunk size
					}
					else if(c == ';') {
						// goto /r/n
					}
					else if(c == '/r') {
						//expect /n
					}
					else {
						debug assert(false, "Unexpected characted " ~ c ~ "in chunked transfer chunk-size line")
						// goto /r/n
					}
				}
				// expect chunkSize bytes of data
			}
			//restart ragel parser with trailing headers+/
		}
		else if(expectedContentLength_) {
			size_t startIdx = pe - body_start;
		
			size_t curLen() {
				size_t len = data_.readable - startIdx;
				auto next = data_.next;
				while(next !is null) {
					len += next.readable;
					next = data_.next;
				}
				return len;
			}
			
			curBuffer_ = data_;
			
			while(curLen < expectedContentLength_) {
				if(!curBuffer_.writeable) {
					completionPort_.keepReading;
					Fiber.yield;
					auto next = curBuffer_.next;
					if(next !is null) curBuffer_ = next;
					else return badRequest;
				}
				
				while(curLen < expectedContentLength_ && curBuffer_.writeable) {
					completionPort_.keepReading;
					Fiber.yield;
				}
				
				if(head is null) {
					assert(curBuffer_ == data_);
					assert(tail is null);
					assert(cur is null);
					head = new DataBuffer;
					head.data = data_.getReadable[startIdx..$];
					head.next = null;
					tail = head;
					cur = head;
				}
				else {
					assert(curBuffer_ != data_);
					assert(tail.next is null);
					tail.next = new DataBuffer;
					tail = tail.next;
					tail.data = curBuffer_.getReadable[startIdx..$];
					tail.next = null;
				}
				
				auto next = curBuffer_.next;
				if(next !is null) curBuffer_ = next;
				
				Fiber handleFiber;
				if(curLen >= expectedContentLength_) break;
				handleFiber.call;				
				if(response_ !is null) return;
			}
			response_ = req.processRequest(this, completionPort_);
		}
		else {
			response_ = req.processRequest(this, completionPort_);
			if(body_start != pe) debug log.warn("Unknown HTTP transfer encoding, body_start = ? and pe = ?", body_start, pe);
		}
	}
	
	SyncTcpResponse handleRequest(StagedReadBuffer data, ITcpCompletionPort completionPort)
	{
		completionPort_ = completionPort;
		data_ = data;
		if(parseFiber_.state != Fiber.State.TERM) {
			// TODO check for exec state and wait
			parseFiber_.call;
			//return response_;
		}
		//else return null;
		return response_;
	}
	
	void doHandling()
	{
		response_ = req.processRequest(this, completionPort_);
	}
	
	size_t expectedContentLength()
	{
		return chunked_ ? 0 : expectedContentLength_;
	}
	
	bool chunked()
	{
		return chunked_;
	}
	
	void[] nextContentBuffer()
	{
		if(cur.next is null) {
			Fiber.yield;
			if(cur.next is null) return null;
		}
		cur = cur.next;
		return cur.data;
	}
	
	void releaseContentBuffer(void[])
	{
		
	}
	
	struct DataBuffer
	{
		void[] data;
		DataBuffer* next;
	}
	
	DataBuffer* head;
	DataBuffer* cur;
	DataBuffer* tail;
}

debug(SenderoUnittest)
{
	unittest
	{
		auto handler = new Http11Handler(null);
		//handler.handleRequest(["GET /test"," HTTP/1.1\r\n\r\n"],null);
	}
}