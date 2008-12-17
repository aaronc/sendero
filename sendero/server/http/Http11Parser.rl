module sendero.server.http.Http11Parser;

//public import sendero.http.Request;
//public import tango.net.http.HttpConst;
import tango.util.log.Log;
import tango.core.Thread;
import Int = tango.text.convert.Integer;

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

  include http_parser_common "http11_parser_common._rl";

}%%

%% write data;

class Http11Parser : ITcpRequestHandler
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
	protected void[][] data;
	
	void parse()
	{
		char* mark;
		char* field_start, query_start;
		char* body_start = null;
		size_t field_len;
		
		char[] buffer; //TODO
		
		int cs = 0;
		char* p = buffer.ptr;
		char* pe = p + buffer.length + 1;
		char* eof = pe;
		
		uint expectedContentLength = 0;
	
		HttpRequestLineData reqLine;
		
		%% write init;
		%% write exec;
		
		req.handleRequestLine(reqLine);
		
		/+if(cs == http_parser_error) return false;
		else return true;+/
	}	
	
	SyncTcpResponse handleRequest(void[][] data, ITcpCompletionPort completionPort)
	{
		parseFiber_.call;
		return null;
	}
}