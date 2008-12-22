module sendero.server.responder.TcpServer;

public import sendero.server.model.ITcpServiceProvider;

import sendero.server.model.IEventDispatcher;
import sendero.util.BufferProvider;
import sendero.util.collection.ThreadSafeQueue;

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
		this.curResData_ = new ThreadSafeQueue!(void[]);
	}
	private SocketConduit socket_;
	private TcpServer server_;
	private IEventDispatcher dispatcher_;
	private ITcpServiceProvider serviceProvider_;
	private ITcpRequestHandler curReqHandler_ = null;
	private bool awatingWrite_ = false;
	private ThreadSafeQueue!(void[]) curResData_;
	private void[] unsentBuffer_ = null;
	private void[][] readBuffers_ = null;
	private bool endOfResponse_ = false;
	private bool keepAlive_ = true;
	
	char[] toString()
	{
		//return "TcpConnection:" ~ socket_.socket.remoteAddress.toString;
		return "TcpConnection";
	}
	
	private void doHandleRead(ISyncEventDispatcher dispatcher, void[][] existingData = null)
	{
		debug log.trace("doHandleRead");
		
		if(curReqHandler_ is null)
			curReqHandler_ = serviceProvider_.getRequestHandler;
		
		auto buf = server_.bufferProvider.get;
		
    	uint readLen = socket_.socket.receive(buf);
    	if(readLen > 0) {
    		//Data Read
    		readBuffers_ ~= buf;
    		existingData ~= buf[0..readLen];
    		//curReqHandler_.handleData([buf[0..readLen]]);
    		if(readLen == buf.length) {
    			//Probably have more data
    			//TODO use readv
    			doHandleRead(dispatcher, existingData);
    		}
    		else {
    			checkForSyncResponse(curReqHandler_.handleRequest(existingData, this));
    		}
    	}
    	else if(readLen == 0) {
    		server_.bufferProvider.release(buf);
    		//Socket Disconnected
    		log.info("Socket {} disconnected on read", toString);
    		dispatcher.unregister(socket_);
    	}
    	else /* readLen < 0 */ {
    		server_.bufferProvider.release(buf);
    		//Socket Error
    		auto err = lastError;
    		switch(err)
    		{
    		case EAGAIN:
    		//case EWOULDBLOCK:
    			checkForSyncResponse(curReqHandler_.handleRequest(existingData, this));
    			return;
    		case EINTR:
    			doHandleRead(dispatcher);
    			return;
    		default:
    			log.error("Socket error {} on read for socket {}", err, toString);
    			dispatcher.unregister(socket_);
    			return;
    		}
    	}
	}
	
	void handleRead(ISyncEventDispatcher dispatcher)
	{
		doHandleRead(dispatcher);
	}
	
	private void checkForSyncResponse(SyncTcpResponse res)
	{
		if(res !is null) {
			debug log.trace("Received sync response");
			sendResponseData(res.data);
			endResponse(res.keepAlive);
		}
	}
    
    void handleWrite(ISyncEventDispatcher dispatcher)
    {
    	//TODO user sendv
    	void[] buf;
    	if(unsentBuffer_.length) {
    		buf = unsentBuffer_;
    		unsentBuffer_ = null;
    	}
    	else buf = curResData_.pop;
    	
    	while(buf.length) {
	    	auto sentLen = socket_.socket.send(buf);
	    	if(sentLen > 0) {
	    		if(sentLen != buf.length) {
	    			log.error("sentLen ~= buf.length for {}", toString);
	    			dispatcher.unregister(socket_);
	    			return;
	    		}
	    	}
	    	else /* sentLen <= 0 */ {
	    		//Socket Error
	    		auto err = lastError;
	    		switch(err)
	    		{
	    		case EAGAIN:
	    		//case EWOULDBLOCK:
	    			unsentBuffer_ = buf;
	    			dispatcher.register(socket_, Event.Write, this);
	    			return;
	    		case EINTR:
	    			unsentBuffer_ = buf;
	    			handleWrite(dispatcher);
	    			return;
	    		version(Win32) {}
	    		else {
	    		case EMSGSIZE:
	    			log.error("Msgsize to big for socket {}", toString);
	    		}
	    		default:
	    			log.error("Socket error {} on write for socket {}", err, toString);
	    			dispatcher.unregister(socket_);
	    			return;
	    		}
	    	}
	    	buf = curResData_.pop;
    	}
    	
    	if(endOfResponse_) finishResponse;
    }
    
    private void finishResponse()
    {
    	endOfResponse_ = false;
    	
    	debug assert(!curResData_.pop.length && !unsentBuffer_.length,
    	             "Response being finished before all data is sent");
    	
    	serviceProvider_.cleanup(curReqHandler_);
    	curReqHandler_ = null;
    	
    	foreach(buf; readBuffers_)
		{
			server_.bufferProvider.release(buf);
		}
		readBuffers_ = null;
		
		if(keepAlive_) {
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
    
    void handleDisconnect(ISyncEventDispatcher dispatcher)
    {
    	debug log.info("Socket {} disconnected", toString);
    	dispatcher.unregister(socket_);
    }
    
    void handleError(ISyncEventDispatcher dispatcher)
    {
    	log.info("Error in socket {}", toString);
    	dispatcher.unregister(socket_);
    }
    
    void keepReading()
    {
    	dispatcher_.postTask((ISyncEventDispatcher dispatcher){
    		dispatcher.register(socket_,Event.Read,this);
    	});
    }
    
    private void registerWriteEventTask(ISyncEventDispatcher d){
		d.register(socket_,Event.Write,this);
	}
    
	void sendResponseData(void[][] data)
	{
		foreach(buf;data)
			curResData_.push(buf);
		if(!awatingWrite_) {
			dispatcher_.postTask(&registerWriteEventTask);
			awatingWrite_ = true;
		}
	}
	
	void endResponse(bool keepAlive = true)
	{
		endOfResponse_ = true;
		keepAlive_ = keepAlive;
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
		this.listen_ = listen;
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
		debug log.trace("Starting");
		this.dispatcher_ = dispatcher;
		dispatcher_.postTask(&startDg);
		debug log.trace("Done posting");
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
		log.info("Accepted new connection from {}", newSock.socket.remoteAddress.toString);
		dispatcher.register(newSock, Event.Read, responder);
	}
	
    void handleWrite(ISyncEventDispatcher dispatcher)
    {
    	log.warn("Unexpected write event on server socket");
    }
    
    void handleDisconnect(ISyncEventDispatcher dispatcher)
    {
    	log.warn("Server socket disconnected");
    	dispatcher.unregister(serverSock_);
    }
    
    void handleError(ISyncEventDispatcher dispatcher)
    {
    	log.error("Error in server socket");
    	dispatcher.unregister(serverSock_);
    }
}