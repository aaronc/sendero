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
import tango.core.Thread;
import tango.io.selector.EpollSelector;
import tango.io.selector.model.ISelector;
import tango.util.log.Log;
import tango.util.log.Configurator;
import tango.text.convert.Sprint;
import tango.core.sync.Mutex;
import tango.core.Exception;
import tango.core.BitArray;
import sendero.util.ThreadPool;

const char BIND_ADDR[] = "127.0.0.1";

version (linux)
{
const uint EvtOneReadEt = EPOLLIN | EPOLLET | EPOLLONESHOT;
const uint EvtOneWriteEt = EPOLLOUT | EPOLLONESHOT;
const uint EvtPersistReadEt = EPOLLIN;
}
version (bsd)
{

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
 	WorkQueue!(SocketConduit) reRegSockList;
  //BitArray registry;
	public
	this()
	{ 
		sprint = new Sprint!(char);
	  logger = Log.getLogger("AsyncServer");
		selector = new EpollSelector();
		pool = new SrvThreadPool(20);
		selMutex = new Mutex;
		reRegSockList = new WorkQueue!(SocketConduit);
		THREAD.register_after_response_write(&rereg_socket);
		//registry.length(1024); //sparse array to see if file handle is busy.
	}

	void run()
	{
		listener = new ServerSocket(new InternetAddress(BIND_ADDR, 3456), 32, true);
		listener.socket().blocking(false);
		running = true;
		selector.open();
		selector.register(listener, cast(Event)EvtPersistReadEt, new Token); //token is a silly struct
		                                                                     //that returns true
		                                                                     //it's how identify that srv
		event_loop();
	  selector.close();
	}

	void event_loop()
	{
		while (running)
		{
			int eventCount = selector.select(0.3);
			//TODO every iteration, empty a queue
			// of file descriptors that need to be re-added as read events
			if (eventCount > 0)
			{
				foreach (SelectionKey key; selector.selectedSet())
				{
					if (key.isError() || key.isHangup() || key.isInvalidHandle())
					{
						logger.info(sprint("closing socket {}", key.conduit().fileHandle()));
						selector.unregister(key.conduit());
						(cast(SocketConduit)key.conduit()).close();
					}					
					else if (key.isReadable())
					{
						// new connection case
						if (key.attachment())
						{
							handle_connection(key.conduit());
						}
						else
						{
							handle_read_event(key.conduit());
						}
					}
					//if (key.isWritable())
					//{
					//	logger.info("iswriteable was triggered");
					//	handle_write_event(key.conduit());
					//}


				}
			}
			//iterate through all empty sockets set here by the handler threads
			//and place them back in the ready state
			foreach(SocketConduit cond; reRegSockList)
			{
				logger.info(sprint("found socket to reregister {}", cond.fileHandle()));
				if (cond.isAlive())
					selector.reregister(cond, cast(Event)EvtOneReadEt);
				else
				{
					logger.info("socket unregistered");
				}
			}
		}
	}

	void handle_connection(ISelectable conduit)
	{
		try 
		{
			ServerSocket server = cast(ServerSocket) conduit;
			SocketConduit cond = server.accept();
			cond.socket().blocking(false);  //not sure if we want this
			logger.info(sprint("Adding socket to selector {}", cond.fileHandle()));
    	selector.register(cond, cast(Event)EvtOneReadEt);
		}
		catch(tango.core.Exception.SocketAcceptException e)
		{
			logger.error(sprint("Exception in accepting socket {}", e));
		}
	}

	void handle_read_event(ISelectable conduit)
	{
		SocketConduit cond = cast(SocketConduit) conduit;
		logger.info(sprint("adding task from read event {}", cond.fileHandle()));
		
		/*
		selMutex.lock();
		scope(exit) selMutex.unlock();
		if (registry.length() < cond.fileHandle()+1)
			registry.length(cond.fileHandle()+1);
		
		if (!registry[cond.fileHandle()])
		{
			pool.add_task(cond);
			registry[cond.fileHandle()] = true;
		}
		*/
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
		if (! sock.isAlive())
		{
			logger.info(sprint("Thread: {0} dead socket {1}, dropping", 
								Thread.getThis().name(), sock.fileHandle()));
			//we don't re-add it to the reRegSockList because the Conduit will get recycled
			//and instead of unregistering it, it will re-register it
		}
		else
		{
			logger.info(sprint("Thread: {0} Re adding socket event {1}", 
									Thread.getThis().name(), sock.fileHandle()));
			//selMutex.lock();
			//scope(exit) selMutex.unlock();
			//registry[sock.fileHandle()] = false;
			reRegSockList.pushBack(sock);
		}
		return true;
	}

}

class Token
{
	bool opCall() {return true;}
}

