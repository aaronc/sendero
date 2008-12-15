module sendero.server.Server;

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

class SenderoAppServer
{
	this()
	{
		
	}
	
	void run()
	{
		auto dispatcher = new EventDispatcher;
		auto runtime = new SafeRuntime(dispatcher);
		dispatcher.open(100,10);
		auto server = new TcpServer(new WorkerPoolTcpServiceProvider(new TestProvider));
		server.start(dispatcher);
		dispatcher.run;
		return 0;
	}
}