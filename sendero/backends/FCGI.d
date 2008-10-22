/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.backends.FCGI;

public import tango.util.log.Log;
import tango.io.FileSystem;

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

debug(SenderoRuntime) {
	//import qcf.Debug;
	import sendero.Debug;
	Logger log;
	static this()
	{
		log = Log.lookup("debug.SenderoRuntime");
	}
}

import tango.net.Uri;
import tango.text.Util;
import tango.net.http.HttpCookies;
import tango.sys.Process;
import tango.core.Thread;
import tango.io.model.IConduit;
import tango.io.Console;
import tango.core.Exception;
import Int = tango.text.convert.Integer;

import fcgi.Request;
import fcgi.Connection;
import fcgi.InternalConduit;
import fcgi.Protocol;

import sendero.backends.Base;
import sendero.routing.Common;

static this()
{
	Cout.output = new ConsoleRedirect;
}

class ConsoleRedirect : OutputStream
{
	IConduit conduit () { return null; }
	void close() {}
	uint write(void[] src) { return src.length; }
	OutputStream copy (InputStream src) { return this; }
	OutputStream flush () { return this; }
}

/**
 * Sendero backend for FCGI (uses <a href="http://www.dsource.org/projects/fastcgi4d">FastCGI4D</a> 
 * 
 */
class FCGIRunner(SessionT, RequestT = Request): AbstractBackend!(SessionT, RequestT)
{
	this(void function(RequestT) appMain)
	{
		super(appMain);
	}
	
	void run(char[][] args)
	{
		auto log = Log.getLogger("sendero.backends.FCGI");
		log.info("Working in directory {}", FileSystem.getDirectory);
	
		FastCGIRequest fcgiRequest;
		if(args.length < 2) {
			fcgiRequest = new FastCGIRequest;
		}
		else {
			fcgiRequest = new FastCGIRequest(new FastCGIConnection("localhost:9000", "9000"));
		}
		
		//auto output = new FastCGIOutputBuffer(fcgiRequest);
		auto session = SessionT.cur;
		auto res = new Responder;

		auto request = session.req;
		request.setResponder(res);

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
				res.reset;
				
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
				if(q) rawGet = *q;
				
				char[] url;
				auto r = ("REQUEST_URI" in fcgiRequest.args);
				if(r) {
					url = *r;
					auto qIndex = locate(*r, '?');
					url = url[0 .. qIndex];
				}
				
				char[] rawPost;
				if(method == HttpMethod.Post) {
					while(1) {
						char[100] str;
						int rd = fcgiRequest.stdin.read(str);
						if(rd > 0) { rawPost ~= str[0 .. rd]; }
						if(rd != str.length) { break; }
					}
				}
				
				request.parse(method, url, rawGet, rawPost);
				
				auto c = ("HTTP_COOKIE" in fcgiRequest.args);
				if(c) { request.cookies = parseCookies(*c); }
				
				auto ip = ("REMOTE_ADDR" in fcgiRequest.args);
				if(ip) { request.ip = *ip; }
				
				// Run appMain
				
				appMain(request);
				
				// Begin sending output client
				
				auto output = fcgiRequest.stdout;
				
				//output.reset;
				
				foreach(cookie; session.cookies)
 					cookie.produce(cast(void delegate(void[]))&output.write);
				
				//res.render(cast(void delegate(void[]))&output.write);
				
				output.write("Content-type: ");
				output.write(res.contentType);
				output.write("\r\n\r\n");
				output.write(res.res);
				
				output.flush;
				
				// Done processing request
				
				fcgiRequest.exitStatus = 0;
				
				version(SenderoBenchmark) {
					auto renderTime = st.stop;
					log.format("Sendero Render Time:{}ms Url:{}", renderTime * 1000, url);
					//benchmarkOut.formatln("Sendero Render Time:{}ms, Url:{}, Method:{}", renderTime * 1000, url, *rm);
				}
			}
			catch(Exception ex)
			{
				auto stdout = fcgiRequest.stdout;
				
				void defaultErrorMsg(Exception ex)
				{
					stdout.write("Content-type: text/html\r\n\r\n");		
					//debug stdout.write("Sendero error: " ~ ex.toString ~ "\n" ~ ex.info.toString);
					debug {
						stdout.write("Sendero error: " ~ ex.toString ~ "\n");
						if(ex.file.length) {
							stdout.write("File: " ~ ex.file ~ " Line: " ~Int.toString(ex.line));
						}
						try
						{
							if(ex.info !is null) stdout.write("\nTrace: " ~ ex.info.toString);
							//TODO use cn.kuehne.flectioned
							auto next = ex.next;
							while(next) {
								stdout.write(" Exception:" ~ next.toString);
								next = next.next; 
							}
							
							//debug(SenderoRuntime) stdout.write(dumpAddresses);
						}
						catch(Exception ex2)
						{
							stdout.write(" Error tracing exception:" ~ ex2.toString); 
						}
					}					
					else stdout.write("Error");
					
					debug(SenderoDebugFCGIVars) {
						stdout.write("<br /><br /><h1>FCGI Variables:</h1>");
						foreach(k, v; fcgiRequest.args)
						{
							stdout.write(k ~ " = " ~ v ~ "<br />");
						}						
					}
				}
				
				if(errorHandler) {
					try
					{
						errorHandler(request);
						stdout.write("Content-type: text/html\r\n\r\n");
						stdout.write(res.res);
					}
					catch(Exception ex2)
					{
						defaultErrorMsg(ex2);
					}
				}
				else {
					defaultErrorMsg(ex);
				}
				log.error ("Exception caught" ~ ex.toString);
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