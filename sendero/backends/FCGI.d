module sendero.backends.FCGI;

version(SenderoLog)
{
	public import tango.util.log.Log;
}

version(SenderoBenchmark)
{
	version(SenderoLog) {}
	else {
		import tango.io.FileConduit;
		import  tango.io.Print;
		import  tango.text.convert.Layout;
	}
	import tango.time.StopWatch;
	
}

import tango.net.Uri;
import tango.text.Util;
import tango.net.http.HttpCookies;
import tango.sys.Process;
import tango.core.Thread;
import tango.io.model.IConduit;
import tango.core.Exception;

import fcgi.Request;
import fcgi.Connection;
import fcgi.InternalConduit;
import fcgi.Protocol;

import sendero.backends.Base;
import sendero.routing.Common;

class FCGIRunner(SessionT, RequestT = Request, ResponseT = Response) : AbstractBackend!(SessionT, RequestT, ResponseT)
{
	this(ResponseT function(RequestT) appMain)
	{
		super(appMain);
	}
	
	void run()
	{
		version(SenderoLog) auto log = Log.getLogger("sendero.backends.FCGI");		
	
		FastCGIRequest fcgiRequest = new FastCGIRequest();
		//auto output = new FastCGIOutputBuffer(fcgiRequest);
		auto session = SessionT.cur;

		while ( fcgiRequest.accept () )
		{			
			try
			{
				version(SenderoBenchmark) {
					StopWatch st;
					st.start;
				}
				
				// Begin processing request
				
				session.reset;
				
				// Extract request info from FastCGI args
				
				HttpMethod method;
				auto rm = ("REQUEST_METHOD" in fcgiRequest.args);
				if(rm) {
					switch(*rm) 
					{
					case "GET": method = HttpMethod.Get; break;
					case "POST": method = HttpMethod.Post; break;
					default: throw new Exception("Unhandled request method " ~ *rm); break;
					}
				}

				char[] rawGet;
				auto q = ("QUERY_STRING" in fcgiRequest.args);
				
				char[] url;
				auto r = ("REDIRECT_URL" in fcgiRequest.args);
				if(r) {	url = *r; }
				
				char[] rawPost;
				if(method == HttpMethod.Post) {
					while(1) {
						char[100] str;
						int rd = fcgiRequest.stdin.read(str);
						if(rd > 0) { rawPost ~= str[0 .. rd]; }
						if(rd != str.length) { break; }
					}
				}
				
				auto request = session.req;
				request.parse(method, url, rawGet, rawPost);
				
				auto c = ("HTTP_COOKIE" in fcgiRequest.args);
				if(c) { request.cookies = parseCookies(*c); }
				
				auto ip = ("REMOTE_ADDR" in fcgiRequest.args);
				if(ip) { request.ip = *ip; }
				
				// Run appMain
				
				auto res = appMain(request);
				
				// Begin sending output client
				
				auto output = fcgiRequest.stdout;
				
				//output.reset;
				
				foreach(cookie; session.cookies)
 					cookie.produce(cast(void delegate(void[]))&output.write);
				
				res.render(cast(void delegate(void[]))&output.write);
				
				output.flush;
				
				// Done processing request
				
				fcgiRequest.exitStatus = 0;
				
				version(SenderoBenchmark) {
					auto renderTime = st.stop;
					version(SenderoLog) log.format("Sendero Render Time:{}ms Url:{}", renderTime * 1000, url);
					else benchmarkOut.formatln("Sendero Render Time:{}ms, Url:{}, Method:{}", renderTime * 1000, url, *rm);
				}
			}
			catch(Exception ex)
			{
				auto stderr = fcgiRequest.stderr;
				
				void defaultErrorMsg(Exception ex)
				{
					stderr.write("Content-type: text/html\r\n\r\n");		
					debug stderr.write("Sendero error: " ~ ex.toString);
					else stderr.write("Error");
				}
				
				if(errorHandler) {
					try
					{
						auto res = errorHandler();
						res.render(cast(void delegate(void[]))&stderr.write);
					}
					catch(Exception ex2)
					{
						defaultErrorMsg(ex2);
					}
				}
				else {
					defaultErrorMsg(ex);
				}
				version(SenderoLog) log.error ("Exception caught" ~ ex.toString);
				fcgiRequest.exitStatus = 0;
			}
		}
	}
}

class FastCGIOutputBuffer : OutputStream
{
	this(FastCGIRequest req)
	{
		req_ = req;
		buffer = new ubyte[FastCGIHeaderStruct.sizeof + ushort.max];
		reset;
	}
	
	private FastCGIRequest req_;
	private FastCGIInternalConduit conduit_;
	
	private ubyte[] buffer;
	
	private uint index;
	
	IConduit conduit () { return conduit_; }
	
	void close() {}
	
	private uint writable()
	{
		return buffer.length - index;
	}
	
	void reset()
	{
		FastCGIHeaderStruct header;

        header.protocolVersion = FastCGIVersion;
        header.recordType = FastCGIRecordType.Stdout;
        header.reqID1 = (req_.id >> 8) & 0xff;
        header.reqID2 = (req_.id) & 0xff;
        header.contentLength1 = 0;
        header.contentLength2 = 0;
        header.paddingLength = 0;
        header.reserved = 0;

        buffer[0 .. header.sizeof] = (cast(ubyte*) &header)[0 .. header.sizeof];
        index = header.sizeof;
	}
	
	alias reset clear;
	
	uint write(void[] src)
	{
		uint x = writable;
		if(src.length <= x) {
			buffer[index .. index + src.length] = cast(ubyte[])src;
			index += src.length;
			return src.length;
		}
		else {
			uint pos = 0;
			
			buffer[index .. x] = cast(ubyte[])src[pos .. x];
			pos += x;
			
			while(pos < src.length) {
				flush;
				x = writable;
				buffer[index .. x] = cast(ubyte[])src[pos .. x];
				pos += x;
			}
		}		
	}
	
	OutputStream copy(InputStream src)
	{
		auto copied = src.read(buffer[index .. buffer.length]);
		if(copied == IOStream.Eof) throw new IOException("Error when copying InputStream in StringWriter");
		index += copied;
		return this;
	}
	
	OutputStream flush()
	{
		int len;
		if(index == buffer.length - 1) len = ushort.max;
		else len = index - FastCGIHeaderStruct.sizeof;
		
        ubyte padding = 8 - (len & 7);
        if (padding == 8)
                padding = 0;
        
        buffer[4] = (len >> 8) & 0xff;
        buffer[5] = (len) & 0xff;
        buffer[6] = padding;
        
        req_.conduit.write(buffer);
        
        reset;
		return this;
	}
}

version(Unittest)
{
	import sendero.session.Session;
	alias SessionGlobal!(BasicSessionData) Session;
	
	alias FCGIRunner!(Session) FCGI;
	
	Response test(Request req)
	{
		return Response();
	}
	
	unittest
	{
		auto fcgi = new FCGI(&test);
	}
}