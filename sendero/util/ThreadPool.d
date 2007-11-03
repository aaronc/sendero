/**
 * Copyright: Copyright (C) 2007 Rick Richardson.  All rights reserved.
 * License:   BSD Style
 * Authors:   Rick Richardson
 */

// ThreadPool class offers the ability to queue up Runnable tasks to be 
// executed by a free thread if one is available. If the queue is empty
// the threads will sleep on a Condition in the workqueue, the workqueue
// itself will notify the sleepers itself when more work arrives.

module sendero.util.ThreadPool;

public import sendero.util.WorkQueue;
import tango.core.Exception;
import tango.core.Thread;
import tango.core.Memory;
import tango.util.log.Log;
import tango.util.log.Configurator;
import tango.text.convert.Sprint;
import Integer = tango.text.convert.Integer;
import tango.stdc.posix.signal;
import tango.stdc.posix.pthread;

class ThreadPool(THREAD, OBJ)
{
  private WorkQueue!(OBJ) wqueue;
	private THREAD[] workers;
	private int num_workers;
	private Logger logger;
	private static Thread main_thread;
	this(int nthreads)
	{ 
		logger = Log.getLogger("Threadpool");
		num_workers = nthreads;
		wqueue = new WorkQueue!(OBJ);
		workers = new THREAD[nthreads];
		
		main_thread	= Thread.getThis();
		//signal(SIGUSR1, &pausethreads);   not needed
		//signal(SIGUSR2, &resumethreads);  

		int i = 0;
		GC.disable();
		foreach (wk; workers)
		{
			wk = new THREAD(wqueue);
			wk.name(Integer.toUtf8(++i));
			wk.start();
		}
		GC.enable();
	}

	public void add_task(OBJ obj)
	{
		auto sprint = new Sprint!(char);
		wqueue.pushBack(obj);
	}

	//this is unessesary since the tango.Thread class joins by default
	public void wait()
	{
		foreach(wk; workers)
		{
			wk.join();
		}
	}

	extern (C) static private void pausethreads(int a)
	{
			Logger log = Log.getLogger("Threadpool");
			log.info("Suspending threads for GC");
	}

	extern (C) static private void resumethreads(int a)
	{
			Logger log = Log.getLogger("Threadpool");
			log.info("Resuming threads");
	}

	public static bool iAmMainThread()
	{
		return (Thread.getThis() is ThreadPool.main_thread);
	}
}
