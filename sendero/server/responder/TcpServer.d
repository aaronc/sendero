module sendero.server.responder.TcpServer;

import sendero.server.model.IEventDispatcher;
import sendero.server.model.Provider;

import tango.net.SocketConduit;
import tango.net.InternetAddress;

import tango.util.log.Log;
Logger log;

static this()
{
	log = Log.lookup("sendero.server.provider.TcpServer");
}

interface ITcpServiceProvider
{
	void handleRequest(void[] data, TcpConnection connection);
}

interface ITcpConnection
{
	void respond(void[][] response);
}

class SyncTcpConnection : ITaskResponder
{
	
}

class AsyncTcpConnection : ITaskResponder
{
	this(SocketConduit socket, ITcpServer server /* or IEventDispatcher??? */, ITcpServiceProvider serviceProvider)
	{
		this.socket = socket;
		//this.server = server;
		this.serviceProvider = serviceProvider;
	}
	private SocketConduit socket;
	//private ITcpServer server;
	private ITcpServiceProvider serviceProvider;
	
	char[] toString()
	{
		
	}
	
    void handleRead(ISyncEventDispatcher)
    {
    	//get read data
    	//serviceProvider.handleRequest(data, connection);
    }
    void handleWrite(ISyncEventDispatcher)
    {
    	// send response data
    	// clear response buffers
    	// register read event
    }
    
    void handleDisconnect(ISyncEventDispatcher)
    {
    	
    }
    
    void handleError(ISyncEventDispatcher)
    {
    	
    }
    
    void respond(void[][] response)
    {
    	// store response data
    	// post task for checking for write event
    }
}

interface ITcpServer
{
	void postTask(EventTaskDg taskDg);
}

private class SyncTcpServer :  TcpServer, ITaskResponder
{
	void handleRead(ISyncEventDispatcher dispatcher)
	{
		auto newCond = new SocketConduit;
		serverSock.socket.accept(newCond.socket);
		auto responder = new SyncTcpConnection(newCond);
		dispatcher.register(newCond, Event.Read, responder);
	}
}

private class AsyncTcpServer : TcpServer, ITaskResponder
{
	void handleRead(ISyncEventDispatcher dispatcher)
	{
		auto newCond = new SocketConduit;
		serverSock.socket.accept(newCond.socket);
		newCond.socket.blocking = false;
		auto responder = new AsyncTcpConnection(newCond);
		dispatcher.register(newCond, Event.Read, responder);
	}
}

abstract class TcpServer : ITcpServer
{
	static TcpServer create(IAsyncServiceProvider)
	{
		
	}
	
	static TcpServer create(ISyncServiceProvider)
	{
		
	}
	
	this(ITcpServiceProvider serviceProvider, InternetAddress bindAddr = null, uint listen = 1000)
	{
		this.provider = serviceProvider;
		this.bindAddr = bindAddr;
		if(this.bindAddr is null)
			this.bindAddr = new InternetAddress("127.0.0.1", 8081);
		this.listen = 1000;
	}
	
	private ITcpServiceProvider serviceProvider;
	private SocketConduit serverSock;
	private InternetAddress bindAddr;
	private uint listen;
	private IEventDispatcher dispatcher;
	
	void start(IEventDispatcher dispatcher)
	{
		this.dispatcher = dispatcher;
		dispatcher.postTask(&startDg);
	}
	
	private void startDg(ISyncEventDispatcher dispatcher)
	{
		serverSock = new SocketConduit;
		serverSock.socket.setAddressReuse(true);
		serverSock.socket.blocking = false;
		serverSock.bind(bindAddr);
		serverSock.socket.listen(n);
		serverLog.info("Listening on {}:{}", bindAddr.toAddrString, bindAddr.toPortString);
		
		dispatcher.register(serverSock,Event.Read,this);
	}
	
	abstract void handleRead(ISyncEventDispatcher);
	
    void handleWrite(ISyncEventDispatcher)
    {
    	//TODO
    }
    
    void handleDisconnect(ISyncEventDispatcher)
    {
    	//TODO
    }
    
    void handleError(ISyncEventDispatcher)
    {
    	//TODO
    }
    
    void respond(EventTaskDg responseDg)
    {
    	debug assert(dispatcher !is null);
    	dispatcher.postTask(responseDg);
    }
}