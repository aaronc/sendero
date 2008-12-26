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

%%{
  
  machine http_parser;

  action mark {mark = fpc; }

  action start_field { field_start = fpc; }
  action snake_upcase_field { snake_upcase_char(fpc);} 
  action write_field { 
    field_len = fpc-field_start;
  }

  action start_value { mark = fpc; }
  action write_value {
  	auto fieldName = field_start[0..field_len];
  	auto fieldVal = mark[0.. fpc - mark];
  	debug log.trace("Parsed Http Header:{}:{}", fieldName, fieldVal); 
    req.handleHeader(fieldName, fieldVal); 
   	switch(fieldName)
   	{
   	case "CONTENT-LENGTH":
   		expectedContentLength = Int.parse(fieldVal);
    	debug log.trace("Parsed Content-Length:{}:{}", fieldName, expectedContentLength);
    	break;
    default:
    	break;
    }    
  }
  
  action request_method { 
      debug log.trace("Parsed Http Request Method:{}", mark[0.. fpc - mark]);
      reqLine.method = mark[0.. fpc - mark];
  }
  
  action request_uri { 
      debug log.trace("Parsed Http RequestURI:{}", mark[0.. fpc - mark]);
      reqLine.uri = mark[0.. fpc - mark];
  }

  action fragment { 
     debug log.trace("Parsed Http Request Fragment:{}", mark[0.. fpc - mark]);
     reqLine.fragment = mark[0.. fpc - mark];
  }
  
  action start_query {query_start = fpc; }
  action query_string { 
      debug log.trace("Parsed Http Query String:{}", query_start[0.. fpc - query_start]);
      reqLine.queryString = query_start[0.. fpc - query_start];
  }

  action http_version {	
      debug log.trace("Parsed Http Version:{}", mark[0.. fpc - mark]);
      reqLine.httpVersion = mark[0.. fpc - mark];
  }

  action request_path {
      debug log.trace("Parsed Http Request Path:{}", mark[0.. fpc - mark]);
      reqLine.path = mark[0.. fpc - mark];
  }

  action done { 
    body_start = fpc + 1; 
      debug log.trace("Finished Parsing Http Request:{}", (fpc + 1)[0 .. pe - fpc - 1]);
    fbreak;
  }

  include http_parser_common "sendero/server/http/http11_parser_common._rl";

}%%

%% write data;

class Http11Handler : ITcpRequestHandler
{
	static this()
	{
		log = Log.lookup("sendero.server.http.Http11Parser");
	}
	static Logger log;
	/+
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
	protected void[][] data_;
	protected ITcpCompletionPort completionPort_;
	protected void[][] response_;
	
	void parse()
	{
		char* mark;
		char* field_start, query_start;
		char* body_start = null;
		size_t field_len;
		
		if(!data.length) {
				throw new Exception("Http parsing initiated before any data has been received");
		}
		
		int cs = 0;
		char* p;
		char* pe;
		char* eof;
		
		uint expectedContentLength = 0;
		bool chunked = false;
	
		HttpRequestLineData reqLine;
		
		void parseHeaders() {
			p = data[0].ptr;
			pe = p + data[0].length + 1;
			eof = pe;
			
			%% write init;
			%% write exec;
		}
		
		void fail() {
			req.signalFatalError;
			response_ = req.processRequest(completionPort_);
		}
		
		parseHeaders;
		if(body_start is null || cs == http_parser_error) {
			if(data_.length > 1) {
				void[] buf;
				foreach(b; data_) buf ~= b;
				data_ = [buf];
				parseHeaders;
				if(body_start is null || cs == http_parser_error) return fail;
			}
			else return fail;
		}
		
		req.handleRequestLine(reqLine);

		size_t calcContentLength() {
			size_t curLen = pe - body_start;
			foreach(buf; data_[1..$]) curLen += buf.length;
			return curLen;
		}
		
		data_[0] = body_start[0 .. pe - body_start];
		
		if(expectedContentLength) {
			auto curLen = calcContentLength;
			while(curLen < expectedContentLength) {
				completionPort_.keepReading;
				Fiber.yield;
				curLen = calcContentLength;
			}
			
			req.handleData(data_);
			response_ = req.processRequest(completionPort_);
		}
		else if(chunked) {
			uint bufIdx = 0;
			uint chunkSize = 0;
			assert(false, "Not implemented yet");
		}
	}
	
	SyncTcpResponse handleRequest(void[][] data, ITcpCompletionPort completionPort)
	{
		completionPort_ = completionPort;
		data_ ~= data;
		if(parseFiber_.state != Fiber.State.TERM) {
			// TODO check for exec state and wait
			parseFiber_.call;
			return response_;
		}
		else return null;
	/+	if(parseFiber_.state != Fiber.State.TERM) return null;
		else return response_;+/
	}
}