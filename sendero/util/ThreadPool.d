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
import tango.util.log.Log;
import tango.util.log.Configurator;
import tango.text.convert.Sprint;
import Integer = tango.text.convert.Integer;


class ThreadPool(THREAD, OBJ)
{
  private WorkQueue!(OBJ) wqueue;
	private THREAD[] workers;
	private int num_workers;
  bool running;
	private Logger logger;
	
	this(int nthreads)
	{ 
		logger = Log.getLogger("sendero.util.Threadpool");
		running = true;
		num_workers = nthreads;
		wqueue = new WorkQueue!(OBJ);
		workers = new THREAD[nthreads];

		int i = 0;
		foreach (wk; workers)
		{
			wk = new THREAD(wqueue);
			wk.name(Integer.toUtf8(++i));
			wk.start();
		}
	}

	public void add_task(OBJ* obj)
	{
		auto sprint = new Sprint!(char);
		wqueue.pushBack(obj);
		logger.info(sprint("added task size - {}", wqueue.size()));
	}

	public void wait()
	{
		foreach(wk; workers)
		{
			wk.join();
		}
	}

	public void end()
	{
		running = false;
	}

}
