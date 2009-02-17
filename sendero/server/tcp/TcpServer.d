module sendero.server.tcp.TcpServer;

public import sendero.server.tcp.model.ITcpServiceProvider;

import sendero.server.model.IEventDispatcher;
//import sendero.util.BufferProvider;
import sendero.util.collection.ThreadSafeQueue;
import sendero.server.io.StagedReadBuffer;
import sendero.server.io.SingleThreadCachedBuffer;
import sendero.server.io.model.ICachedBuffer;


alias StagedReadBufferPool ReadBufferProviderT;
alias SingleThreadBufferPool WriteBufferProviderT;

alias ReadBufferProviderT.BufferT ReadBufferT;
alias WriteBufferProviderT.BufferT WriteBufferT;

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

class TcpConnection : EventResponder, IAsyncTcpConduit
{
	this(SocketConduit socket, TcpServer server, IEventDispatcher dispatcher, ITcpServiceProvider serviceProvider)
	{
		assert(socket !is null);
		assert(server !is null);
		assert(dispatcher !is null);
		assert(serviceProvider !is null);
	/+	int True = 1;
		void[] TrueBuf = (cast(void*)&True)[0..4];
		void[] buf = new void[256];
		//socket.socket.setOption(SocketOptionLevel.SOCKET, SocketOption.SO_KEEPALIVE,TrueBuf);
		auto res = socket.socket.getOption(SocketOptionLevel.SOCKET, SocketOption.SO_KEEPALIVE,buf);
		debug log.trace("Socket option SO_KEEPALIVE = {}",buf[0..res]);+/
		this.socket_ = socket;
		this.remoteAddress_ = socket_.socket.remoteAddress.toString;
		this.server_ = server;
		this.dispatcher_ = dispatcher;
		this.serviceProvider_ = serviceProvider;
		//this.curResData_ = new ThreadSafeQueue!(void[]);
		this.writeBufferQueue_ = new ThreadSafeQueue!(ICachedBuffer);
	}
	private SocketConduit socket_;
	private char[] remoteAddress_;
	private TcpServer server_;
	private IEventDispatcher dispatcher_;
	private ITcpServiceProvider serviceProvider_;
	private ITcpRequestHandler curReqHandler_ = null;
	//private ThreadSafeQueue!(void[]) curResData_;
	//private void[] unsentBuffer_ = null;
	//private void[][] readBuffers_ = null;
	private StagedReadBuffer readBufferHead_ = null;
	private StagedReadBuffer readBufferCur_ = null;
	private SingleThreadCachedBuffer writeBuffer_ = null;
	private ICachedBuffer writeBufferCur_ = null;
	private ThreadSafeQueue!(ICachedBuffer) writeBufferQueue_;
	//private ICachedBuffer writeBufferHead_ = null;
	//private ICachedBuffer writeBufferTail_ = null;
	private TcpAction nextAction_ = TcpAction.None;
	private bool awatingWrite_ = false;
	private bool endOfResponse_ = false;
	private bool ready_ = false;
	private bool keepAlive_ = true;
	
	static const BlockTransferMax = 32768;
	
	char[] toString()
	{
		return "TcpConnection:" ~ remoteAddress_;
	}
	
	void handleRead(ISyncEventDispatcher dispatcher)
	{
		doHandleRead(dispatcher);
	}
	
	void doHandleRead(ISyncEventDispatcher dispatcher, ref size_t totalRead = 0) in {
		assert(readBufferHead_ !is null);
		assert(readBufferCur_ !is null);
	}
	body {
		debug log.trace("doHandleRead");
		
		if(curReqHandler_ is null)
			curReqHandler_ = serviceProvider_.getRequestHandler;
		
		/+if(readBufferHead_ is null) {
			auto buf = server_.bufferProvider.get;
			debug assert(buf.length);
			readBufferHead_ = new StagedReadBuffer(buf);
			readBufferCur_ = readBufferHead_;
			debug assert(readBufferCur_.writeable);
		}+/
		
		if(!readBufferCur_.writeable) {
			readBufferCur_.next = server_.readBufferProvider_.get;
			readBufferCur_ = readBufferCur_.next;
			readBufferCur_.next = null;
		}
		
		debug assert(readBufferCur_.writeable);
		
    	uint readLen = socket_.socket.receive(readBufferCur_.getWritable);
    	if(readLen > 0) {
    		//Data Read
    		readBufferCur_.advanceWritten(readLen);
    		totalRead += readLen;
    		if(totalRead_ >= BlockTransferMax) {
    			checkForSyncResponse(curReqHandler_.handleRequest(this));
    		}
    		else if(!readBufferCur_.writeable) {
    			//Probably have more data
    			//TODO use readv
    			doHandleRead(dispatcher, totalRead);
    		}
    		else {
    			checkForSyncResponse(curReqHandler_.handleRequest(this));
    		}
    	}
    	else if(readLen == 0) {
    		//Socket Disconnected
    		log.info("Socket {} disconnected on read", toString);
    		dispatcher.unregister(socket_);
    		socket_.detach;
    	}
    	else /* readLen < 0 */ {
    		//Socket Error
    		auto err = lastError;
    		switch(err)
    		{
    		case EAGAIN:
    		//case EWOULDBLOCK:
    			checkForSyncResponse(curReqHandler_.handleRequest(this));
    			return;
    		case EINTR:
    			doHandleRead(dispatcher, totalRead);
    			return;
    		default:
    			log.error("Socket error {} on read for socket {}", err, toString);
    			dispatcher.unregister(socket_);
    			socket_.detach;
    			return;
    		}
    	}
	}
	
