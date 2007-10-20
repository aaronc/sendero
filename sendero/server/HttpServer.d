/**
 * Copyright: Copyright (C) 2007 Rick Richardson.  All rights reserved.
 * License:   BSD Style
 * Authors:   Rick Richardson
 */

module sendero.server.HttpServer;

import tango.util.log.Log;
import tango.util.log.Configurator;
import tango.text.convert.Sprint;
import tango.sys.linux.epoll;
import tango.net.SocketConduit;
import tango.io.model.IConduit;
import tango.io.Stdout;
import tango.io.Console;
import tango.core.Exception;
import tango.net.Socket;
import sendero.util.http.HttpProvider;
import sendero.server.AsyncServer;
import sendero.server.HttpThread;
import sendero.server.SenderoProvider;

Logger logger;

  void main()
	{
		auto sprint = new Sprint!(char);

		auto pfact = new SenderoProviderFactory;
		HttpThread.set_providerfactory(pfact); 
		auto srv = new AsyncServer!(HttpThread);
    srv.run();
	}
