/**
 * Copyright: Copyright (C) 2007 Rick Richardson.  All rights reserved.
 * License:   BSD Style
 * Authors:   Rick Richardson
 */

module sendero.util.AsyncServer;

import tango.net.Socket;
import tango.io.Stdout;
import tango.io.Console;
import tango.stdc.stdio;
import tango.core.Memory;
import tango.net.InternetAddress;
import tango.core.Exception;

import sendero.util.event;
import sendero.util.ThreadPool;

const int MAX_CONN = 512; // this will likely be overridden to 128 or whatever the max is
const int NUM_THREADS = 20;

typedef int function(SocketEvent*) Handler;

alias _BCD_func__388 EventCallback;

struct SocketEvent
{
	AsyncServer asock;
	Socket sock;
	event evt;
}

class AsyncServer
{
  //todo, take port, addr, etc as params
	this()
	{
		pool = new ThreadPool(NUM_THREADS);
	}
	~this()
	{}

	void run()
	{
		EventCallback fp = &handle_connection;  //bcd alias for a function ptr
		chevt = new SocketEvent();
		Stdout.formatln("run chevt = {}", chevt);
    chevt.asock = this;
		chevt.sock = new Socket(AddressFamily.INET, 
														SocketType.STREAM, 
														ProtocolType.TCP, 
														true);

		try 
		{
  		chevt.sock.bind(new InternetAddress("127.0.0.1", 3456));
  		chevt.sock.listen(MAX_CONN);
		}
		catch(SocketException e)
		{
			Stdout.formatln(e.toUtf8);
			throw new Exception("Try to die");
		}
  	chevt.sock.blocking(false);

		void* ebase = event_init();
		event_set(&chevt.evt, chevt.sock.fileHandle(), EV_READ | EV_PERSIST, fp, chevt);
  	event_add(&chevt.evt, null);

		int err = event_dispatch();
		if (err != 0)
			Stdout.formatln("event_dispatch ended with error {}", err);
	}

	static void handle_data_event(int fd, short event, void* arg)
	{
		SocketEvent* sevt = cast(SocketEvent*) arg;
		/*
		Stdout.formatln("in handle_data_event");
    AsyncServer self = sevt.asock;
		if (self.dataFN)
		{
			auto df = new DataFunctor(self.dataFN, sevt);
			pool.add_task(df);
		}
		Stdout.formatln("done with handle_data_event");
		*/
		char buf[1024];
		int rec = sevt.sock.receive(buf);

		if (rec > 0) 
		{
			Stdout.formatln("handle_data received {} bytes", rec);
			Stdout.formatln(buf[0 .. rec]);
		}
		
	}

	static void handle_connection(int fd, short event, void* arg)
	{
		SocketEvent* cevt = cast(SocketEvent*)(arg);
    Stdout.formatln("handle_connection cevt = {}", cevt);
		SocketEvent* sevt = new SocketEvent();
    cevt.asock.devent = sevt;
		sevt.sock = cevt.sock.accept();

		EventCallback fp = &handle_data_event;
		sevt.sock.blocking(false);

		// set up an event for the new socket
		event_set(&sevt.evt, sevt.sock.fileHandle(), EV_READ | EV_PERSIST, fp, sevt);
		// event add to begin handling data events for that socket
		event_add(&sevt.evt, null);
	}

	public void shutdown()
	{
		chevt.sock.shutdown(SocketShutdown.BOTH);
	}

	public void setDataCallback(Handler cb)
	{
		dataFN = cb;
	}
	public void setErrorCallback(Handler cb)
	{
		errorFN = cb;
	}
	public void setSockFlags(SocketFlags sf)
	{
		sockflags = sf;
	}
	private static Handler dataFN;
	private static Handler errorFN;	
	private static SocketFlags sockflags;

	private SocketEvent* chevt;
	private SocketEvent* devent;
	private static ThreadPool pool;
}

class DataFunctor : WQFunctor
{
	this(Handler f, SocketEvent* e) 
	{
		evt = e; 
		myFunc = f; 
	}
	void opCall() { result = myFunc(evt); }
	SocketEvent* evt;
	int result;
	Handler myFunc;	
}

