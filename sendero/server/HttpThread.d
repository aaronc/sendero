module sendero.server.HttpThread;

import tango.util.log.Log;
import tango.util.log.Configurator;
import tango.text.convert.Sprint;
import tango.net.SocketConduit;
import tango.io.model.IConduit;
import tango.core.Thread;
import tango.core.Exception;
import sendero.server.HttpBridge;
import sendero.util.http.HttpProvider;
import sendero.util.WorkQueue;



template safecall(char[] handler)
{
	const char[] safecall = "if (" ~ handler ~ ")" ~
		handler ~ "(cond);";
}

alias WorkQueue!(SocketConduit) SocketQueue;
typedef bool delegate(SocketConduit) Handler;

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
		bridge = new HttpBridge (pfactory.create(), this);
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
			SocketConduit sock = wqueue.popFront();
			logger.info(sprint("Thread: {0}, Sock {1} popped task size - {2}",
					 				Thread.getThis().name(), sock.fileHandle(), wqueue.size()));
			try
			{
				task_handler(sock);
			}
			catch(IOException e)
			{
				logger.error(sprint("Thread: {0}, Sock: {1}, IOException: {2}", 
										 Thread.getThis.name(), sock.fileHandle(), e.toUtf8));
			}
			catch(TracedException e)
			{
				logger.error(sprint("Thread: {0}, Sock: {1}, TracedException: {2}", 
										 Thread.getThis.name(), sock.fileHandle(), e.toUtf8));

			}
			catch(Exception e)
			{
				logger.error(sprint("Thread: {0}, Sock: {1}, Exception: {2}", 
										 Thread.getThis.name(), sock.fileHandle(), e.toUtf8));

			}
		}
	}

	void task_handler(SocketConduit cond)
	{
		//while(1) <-- for edge triggered: we might have received another request, should
		//process all possible data before returning the socket because it will ignore 
		//any data left there
			while (cond.isAlive())
				bridge.cross(cond);

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
	}
	private
	static Handler before_request_read;
	static Handler after_request_read;
	static Handler before_response_write;
  static Handler after_response_write;
  static ProviderFactory pfactory;
}

