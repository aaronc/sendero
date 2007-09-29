

module sendero.util.AsyncServer;

import sendero.util.event;
import tango.net.Socket;
import tango.io.Stdout;
import tango.io.Console;
import tango.stdc.stdio;
import tango.core.Memory;
import tango.net.InternetAddress;

const int MAX_CONN = 512; // this will likely be overridden to 128 or whatever the max is


alias _BCD_func__388 EventCallback;


struct SocketEvent
{
	AsyncServer* asock;
	Socket sock;
	event evt;
}

class AsyncServer
{
	this()
	{}
	~this()
	{}

	void run()
	{
		EventCallback fp = &handle_connection;  //bcd alias for a function ptr
		chevt = new SocketEvent();
		Stdout.formatln("run chevt = {}", chevt);
    chevt.asock = &this;
		chevt.sock = new Socket(AddressFamily.INET, 
														SocketType.STREAM, 
														ProtocolType.TCP, 
														true);

  	chevt.sock.bind(new InternetAddress("127.0.0.1", 3456));
  	chevt.sock.listen(MAX_CONN);
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
		char buf[1024];
	  SocketEvent* sevt = cast(SocketEvent*) arg;
		int rec = sevt.sock.receive(buf);

    Stdout.formatln("received {} bytes", rec);
		if (rec > 0) 
		{
			Stdout.formatln("handle_data received {} bytes", rec);
			if (sevt.asock.eventDG)
				sevt.asock.eventDG(buf[0..(rec-1)]);
			else if (sevt.asock.eventFN)
				sevt.asock.eventFN(buf[0..(rec-1)]);
		}
		else
		{
			if (sevt.asock.errorDG)
				sevt.asock.errorDG("Error received from receive");
			else if (sevt.asock.errorFN)
				sevt.asock.errorFN("Error received from receive");
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

	public void setEventCallback(int delegate(char[]) cb)
	{
		eventDG = cb;
	}
	public void setEventCallback(int function(char[]) cb)
	{
		eventFN = cb;
	}
	public void setErrorCallback(int delegate(char[]) cb)
	{
		errorDG = cb;
	}
	public void setErrorCallback(int function(char[]) cb)
	{
		errorFN = cb;
	}
	public void setSockFlags(SocketFlags sf)
	{
		sockflags = sf;
	}
	private static int delegate(char[]) eventDG;
	private static int function(char[]) eventFN;
	private static int delegate(char[]) errorDG;
	private static int function(char[]) errorFN;	
	private static SocketFlags sockflags;

	private SocketEvent* chevt;
	private SocketEvent* devent;
}


