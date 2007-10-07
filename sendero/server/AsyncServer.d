/**
 * Copyright: Copyright (C) 2007 Rick Richardson.  All rights reserved.
 * License:   BSD Style
 * Authors:   Rick Richardson
 */

module sendero.server.AsyncServer;

import tango.io.selector.EpollSelector;
import tango.sys.linux.epoll;
import tango.net.SocketConduit;
import tango.net.ServerSocket;
import tango.net.Socket;
import tango.net.InternetAddress;
import tango.io.Stdout;
import tango.io.Console;
import tango.net.InternetAddress;
import tango.core.Exception;
import tango.io.selector.EpollSelector;
import tango.io.selector.model.ISelector;
import tango.util.log.Log;
import tango.util.log.Configurator;
import tango.text.convert.Sprint;
import tango.core.sync.Mutex;

import sendero.util.ThreadPool;

const char BIND_ADDR[] = "127.0.0.1";

version (linux)
{
const uint EvtOneReadEt = EPOLLIN | EPOLLET | EPOLLONESHOT;
const uint EvtOneWriteEt = EPOLLOUT | EPOLLET | EPOLLONESHOT;
const uint EvtPersistReadEt = EPOLLIN;
}

typedef char[] delegate(char[], int, int*) RequestHandler;

class AsyncServer(THREAD)
{
  alias ThreadPool!(THREAD, SocketConduit) SrvThreadPool; 
	private
	ServerSocket listener;
	EpollSelector selector;
	SrvThreadPool pool;
	Logger logger;
	Sprint!(char) sprint;
  Mutex selMutex;
	RequestHandler reqhandler;
	uint listenerHandle;
  bool running;
  
	public
	this()
	{ 
		sprint = new Sprint!(char);
	  logger = Log.getLogger("AsyncServer");
		selector = new EpollSelector();
		pool = new SrvThreadPool(20);
		selMutex = new Mutex;
		THREAD.register_after_response_write(&rereg_socket);
	}

	void run()
	{
		listener = new ServerSocket(new InternetAddress(BIND_ADDR, 3456), 32, true);
		listener.socket().blocking(false);
		running = true;
		selector.open();
		selector.register(listener, cast(Event)EvtPersistReadEt, new Token);
		event_loop();
	  selector.close();
	}

	void event_loop()
	{
		while (running)
		{
			int eventCount = selector.select();
      
			//TODO every iteration, empty a queue
			// of file descriptors that need to be re-added as read events
			if (eventCount < 0)
			{
				//handle error
				continue;
			}

			foreach (SelectionKey key; selector.selectedSet())
			{
				if (key.isReadable())
				{
					// new connection case
					if (key.attachment())
					{
						handle_connection(key.conduit());
					}
					else
					{
						logger.info("isreadable was triggered");
						handle_read_event(key.conduit());
					}
				}

				if (key.isWritable())
				{
					logger.info("iswriteable was triggered");
					handle_write_event(key.conduit());
				}

				if (key.isError() || key.isHangup() || key.isInvalidHandle())
				{
					logger.info("closing socket");
					selector.unregister(key.conduit());
				  (cast(SocketConduit)key.conduit()).close();
				}
			}
		}
	}

	void handle_connection(ISelectable conduit)
	{
		ServerSocket server = cast(ServerSocket) conduit;
		SocketConduit cond = server.accept();
		cond.socket().blocking(false);  //not sure if we want this
		
		//it would probably be best to go blocking with a really short timeout
    selector.register(cond, cast(Event)EvtOneReadEt);
	}

	void handle_read_event(ISelectable conduit)
	{
		SocketConduit cond = cast(SocketConduit) conduit;
		pool.add_task(cond);
	}

	void handle_write_event(ISelectable conduit)
	{
		// in the future, this may be used to indicate that a 
		// socket is idle
	}

  bool rereg_socket(SocketConduit sock)
	{
		//once we've emptied the socket, we
		// re-add the event notification
		selMutex.lock();
		scope(exit) selMutex.unlock();
		selector.reregister(sock, cast(Event)EvtOneReadEt);
		return true;
	}

}

class Token
{
	bool opCall() {return true;}
}

