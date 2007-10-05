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

import tango.core.Thread;
public import sendero.util.WorkQueue;
import tango.core.Exception;
import tango.util.log.Log;
import tango.util.log.Configurator;
import tango.text.convert.Sprint;
import Integer = tango.text.convert.Integer;

typedef void delegate(Object) TaskHandler;

class ThreadPool
{
  private WorkQueue wqueue;
	private PoolWorker[] workers;
	private int num_workers;
  bool running;
	private Logger logger;
  TaskHandler task_handler;
	this(int nthreads)
	{ 
		logger = Log.getLogger("sendero.util.Threadpool");
		running = true;
		num_workers = nthreads;
		wqueue = new WorkQueue;
		workers = new PoolWorker[nthreads];
    
		int i = 0;
		foreach (wk; workers)
		{
			wk = new PoolWorker();
			wk.name(Integer.toUtf8(++i));
			wk.start();
		}
	}

	public void add_task(Object obj)
	{
		auto sprint = new Sprint!(char);
		wqueue.pushBack(obj);
		logger.info(sprint("added task size - {}", wqueue.size()));
	}

	public void set_task_handler(TaskHandler fun)
	{
		task_handler = fun;
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

	class PoolWorker : Thread 
	{
		this ()
		{
			super(&run);
		}

		private
		void run() 
		{
			auto sprint = new Sprint!(char);
			logger.info("Starting thread");
			while(running)
			{
				//WorkQueue is built for threaded access and will block on empty
				//so this thread simply needs to request a task and will block(sleep)
				//until one becomes available
			  Object obj = wqueue.popFront();
				logger.info(sprint("popped task size - {}", wqueue.size()));
				try
   			{
					task_handler(obj);
				}
				catch(Exception e)
				{
					logger.error("Exception: " ~ e.toUtf8);
				}
			}
		}
	}
}
