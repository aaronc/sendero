module sendero.server.WorkerPool;

import tango.core.Thread;
import tango.core.sync.Semaphore, tango.core.sync.Mutex;
import sendero.server.runtime.SafeThread;
import sendero.server.TimerDispatcher;

import sendero.util.collection.ThreadSafeQueue;

import tango.util.log.Log;
	
static Logger log;

static this()
{
	log = Log.lookup("sendero.server.WorkerPool");
}

abstract class WorkerPoolBase(JobType)
{
	this()
	{
		greenLight_ = new Semaphore;
		jobQueue_ = new ThreadSafeQueue!(JobType);
		threads_ = new ThreadGroup;
	}
	
	void pushJob(JobType job)
	{
		debug log.trace("Pushing job");
		debug assert(jobQueue_ !is null);
		jobQueue_.push(job);
		greenLight_.notify;
		debug log.trace("Done pushing job");
	}
	
	protected abstract Thread createThread();
	
	void start(uint startThreads = 1)
	{
		startThreads_ = startThreads;
		running_ = true;
		for(uint i = 0; i < startThreads; ++i) {
			//auto t = new ThreadT!(DgT)(&proc);
			auto t = createThread;
			threads_.add(t);
			t.start;
		}
	}
	
	uint runningThreads()
	{
		uint i = 0;
		foreach(thr; threads_)
		{
			if(thr.isRunning)
				++i;
		}
		return i;
	}
	
	void shutdown()
	{
		running_ = false;
		threads_.joinAll;
	}
	
	void ensureAlive()
	{
		foreach(thr; threads_)
		{
			if(thr.isRunning)
				return;
		}
		if(startThreads_ == 0) startThreads_ = 1;
		log.error("Thread pool was dead on call to ensureAlive, "
		"restarting {} threads", startThreads_);
		start(startThreads_);
	}
	
	void setHeartbeat(TimerDispatcher timer, uint resolutionMultiplier = 0)
	{
		auto heartbeat = new TimedTask(&ensureAlive, resolutionMultiplier);
		timer.scheduleTask(heartbeat);
	}
	
protected:
	uint startThreads_;
	ThreadSafeQueue!(JobType) jobQueue_;
	Semaphore greenLight_;
	bool running_;
	ThreadGroup threads_;
}

alias void delegate() WorkDg;

class WorkerPoolThread  : SafeWorkerThread
{
	this(WorkerPool pool)
	{
		assert(pool);
		this.pool_ = pool;
	}
	private WorkerPool pool_;
	
	override void doWork()
	{
		try
		{
			debug log.trace("Waiting for traffic");
			pool_.greenLight_.wait;
			debug log.trace("Got notified");
			auto jobDg = pool_.jobQueue_.pop;
			debug assert(jobDg !is null);
			jobDg();
		}
		catch(Exception ex)
		{
			if(ex.info !is null) {
				log.error("Exception caught:{}. Trace: {}", ex.toString, ex.info.toString);
			}
			else {
				log.error("Exception caught:{}", ex.toString);
			}
		}
	}
}


class WorkerPool : WorkerPoolBase!(WorkDg)
{	
	protected override Thread createThread()
	{
		return new WorkerPoolThread(this);
	}
}

class JobWorkerPoolThread(JobType) : SafeWorkerThread
{
	alias void delegate(JobType) DgT;
	
	this(JobWorkerPool!(JobType) pool)
	{
		assert(pool.workerProc_);
		assert(pool);
		this.pool_ = pool;
		this.workerProc_ = pool.workerProc_;
		
	}
	private DgT workerProc_;
	private JobWorkerPool!(JobType) pool_;
	
	override void doWork()
	{
		try
		{
			debug log.trace("Waiting for traffic");
			pool_.greenLight_.wait;
			debug log.info("Got notified");
			auto job = pool_.jobQueue_.pop;
			if(job !is null)
				workerProc_(job);
		}
		catch(Exception ex)
		{
			if(ex.info !is null) {
				log.error("Exception caught:{}. Trace: {}", ex.toString, ex.info.toString);
			}
			else {
				log.error("Exception caught:{}", ex.toString);
			}
		}
	}
}

class JobWorkerPool(JobType) : WorkerPoolBase!(JobType)
{
public:
	alias void delegate(JobType) DgT;

	this(DgT workerProc)
	{
		assert(workerProc);
		this.workerProc_ = workerProc;
		super();
	}
	
	protected override Thread createThread()
	{
		return new JobWorkerPoolThread!(JobType)(this);
	}
	
protected:
	DgT workerProc_;
}