module sendero.server.responder.TcpServer;

import sendero.server.model.IEventDispatcher;
import sendero.server.model.ITcpServiceProvider;
import sendero.util.BufferProvider;

import tango.net.Socket;
import tango.net.SocketConduit;
import tango.net.InternetAddress;
import tango.stdc.errno;

import tango.util.log.Log;
Logger log;

static this()
{
	log = Log.lookup("sendero.server.provider.TcpServer");
}

class TcpConnection : EventResponder, ITcpCompletionPort
{
	this(SocketConduit socket, TcpServer server, IEventDispatcher dispatcher, ITcpServiceProvider serviceProvider)
	{
		assert(socket !is null);
		assert(server !is null);
		assert(dispatcher !is null);
		assert(serviceProvider !is null);
		this.socket_ = socket;
		this.server_ = server;
		this.dispatcher_ = dispatcher;
		this.serviceProvider_ = serviceProvider;
	}
	private SocketConduit socket_;
	private TcpServer server_;
	private IEventDispatcher dispatcher_;
	private ITcpServiceProvider serviceProvider_;
	private ITcpRequestHandler curReqHandler_ = null;
	private bool awatingWrite_ = false;
	private void[][] curResData_ = null;
	
	char[] toString()
	{
		return "TcpConnection";
	}
	
	void handleRead(ISyncEventDispatcher d)
	{
		if(curReqHandler_ is null)
			curReqHandler_ = serviceProvider_.getRequestHandler;
		
		auto buf = server_.bufferProvider.get;
    	uint readLen = socket_.socket.receive(buf);
    	if(readLen > 0) {
    		//Data Read
    		curReqHandler_.handleData([buf[0..readLen]]);
    		if(readLen == buf.length) {
    			//Probably have more data
    			//TODO use readv
    			handleRead(d);
    		}
    		else {
    			curReqHandler_.processRequest(this);
    		}
    	}
    	else if(readLen == 0) {
    		//Socket Disconnected
    		log.info("Socket {} disconnected on read", toString);
    		d.unregister(socket_);
    	}
    	else /* readLen < 0 */ {
    		//Socket Error
    		auto err = lastError;
    		switch(err)
    		{
    		case EAGAIN:
    		//case EWOULDBLOCK:
    			curReqHandler_.processRequest(this);
    			break;
    		default:
    			log.info("Socket error {} on read for socket {}", err, toString);
    			d.unregister(socket_);
    			break;
    		}
    	}
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
    
    void keepReading()
    {
    	dispatcher_.postTask((ISyncEventDispatcher d){
    		d.register(socket_,Event.Read,this);
    	});
    }
    
	void sendResponseData(void[][] data)
	{
		curReqHandler_ = null;
		curResData_ ~= data;
		if(!awatingWrite_) {
			dispatcher_.postTask((ISyncEventDispatcher d){
	    		d.register(socket_,Event.Write,this);
	    	});
			awatingWrite_ = true;
		}
	}
	
	void endResponse(bool keepAlive = true)
	{
		if(keepAlive) {
			dispatcher_.postTask((ISyncEventDispatcher d){
	    		d.register(socket_,Event.Read,this);
	    	});
		}
		else {
			dispatcher_.postTask((ISyncEventDispatcher d){
	    		d.unregister(socket_);
	    	});
		}
	}
}

class TcpServer : EventResponder
{
	this(ITcpServiceProvider serviceProvider, InternetAddress bindAddr = null, uint listen = 1000)
	{
		this.serviceProvider_ = serviceProvider;
		this.bindAddr_ = bindAddr;
		if(this.bindAddr_ is null)
			this.bindAddr_ = new InternetAddress("127.0.0.1", 8081);
		this.listen_ = 1000;
		bufferProvider_ = new BufferProvider;
	}
	
	private ITcpServiceProvider serviceProvider_;
	private SocketConduit serverSock_;
	private InternetAddress bindAddr_;
	private uint listen_;
	private IEventDispatcher dispatcher_;
	private BufferProvider bufferProvider_;
	
	BufferProvider bufferProvider() { return bufferProvider_; }
	
	void start(IEventDispatcher dispatcher)
	{
		this.dispatcher_ = dispatcher;
		dispatcher_.postTask(&startDg);
	}
	
	private void startDg(ISyncEventDispatcher dispatcher)
	{
		serverSock_ = new SocketConduit;
		serverSock_.socket.setAddressReuse(true);
		serverSock_.socket.blocking = false;
		serverSock_.bind(bindAddr_);
		serverSock_.socket.listen(listen_);
		log.info("Listening on {}:{}", bindAddr_.toAddrString, bindAddr_.toPortString);
		
		dispatcher.register(serverSock_,Event.Read,this);
	}
	
	char[] toString()
	{
		return "TcpServer";
	}
	
	void handleRead(ISyncEventDispatcher dispatcher)
	{
		auto newSock = new SocketConduit;
		serverSock_.socket.accept(newSock.socket);
		newSock.socket.blocking = false;
		auto responder = new TcpConnection(newSock, this, dispatcher_, serviceProvider_);
		dispatcher.register(newSock, Event.Read, responder);
	}
	
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
}