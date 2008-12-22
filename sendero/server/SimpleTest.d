module sendero.server.SimpleTest;

import sendero.server.WorkerPool;
import sendero.server.Http11;
import sendero.server.Packet;
import sendero.util.collection.ThreadSafeQueue;

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
	this(void function(Request req) appMain, ThreadSafeQueue!(Packet) responseQueue)
	{
		this.appMain = appMain;
		this.responseQueue = responseQueue;
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
				p.write("HTTP/1.x 200 OK\r\n");
				p.write("Content-Type: "~ res.contentType_ ~"\r\n");
				p.write("Content-Length: " ~ Int.toString(res.res.length) ~ "\r\n");
				p.write("\r\n");
				p.write(res.res);
				log.info("Done writing");
			}
			else {
				p.write("HTTP/1.x " ~ Int.toString(status.code) ~ " " ~ status.name ~ "\r\n");
				p.write("\r\n");
			}
			
			responseQueue.push(p);
		}
		catch(Exception ex)
		{
			if(ex.info !is null) {
				log.error("Exception caught:{}. Trace: {}", ex.toString, ex.info.toString);
			}
			else {
				log.error("Exception caught:{}", ex.toString);
			}
			
			p.write("HTTP/1.x 400 Bad Request\r\n");
			p.write("Content-Type: text/html\r\n");
			
			char[] err = "<h1>Bad request</h1>\r\n";
			
			debug {
				
				err ~= "<h2>Exception caught</h2><p>" ~ ex.toString ~ ".</p>";
				if(ex.info !is null) {
					err ~= "<p> Trace: " ~ ex.info.toString ~ "</p>";
				}
				
				err ~= "<p><em>Sendero Server</em></p>";
			}
			
			p.write("Content-Length: " ~ Int.toString(err.length) ~ "\r\n");
			p.write("\r\n");
			p.write(err);
			
			responseQueue.push(p);
		}
	}
	
private:
	void function(Request req) appMain;
	ThreadSafeQueue!(Packet) responseQueue;
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
	
	auto responseQueue = new ThreadSafeQueue!(Packet);
	auto service = new SimpleService(appMain, responseQueue);
	auto workerPool = new JobWorkerPool!(Packet)(&service.run);
	
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
						//selector.reregister(serverSock, Event.Read, null);
						selector.register(serverSock, Event.Read, null);
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
						else if(key.isWritable)
						{
							serverLog.info("Writing response");
							auto packet = cast(Packet)key.attachment;
							assert(packet !is null);
							packet.cond.write(packet.res);
							//selector.reregister(packet.cond, Event.Read, null);
							selector.register(serverSock, Event.Read, null);
						}
						
						assert(!key.isError);
					}
				}
			}
			
			auto response = responseQueue.pop;
			while(response !is null) {
				serverLog.info("Pushing response object");
				//selector.reregister(response.cond, Event.Write, response);
				selector.register(response.cond, Event.Write, response);
				response = responseQueue.pop;
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