/**
 * Copyright: Copyright (C) 2007 Rick Richardson.  All rights reserved.
 * License:   BSD Style
 * Authors:   Rick Richardson
 */

module sendero.util.AsyncServer;

import tango.io.selector.EpollSelector;
import tango.sys.linux.epoll;
import tango.net.SocketConduit;
import tango.net.ServerSocket;
import tango.net.InternetAddress;
import tango.io.Stdout;
import tango.io.Console;
import tango.net.InternetAddress;
import tango.core.Exception;
import tango.io.selector.EpollSelector;
import tango.io.selector.model.ISelector;

import sendero.util.ThreadPool;

const char BIND_ADDR[] = "127.0.0.1";

version (linux)
{
const uint EvtOneReadEt = EPOLLIN | EPOLLET;   // maybe EPOLLONESHOT 
const uint EvtOneWriteEt = EPOLLOUT | EPOLLET; // maybe EPOLLONESHOT
const uint EvtPersistReadEt = EPOLLIN;
}

class AsyncServer
{
	private
	TaskHandler read_handler;
	ServerSocket listener;
	EpollSelector selector;
	ThreadPool pool;
  uint listenerHandle;
  bool running;

	public
	this()
	{
		selector = new EpollSelector();
		pool = new ThreadPool(20);
	}

	void run()
	{
		listener = new ServerSocket(new InternetAddress(BIND_ADDR, 3456), 32, true);
		pool.set_task_handler(read_handler);
		listener.socket().blocking(false);
		running = true;
		selector.open();
		selector.register(listener, cast(Event)EvtPersistReadEt);
		event_loop();
	  selector.close();
	}

	void event_loop()
	{
		while (running)
		{
			int eventCount = selector.select();

			if (eventCount < 0)
			{
				//handle error
				continue;
			}

			foreach (SelectionKey key; selector.selectedSet())
			{
				SocketConduit sock = cast(SocketConduit) key.conduit();
				if (key.isReadable())
				{
					// new connection case
					if (sock.socket().fileHandle() == listenerHandle)
					{
						handle_connection(sock);
					}
					else
					{
						handle_read_event(sock);
						selector.reregister(sock, cast(Event)EvtOneWriteEt);
					}
				}

				if (key.isWritable())
				{
					handle_write_event(sock);
					selector.reregister(sock, cast(Event)EvtOneReadEt);
				}

				if (key.isError() || key.isHangup() || key.isInvalidHandle())
				{
					selector.unregister(sock);
					sock.close();
				}
			}
		}
	}

	void handle_connection(SocketConduit conduit)
	{
		ServerSocket server = cast(ServerSocket) conduit;
		SocketConduit cond = server.accept();
		//cond.socket().blocking(false);  not sure if we want this
		//it would probably be best to go blocking with a really short timeout
    selector.register(cond, cast(Event)EvtOneWriteEt);

		// if there is a connection, there should be data right away
		pool.add_task(cond);
	}

	void handle_read_event(SocketConduit conduit)
	{
		pool.add_task(conduit);
	}

	void handle_write_event(SocketConduit conduit)
	{
		// in the future, this may be used to indicate that a 
		// socket is idle
	}

	void register_read_handler(TaskHandler handler)
	{
		read_handler = handler;
	}
}

version (TestMain)
{
	void main()
	{
		void handler(SocketConduit cond)
		{
			char buffer[1024];
			int rec;

			rec = cond.read(buffer);
			assert(rec != IConduit.Eof);
			Stdout.formatln("Received {} bytes", rec);
			Stdout.formatln(buffer);
		}

		srv = new AsyncServer();
		srv.register_read_handler(&handler);
    srv.run();
	}
}
