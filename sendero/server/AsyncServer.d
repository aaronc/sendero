/**
 * Copyright: Copyright (C) 2007 Rick Richardson.  All rights reserved.
 * License:   BSD Style
 * Authors:   Rick Richardson
 */

module sendero.server.AsyncServer;

import tango.io.selector.EpollSelector;
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

const uint EvtOneRead = Event.Read | Event.EdgeTriggered | 
												Event.Hangup | Event.Error;
const uint EvtOneWrite = Event.Write | Event.EdgeTriggered | 
												 Event.Hangup | Event.Error;
const uint EvtErrChk = Event.Hangup | Event.Error;
const uint EvtPersistRead = Event.Read;

typedef char[] delegate(char[], int, int*) RequestHandler;

class AsyncServer(THREAD)
{
  alias ThreadPool!(THREAD, SelectionKey) SrvThreadPool; 
	private
	ServerSocket listener;
	EpollSelector selector;
	SrvThreadPool pool;
	Logger logger;
	Sprint!(char) sprint;
  Mutex selMutex;
	RequestHandler reqhandler;
  bool running;
 	WorkQueue!(SelectionKey) reRegSockList;
	uint reqnum;
	uint[uint] reqtable;
	public
	this()
	{ 
		sprint = new Sprint!(char);
	  logger = Log.getLogger("AsyncServer");
		selector = new EpollSelector();
		pool = new SrvThreadPool(20);
		selMutex = new Mutex;
		reRegSockList = new WorkQueue!(SelectionKey);
		THREAD.register_after_response_write(&rereg_socket);
		reqnum = 0;
	}

	void run()
	{
		listener = new ServerSocket(new InternetAddress(BIND_ADDR, 3456), 128 * 8, true);
		listener.socket().blocking(false);
		running = true;
		selector.open();
		selector.register(listener, EvtPersistRead); 
		event_loop();
	  selector.close();
	}

	void event_loop()
	{
		while (running)
		{
			int eventCount = selector.select(0.3);
			if (eventCount > 0)
			{
				ISelectionSet selset = selector.selectedSet();
				foreach (SelectionKey key; selset)
				{
					if (key.check(Event.Error) || key.check(Event.Hangup))
					{
						logger.info(sprint("closing socket {}", key.conduit().fileHandle()));
						selector.unregister(key);
						(cast(SocketConduit)key.conduit()).detach();
					}
				}
				foreach (SelectionKey key; selset)
				{
					if (key.check(Event.Read))
					{
						// new connection case
						if (key.conduit() is listener)
						{
							handle_connection(key.conduit());
						}
						else
						{
							if (key.conduit().fileHandle() > 0)
								handle_read_event(key);
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
			foreach(SelectionKey key; reRegSockList)
			{
				SocketConduit cond = cast(SocketConduit) key.conduit();
				if (cond.readable())
				{
					//selector.reregister(key, EvtOneRead);
				}
				else
				{
					logger.info(sprint("unregestering {}", key._id));
					selector.unregister(key);
					cond.detach();
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
			
			logger.info(sprint("adding child socket  {}", cond.fileHandle()));
  	  selector.register(cond, EvtOneRead);			
		}
		catch(tango.core.Exception.SocketAcceptException e)
		{
			//logger.error(sprint("Exception in accepting socket {}", e));
		}
	}

	void handle_read_event(SelectionKey key)
	{
		logger.info(sprint("adding task from read event {}", key.conduit().fileHandle()));
		reqnum++;
		key._id = reqnum;
		reqtable[reqnum] = 1;
		pool.add_task(key);
	}

	void handle_write_event(SelectionKey conduit)
	{
		// in the future, this may be used to indicate that a 
		// socket is read for write
	}

  bool rereg_socket(SelectionKey key)
	{
		//once we've emptied the socket, we
		// re-add the event notification
		logger.info(sprint("completed {}", key._id));
		reqtable[key._id] = 0;
		reRegSockList.pushBack(key);
    
		foreach (reqid; reqtable.keys)
    {
			if (reqtable[reqid] > 0)
				logger.info(sprint("uncompleted: {}", reqid));
    }
		return true;
	}

}

