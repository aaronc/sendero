module sendero.server.Server;

interface IServiceProvider
{
	void handleConnect(SocketConduit cond, Selector selector);
}

interface IResponder
{
	void handler(Packet packet);
}

abstract class ServiceProvider : IServiceProvider, IResponder
{
	void handleConnect(SocketConduit cond, Selector selector)
	{
		auto newCond = new SocketConduit;
		serverSock.socket.accept(newCond.socket);
		selector.register(newCond, Event.Read, getResponder);
	}
	
	protected IResponder getResponder()
	{
		
	}
}

class SenderoServer
{
	static this()
	{
		serverLog = Log.lookup("sendero.server.Server.main");
	}
	static Logger serverLog;
	
	this()
	{
		auto selector = new Selector;
		selector.open(100, 10);
	}
	
	void addServiceProvider(InternetAddress addr, IServiceProvider service)
	{
		auto serverSock = new SocketConduit;
		serverSock.socket.setAddressReuse(true);
		serverSock.bind(new InternetAddress("127.0.0.1", 8081));
		serverSock.socket.listen(1000);
		selector.register(serverSock, Event.Read, service);
	}
	
	void run()
	{
		
		//auto service = new SimpleService(selector);
		auto service = new SenderoService(selector, "../../practivist/practivist_main.lib");
		auto workerPool = new WorkerPool!(Packet_)(&service.run);
		
		auto readBuffer = new char[8192];

		while(true) {
			try
			{
				auto eventCnt = selector.select(0.01);
				if(eventCnt > 0) {
					foreach(key; selector.selectedSet) {
						auto cond = cast(SocketConduit)key.conduit;
						assert(cond !is null);
						if(is(typeof(key.attachment) : IServiceProvider))
						{
							auto provider = cast(IServiceProvider)key.attachment;
							provider.handleConnect(cond, selector);
							selector.reregister(cond, Event.Read, provider);
						}
						else {
							if(key.isReadable)
							{
								//serverLog.info("Received read event");
								
								auto read = cond.read(readBuffer);
								
								if(read != IConduit.Eof) {
									auto p = new Packet(cond, readBuffer[0 .. read]);
									workerPool.pushJob(p);
									
								}
								else {
									if(!cond.isAlive) {
										cond.shutdown;
										cond.close;
										selector.unregister(cond);
									}
									else cond.setTimeout(.5);
								}
								//selector.unregister(cond);
							}
							
							assert(!key.isError);
						}
					}
				}
			}
			catch(Exception ex)
			{
				if(ex.info !is null) {
					serverLog.error("Exception caught:{}. Trace: {}", ex.toString, ex.info.toString);
				}
				else {
					serverLog.error("Exception caught:{}", ex.toString);
				}
			}
		}

		selector.close;
	}
}