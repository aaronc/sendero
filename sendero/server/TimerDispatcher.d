module sendero.server.TimerDispatcher;

import tango.stdc.posix.sys.time;

import sendero.server.model.IEventLoop;
import sendero.util.collection.ThreadSafeQueue;

import tango.util.log.Log;
private Logger log;
static this()
{
	log = Log.lookup("sendero.server.TimerDispatcher");
}

class TimedTask
{
	this(void delegate() dg,
		uint resolutionMultiplier,
		bool recurring = false)
	{
		this.dg = dg;
		this.resolutionMultiplier = resolutionMultiplier;
		this.recurring = recurring;
		this.count = resolutionMultiplier;
	}
	
	void delegate() dg;
	uint resolutionMultiplier;
	bool recurring;
	private uint count;
}

class TimerDispatcher
{
	this(IMainEventLoop evntDispatcher, uint resolution = 1000)
	{
		this.evntDispatcher = evntDispatcher;
		evntDispatcher.setSignalHandler(SIGALRM, &handleAlarmSignal);
		taskQueue = new typeof(taskQueue);
		this.resolution = resolution;
	}
	
	~this()
	{
		evntDispatcher.unsetSignalHandler(SIGALRM);
	}
	
	private ThreadSafeQueue!(TimedTask) taskQueue;
	private TimedTask[] tasks;
	private IMainEventLoop evntDispatcher;
	
	private void handleAlarmSignal(SignalInfo sig)
	{
		foreach(task; tasks)
		{
			task.dg();
		}
		//debug log.trace("Got Alarm Signal");
		/+auto task = taskQueue.pop;
		while(task !is null) {
			if(task.count == 0)
			{
				//debug log.trace("Running Timed Task");
				task.dg();
				if(task.recurring)
				{
					taskQueue.push(task);
				}
			}
			else
			{
				--task.count;
				taskQueue.push(task);
			}
			task = taskQueue.pop;
		}+/
	}
	
	private void setResolutionTask(ISyncEventDispatcher)
	{
		itimerval setVal;
		timeval interval;
		interval.tv_sec = resolution_ / 1000;
		interval.tv_usec = (resolution_ % 1000) * 1000;
		setVal.it_interval = interval;
		setVal.it_value = interval;
		setitimer(ITIMER_REAL,&setVal,null);
	}
	
	void resolution(uint millseconds)
	{
		resolution_ = millseconds;
		evntDispatcher.postTask(&setResolutionTask);
	}
	
	uint resolution()
	{
		return resolution_;
	}
	
	private uint resolution_;
	
	void scheduleTask(TimedTask task)
	{
		//taskQueue.push(task);
		tasks ~= task;
	}
}