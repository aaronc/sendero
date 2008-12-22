//import qcf.reflectioned;

import sendero.server.EventDispatcher;
import sendero.server.runtime.SafeRuntime;
//import sendero.server.SimpleTest;
import sendero.server.responder.TcpServer;
import sendero.server.WorkerPool;
import sendero.server.http.Http11Parser;
import sendero.server.provider.WorkerPoolTcpServiceProvider;
import sendero.server.runtime.StackTrace;
//import sendero.server.TimerDispatcher;
import sendero.server.runtime.HeartBeat;

import Int = tango.text.convert.Integer;
import tango.stdc.stdlib;
import tango.stdc.errno;
import tango.sys.Process;

debug import tango.util.log.Config;

version(Windows) {}
else {
import tango.stdc.posix.unistd;
}

import tango.core.Thread;

static this()
{
	Symbol.loadObjDumpSymbols("test_server.symbols");
}

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

class Server
{
	this()
	{
		dispatcher = new EventDispatcher;
		auto runtime = new SafeRuntime(dispatcher);
		//auto timer = new TimerDispatcher(dispatcher);
		dispatcher.open(100,10);
		pool = new WorkerPool;
		pool.start(1);
		auto heartbeatThr = new HeartBeatThread(&heartbeat);
		heartbeatThr.start;
		//pool.setHeartbeat(timer);
		auto server = new TcpServer(new WorkerPoolTcpServiceProvider(new TestProvider, pool));
		server.start(dispatcher);
		dispatcher.run;
	}
	EventDispatcher dispatcher;
	WorkerPool pool;
	
	void startFork()
	{
version(Windows) {}
else {
		pid_t pid;
		pid = fork();
		if(pid == 0)
		{
			auto server = new Server;
			exit(0);
		}
		else if(pid > 0)
		{
			Stdout.formatln("Fprking server daemon");
			exit(0);
		}
		else
		{
			//Error Forking
			Stdout.formatln("Unable to create server daemon, errno {}", errno);
			exit(-1);
		}
}
	}
	
	void heartbeat()
	{
		pool.ensureAlive;
	}
}

int serverMain(char[][] args)
{
	auto server = new Server;
	return 0;
}

int start_server(char[][] args)
{
version(Windows) {return serverMain(args);}
else {
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
