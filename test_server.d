import qcf.reflectioned;

import sendero.server.EventDispatcher;
import sendero.server.runtime.SafeRuntime;
//import sendero.server.SimpleTest;
import sendero.server.responder.TcpServer;

import Int = tango.text.convert.Integer;

import tango.util.log.Config;

class TestProvider : ITcpServiceProvider
{
	ITcpRequestHandler getRequestHandler()
	{
		return new TestRequestHandler;
	}
}

class TestRequestHandler : ITcpRequestHandler
{
	void handleData(void[][] data)
	{
		
	}
	
	SyncTcpResponse processRequest(ITcpCompletionPort completionPort)
	{
		auto res = new SyncTcpResponse;
		char[] txt = "Hello Sendero Server World!\r\n";
		char[] resTxt = "HTTP/1.x 200 OK\r\n";
		resTxt ~= "Content-Type: text/html\r\n";
		resTxt ~= "Content-Length: " ~ Int.toString(txt.length) ~ "\r\n";
		resTxt ~= "\r\n";
		resTxt ~= txt;
		res.data ~= resTxt;
		return res;
	}
	
	void cleanup()
	{
		
	}
}

import tango.io.Stdout;

int main(char[][] args)
{
	auto dispatcher = new EventDispatcher;
	auto runtime = new SafeRuntime(dispatcher);
	dispatcher.open(100,10);
	auto server = new TcpServer(new TestProvider);
	Stdout.formatln("here");
	server.start(dispatcher);
	Stdout.formatln("here");
	dispatcher.run;
	return 0;
}