	private void checkForSyncResponse(SyncTcpResponse res)
	{
		if(res !is null) {
			debug log.trace("Received sync response");
			/+sendResponseData(res.data);
			endResponse(res.keepAlive);+/
			assert(false, "TODO");
		}
	}
    
    void handleWrite(ISyncEventDispatcher dispatcher) in {
    	assert(writeBufferQueue_ !is null);
    }
    body {
    	assert(false, "TODO");
    	//TODO user sendv
    	void[] buf;
    	if(unsentBuffer_.length) {
    		buf = unsentBuffer_;
    		unsentBuffer_ = null;
    	}
    	else buf = curResData_.pull;
    	
    	while(buf.length) {
	    	auto sentLen = socket_.socket.send(buf);
	    	if(sentLen > 0) {
	    		if(sentLen != buf.length) {
	    			log.error("sentLen ~= buf.length for {}", toString);
	    			dispatcher.unregister(socket_);
	    			socket_.detach;
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
	    			socket_.detach;
	    			return;
	    		}
	    	}
	    	buf = curResData_.pull;
    	}
    	
    	if(endOfResponse_) finishResponse;
    	else awatingWrite_ = false;
    }
    
    private void reregisterReadDg(ISyncEventDispatcher dispatcher)
    {
    	debug assert(socket_ !is null);
    	debug assert(socket_.socket !is null);
    	if(socket_.socket !is null) {
    		dispatcher.register(socket_,Event.Read,this);
    	}
    }
    
    private void cleanupReadBuffers()
    {
    	readBufferCur_ = readBufferHead_;
    	while(readBufferCur_ !is null) {
    		server_.bufferProvider.release(readBufferCur_.getContent);
    		readBufferCur_ = readBufferHead_.next;
    	}
    	readBufferHead_ = null;
    }
    
    private void reregisterReadAndFinishResDg(ISyncEventDispatcher dispatcher)
    {
    	/+foreach(buf; readBuffers_)
		{
			server_.bufferProvider.release(buf);
		}
		readBuffers_ = null;+/
    	cleanupReadBuffers;
		
    	debug assert(socket_ !is null);
    	debug assert(socket_.socket !is null);
    	if(socket_.socket !is null) {
    		dispatcher.register(socket_,Event.Read,this);
    	}
    }
    
    private void unregisterSocketDg(ISyncEventDispatcher dispatcher)
    {
    	debug assert(socket_ !is null);
    	debug assert(socket_.socket !is null);
    	dispatcher.unregister(socket_);
		socket_.detach;
    }
    
    private void unregisterSocketAndFinishResDg(ISyncEventDispatcher dispatcher)
    {
    	cleanupReadBuffers;
		
    	debug assert(socket_ !is null);
    	debug assert(socket_.socket !is null);
    	dispatcher.unregister(socket_);
		socket_.detach;
    }
    
    private void finishResponse()
    {
    	endOfResponse_ = false;
    	
    	debug assert(!curResData_.pull.length && !unsentBuffer_.length,
    	             "Response being finished before all data is sent");
    	
    	serviceProvider_.cleanup(curReqHandler_);
    	curReqHandler_ = null;
    	awatingWrite_ = false;
    	
		if(keepAlive_) {
			dispatcher_.postTask(&reregisterReadAndFinishResDg);
		}
		else {
			dispatcher_.postTask(&unregisterSocketAndFinishResDg);
		}
    }
    
    void sendResponseData(TcpAction whenDone, void[][] data...)
    {
    	
    }
    
	void sendResponseData(TcpAction whenDone, ICachedBuffer data)
	{
		
	}
	
	StagedReadBuffer requestData()
	{
		return readBufferHead_;
	}
	
	CachedBuffer responseBuffer()
	{
		return writeBuffer_;
	}
    
    void handleDisconnect(ISyncEventDispatcher dispatcher)
    {
    	debug log.info("Socket {} disconnected", toString);
    	dispatcher.unregister(socket_);
		socket_.detach;
    }
    
    void handleError(ISyncEventDispatcher dispatcher)
    {
    	log.info("Error in socket {}", toString);
    	dispatcher.unregister(socket_);
    	socket_.detach;
    }
    
    void keepReading()
    {
    	if(ready_) dispatcher_.postTask(&handleRead);
    	else dispatcher_.postTask(&reregisterReadDg);
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
		//bufferProvider_ = new BufferQueueT;
	}
	
	private ITcpServiceProvider serviceProvider_;
	private SocketConduit serverSock_;
	private InternetAddress bindAddr_;
	private uint listen_;
	private IEventDispatcher dispatcher_;
	//private BufferQueueT bufferProvider_;
	private ReadBufferProviderT readBufferProvider_;
	private WriteBufferProviderT writeBufferProvider_;
	
	
	//BufferQueueT bufferProvider() { return bufferProvider_; }
	
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
    	serverSock_.close;
    }
    
    void handleError(ISyncEventDispatcher dispatcher)
    {
    	log.error("Error in server socket");
    	dispatcher.unregister(serverSock_);
    	serverSock_.close;
    }
}