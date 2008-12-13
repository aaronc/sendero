import sendero.server.EventDispatcher;
import sendero.server.SimpleTest;
import sendero.server.responder.TcpServer;

import Int = tango.text.convert.Integer;

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

int main(char[][] args)
{
	auto dispatcher = new EventDispatcher;
	dispatcher.open(100,10);
	auto server = new TcpServer(new TestProvider);
	server.start(dispatcher);
	dispatcher.run;
	return 0;
}
