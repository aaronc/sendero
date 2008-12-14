import qcf.reflectioned;

import sendero.server.EventDispatcher;
import sendero.server.runtime.SafeRuntime;
//import sendero.server.SimpleTest;
import sendero.server.responder.TcpServer;
import sendero.server.WorkerPool;
import sendero.server.http.Http11Parser;
import sendero.server.provider.WorkerPoolTcpServiceProvider;

import Int = tango.text.convert.Integer;
import tango.util.log.Config;
import tango.stdc.stdlib;
import tango.stdc.posix.unistd;
import tango.stdc.errno;
import tango.sys.Process;

import tango.core.Thread;

class TestProvider : ITcpServiceProvider
{
	ITcpRequestHandler getRequestHandler()
	{
		return new TestRequestHandler;
	}
	
	void cleanup(ITcpRequestHandler handler)
	{
		delete handler;
	}
}

class TestRequestHandler : ITcpRequestHandler
{
	SyncTcpResponse handleRequest(void[][] data, ITcpCompletionPort completionPort)
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
}

import tango.io.Stdout;

int serverMain(char[][] args)
{
	auto dispatcher = new EventDispatcher;
	auto runtime = new SafeRuntime(dispatcher);
	dispatcher.open(100,10);
	auto server = new TcpServer(new WorkerPoolTcpServiceProvider(new TestProvider));
	server.start(dispatcher);
	dispatcher.run;
	return 0;
}

int start_server(char[][] args)
{
	//	 Daemonize
	pid_t pid;
	pid = fork();
	if(pid == 0)
	{
		//Child Process
		return serverMain(args);
	}
	else if(pid > 0)
	{
		//Parent Process
		Stdout.formatln("Starting server daemon");
		return 0;
	}
	else
	{
		//Error Forking
		Stdout.formatln("Unable to create server daemon, errno {}", errno);
		return -1;
	}
}
	
int stop_server(char[][] args)
{
	auto proc = new Process("killall","-2",args[0]);
	proc.execute;
	auto res = proc.wait;
	if(res.status != 0) Stdout.formatln("Unable to stop server");
	return res.status;
}

int main(char[][] args)
{
	Stdout.formatln("Server Server Version {}.{}.{}",0,0,0);
	
	if(args.length > 1)
	{
		switch(args[1])
		{
		case "start":
			return start_server(args);
			break;
		case "stop":
			return stop_server(args);
			break;
		default:
			Stdout.formatln("Unknown action {}", args[1]);
			break;
		}
	}
	
	return serverMain(args);
}
