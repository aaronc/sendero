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

	action action_eof {
		assert(false);
	}

  include http_parser_common "sendero/server/http/http11_parser_common._rl";

}%%

%% write data;

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
			
			%% write init;
			%% write exec;
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