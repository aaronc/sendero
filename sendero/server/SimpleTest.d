module sendero.server.SimpleTest;

import sendero.server.WorkerPool;
import sendero.server.Http11;
import sendero.server.Packet;

import tango.io.Stdout;
import tango.net.InternetAddress;
import tango.net.Socket, tango.net.SocketConduit, tango.io.selector.Selector;
import tango.core.Thread;
import tango.io.Stdout;
import Int = tango.text.convert.Integer;

import tango.util.log.Config;
import tango.util.log.Log;

Logger log;

static this()
{
	log = Log.lookup("sendero.server.SimpleTest");
}

class SenderoResponder : IResponder
{
	void setContentType(char[] contentType)
	{
		contentType_ = contentType;
	}
	
	void write(void[] val)
	{
		res ~= val;
	}
	
	void setCookie(char[] name, char[] value)
	{
		
	}
	
	void setCookie(Cookie cookie)
	{
		
	}
	
private:
	void[] res;
	char[] contentType_ = Mime.TextHtml;
}

class SimpleService
{
	this(void function(Request req) appMain, ISelector selector)
	{
		this.selector = selector;
		this.appMain = appMain;
	}
	
	void run(Packet p)
	{
		try
		{
			log.info("Running job");

			auto req = new Request;
			auto status = parse(p.data, req);	

			auto res = new SenderoResponder;
			req.setResponder(res);
			
			appMain(req);
			//char[] res = "Hello world!";			
			
			if(status.code < 300) {
				log.info("Ready to write");
				p.cond.write("HTTP/1.x 200 OK\r\n");
				p.cond.write("Content-Type: "~ res.contentType_ ~"\r\n");
				p.cond.write("Content-Length: " ~ Int.toString(res.res.length) ~ "\r\n");
				p.cond.write("\r\n");
				p.cond.write(res.res);
				log.info("Done writing");
			}
			else {
				p.cond.write("HTTP/1.x " ~ Int.toString(status.code) ~ " " ~ status.name ~ "\r\n");
				p.cond.write("\r\n");
			}
		}
		catch(Exception ex)
		{
			if(ex.info !is null) {
				log.error("Exception caught:{}. Trace: {}", ex.toString, ex.info.toString);
			}
			else {
				log.error("Exception caught:{}", ex.toString);
			}
		}
	}
	
private:
	ISelector selector;
	void function(Request req) appMain;
}

void run(void function(Request req) appMain)
{
	auto serverLog = Log.lookup("sendero.server.SimpleTest.run");
	
	auto serverSock = new SocketConduit;
	serverSock.socket.setAddressReuse(true);
	serverSock.socket.blocking = false;
	serverSock.bind(new InternetAddress("127.0.0.1", 8081));
	serverSock.socket.listen(1000);
	
	serverLog.info("Listening on 127.0.0.1:8081");

	auto selector = new Selector;
	selector.open(100, 10);
	selector.register(serverSock, Event.Read);
	
	auto service = new SimpleService(appMain, selector);
	auto workerPool = new WorkerPool!(Packet)(&service.run);
	
	auto readBuffer = new char[8192];

	while(true) {
		try
		{
			auto eventCnt = selector.select(0.01);
			if(eventCnt > 0) {
				foreach(key; selector.selectedSet) {
					auto cond = cast(SocketConduit)key.conduit;
					assert(cond !is null);
					if(cond.fileHandle == serverSock.fileHandle)
					{
						auto newCond = new SocketConduit;
						serverSock.socket.accept(newCond.socket);
						selector.register(newCond, Event.Read, null);
						log.info("Accepted new connection");
						selector.reregister(serverSock, Event.Read, null);
					}
					else {
						if(key.isReadable)
						{
							//serverLog.info("Received read event");
							
							auto read = cond.read(readBuffer);
							
							if(read != IConduit.Eof) {
								auto p = new Packet(cond, readBuffer[0 .. read]);
								workerPool.pushJob(p);
								
							}
							else {
								if(!cond.isAlive) {
									cond.shutdown;
									cond.close;
									selector.unregister(cond);
								}
								else cond.setTimeout(.5);
							}
							//selector.unregister(cond);
						}
						
						assert(!key.isError);
					}
				}
			}
		}
		catch(Exception ex)
		{
			if(ex.info !is null) {
				serverLog.error("Exception caught:{}. Trace: {}", ex.toString, ex.info.toString);
			}
			else {
				serverLog.error("Exception caught:{}", ex.toString);
			}
		}
	}

	selector.close;
}