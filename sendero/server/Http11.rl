module http11_parser;

public import sendero.http.Request;
public import tango.net.http.HttpConst;

import tango.util.log.Config;
import tango.util.log.Log;

%%{
  
  machine http_parser;

  action mark {mark = fpc; }

  action start_field { field_start = fpc; }
  action snake_upcase_field { /* FIXME stub */ }
  action write_field { 
    field_len = fpc-field_start;
  }

  action start_value { mark = fpc; }
  action write_value { 
    req.headers[field_start[0..field_len]] = mark[0.. fpc - mark];
    switch(field_start[0..field_len])
    {
    case "Cookie":
		req.cookies = parseCookies(mark[0.. fpc - mark]);
    	break;
	default: 
		break;
    }
    log.info("write_value:{}:{}", field_start[0..field_len], mark[0.. fpc - mark]);
  }
  action request_method { 
      log.info("request_method:{}", mark[0.. fpc - mark]);
      switch(mark[0.. fpc - mark])
      {
      case "GET": method = HttpMethod.Get; break;
      case "POST": method = HttpMethod.Post; break;
      case "PUT": method = HttpMethod.Put; break;
      case "DELETE": method = HttpMethod.Delete; break;
      default: return HttpResponses.MethodNotAllowed;
      }
  }
  action request_uri { 
      log.info("request_uri:{}", mark[0.. fpc - mark]);
  }
  action fragment { 
     log.info("fragment:{}", mark[0.. fpc - mark]);
     postStr = mark[0.. fpc - mark];
  }
  
  action start_query {query_start = fpc; }
  action query_string { 
      log.info("query_string:{}", query_start[0.. fpc - query_start]);
      getStr = mark[0.. fpc - mark];
  }

  action http_version {	
      log.info("http_version:{}", mark[0.. fpc - mark]);
  }

  action request_path {
      log.info("request_path:{}", mark[0.. fpc - mark]);
      url = mark[0.. fpc - mark];
  }

  action done { 
    body_start = fpc + 1; 
      log.info("done:{}", (fpc + 1)[0 .. pe - fpc - 1]);
    fbreak;
  }

  include http_parser_common "sendero/server/http11_parser_common._rl";

}%%

%% write data;

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
	
	%% write init;
	%% write exec;
	
	req.parse(method, url, getStr, postStr);
	
	if(cs == http_parser_error) return HttpResponses.BadRequest;
	else return HttpResponses.Accepted;
}