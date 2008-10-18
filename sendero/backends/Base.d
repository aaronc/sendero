/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.backends.Base;

import sendero.core.Config;

public import sendero.http.Request;

version(SenderoLog)
{
	public import tango.util.log.Log;
}

version(SenderoBenchmark)
{
	version(SenderoLog) {}
	else {
		import tango.io.FileConduit;
		import  tango.io.Print;
		import  tango.text.convert.Layout;
	}
	import tango.time.StopWatch;
	
}
/**
 * The base class for implementing a backend in Sendero
 *
 */
abstract class AbstractBackend(SessionT, RequestT = Request)
{
	static this()
	{
		version(SenderoLog) auto senderoLog = Log.getLogger("sendero");
		
		version(SenderoBenchmark)
		{
			version(SenderoLog) {}
			else {
				 auto layout = new Layout!(char);
				 auto style = FileConduit.WriteAppending;
	             style.share = FileConduit.Share.Read;
				 auto file = new FileConduit("sendero.benchmarks.txt", style);
				 benchmarkOut = new Print!(char) (layout, file);				
			}
		}
	}
		
	version(SenderoLog) private static Logger senderoLog;
	version(SenderoBenchmark)
	{
		version(SenderoLog) {}
		else {
			private static Print!(char) benchmarkOut;
		}
	}
		
	this(void function(RequestT) appMain)
	{
		if(appMain is null) throw new Exception("Sendero application has no main function");
		this.appMain = appMain;
	}
	
	void setDefaultErrorHandler(void function(RequestT) errorHandler)
	{
		this.errorHandler = errorHandler;
	}
	
	protected void function(RequestT) appMain;
	protected void function(RequestT) errorHandler;
	
	/**
	 * Begins execution of the Sendero application
	 */
	abstract void run(char[][] args);
}