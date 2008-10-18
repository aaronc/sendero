module sendero.server.SenderoService;

import tango.net.SocketConduit, tango.io.selector.model.ISelector;
import Http11;
import sendero.http.Response;
import Int = tango.text.convert.Integer;
import DynamicServiceLoader;
import tango.core.Thread;
import Packet;
import tango.io.Stdout;

import tango.util.log.Log;

Logger log;

static this()
{
	log = Log.lookup("SenderoService");
}

alias void function(Req) SenderoResponderT;

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
	
private:
	void[] res;
	char[] contentType_ = TextHtml;
}

class SenderoService
{
	this(ISelector selector, SenderoResponderT senderoAppMain)
	{
		assert(selector);
		assert(senderoAppMain);
		this.selector = selector;
		this.senderoAppMain = senderoAppMain;
	}
	
	void loadSenderoAppMain()
	{
		this.senderoAppMain = DynamicServiceLoader_.getService!(SenderoResponderT, "main.senderoAppMain")(libFilePath);
	}
	
	void run(Packet_ p)
	{
		try
		{
			log.info("Running job");
			
			auto req = new Request;
			auto status = parse(p.data, req);
			
			assert(senderoAppMain !is null);
			auto res = new SenderoResponder;
			req.setResponder(res);
			
			senderoAppMain(req);
			
			log.info("Got response");
			
			if(status.code < 300) {
				log.info("Ready to write");
				p.cond.write("HTTP/1.x 200 OK\r\n");
				p.cond.write("Content-Type: " ~ res.contentType_ ~ "\r\n");
				p.cond.write("Content-Length: " ~ Int.toString(res.res.length) ~ "\r\n");
				p.cond.write("\r\n");
				//res.render(cast(void delegate(void[]))&p.cond.write);
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
	SenderoResponderT senderoAppMain;
	ISelector selector;
	char[] libFilePath;
}

class DynamicSenderoAppProvider
{
	this(char[] libFilePath)
	{
		this.libFilePath = libFilePath;
		loadSenderoAppMain;
		auto checker = new Thread(&appModificationChecker);
		checker.start;
	}
	
	void loadSenderoAppMain()
	{
		this.senderoAppMain = DynamicServiceLoader_.getService!(SenderoResponderT, "main.senderoAppMain")(libFilePath);
	}
	
private:
	char[] libFilePath;
	void appModificationChecker()
	{
		while(1) {
			Thread.sleep(.5);
			loadSenderoAppMain;
		}
	}
}
