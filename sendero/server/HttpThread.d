module sendero.server.HttpThread;

import tango.util.log.Log;
import tango.util.log.Configurator;
import tango.text.convert.Sprint;
import tango.net.SocketConduit;
import tango.io.selector.model.ISelector;
import tango.io.model.IConduit;
import tango.core.Thread;
import tango.core.Exception;
import sendero.server.HttpBridge;
import sendero.util.http.HttpProvider;
import sendero.util.WorkQueue;



template safecall(char[] handler)
{
	const char[] safecall = "if (" ~ handler ~ ")" ~
		handler ~ "(key);";
}

alias WorkQueue!(SelectionKey) SocketQueue;
typedef bool delegate(SelectionKey) Handler;

class HttpThread : Thread 
{
	HttpBridge bridge;
	SocketQueue wqueue;
	Logger logger;
	Sprint!(char) sprint;
	this (SocketQueue wq)
	{
		sprint = new Sprint!(char);
		wqueue = wq;
		logger = Log.getLogger("HttpThread");
		bridge = new HttpBridge (provider, this);
		super(&run);
	}

	private
	void run() 
	{
		auto sprint = new Sprint!(char);
		//logger.info("Starting thread");
		while(true)
		{
			//WorkQueue is built for threaded access and will block on empty
			//so this thread simply needs to request a task and will block(sleep)
			//until one becomes available
			SelectionKey key = wqueue.popFront();
			SocketConduit sock = cast(SocketConduit) key.conduit();
			task_handler(key);
		}
	}

	void task_handler(SelectionKey key)
	{
		//while(1) <-- for edge triggered: we might have received another request, should
		//process all possible data before returning the socket because it will ignore 
		//any data left there
		SocketConduit cond = cast(SocketConduit) key.conduit();	
		try
		{
				logger.info(sprint("crossing handle {0} - id {1}", 
										cond.fileHandle(), key._id)); 
				bridge.cross(cond);
		}
		catch(IOException e)
		{
			logger.error(sprint("Thread: {0}, Sock: {1}, IOException: {2}", 
										 Thread.getThis.name(), cond.fileHandle(), e.toUtf8));
		}
		catch(TracedException e)
		{
			logger.error(sprint("Thread: {0}, Sock: {1}, TracedException: {2}", 
										 Thread.getThis.name(), cond.fileHandle(), e.toUtf8));

		}
		catch(Exception e)
		{
			logger.error(sprint("Thread: {0}, Sock: {1}, Exception: {2}", 
										 Thread.getThis.name(), cond.fileHandle(), e.toUtf8));
		}
		mixin(safecall!("after_response_write"));
	}

	public 
	static void register_before_request_read(Handler h)
	{
		before_request_read = h;
	}
	static void register_after_request_read(Handler h)
	{
		after_request_read = h;
	}
	static void register_before_response_write(Handler h)
	{
		before_response_write = h;
	}
	static void register_after_response_write(Handler h)
	{
		after_response_write = h;
	}

	static void set_providerfactory(ProviderFactory p)
	{
		pfactory = p;
		provider = p.create();
	}
	static void set_provider(HttpProvider p)
	{
		provider = p;
	}
	private
	static Handler before_request_read;
	static Handler after_request_read;
	static Handler before_response_write;
  static Handler after_response_write;
  static HttpProvider provider;
	static ProviderFactory pfactory;
}

