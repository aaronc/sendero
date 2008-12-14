module sendero.server.WorkerPool;

import tango.core.Thread;
import tango.core.sync.Semaphore, tango.core.sync.Mutex;
import sendero.server.runtime.SafeThread;

import sendero.util.collection.ThreadSafeQueue;

import tango.util.log.Log;
	
static Logger log;

static this()
{
	log = Log.lookup("sendero.server.WorkerPool");
}

class WorkerPoolThread(JobType) : SafeWorkerThread
{
	alias void delegate(JobType) DgT;
	
	this(WorkerPool(!JobType) ooil, DgT workerProc)
	{
		assert(workerProc);
		assert(pool);
		this.pool_ = pool;
		this.workerProc_ = workerProc;
		
	}
	private DgT workerProc_;
	private WorkerPool(!JobType) pool_;
	
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

class WorkerPool(JobType)
{
public:
	alias void delegate(JobType) DgT;

	this(DgT workerProc, uint startThreads = 4)
	{
		assert(workerProc);
		this.workerProc_ = workerProc;
		this.running_ = true;
		greenLight_ = new Semaphore;
		jobQueue_ = new ThreadSafeQueue2!(JobType);
		threads_ = new ThreadGroup;
		for(uint i = 0; i < startThreads; ++i) {
			auto t = new WorkerPoolThread!(DgT)(&proc);
			threads_.add(t);
			t.start;
		}
	}
	
	void pushJob(JobType job)
	{
		debug log.info("Pushing job");
		assert(jobQueue_ !is null);
		jobQueue_.push(job);
		greenLight_.notify;
		debug log.info("Done pushing job");
	}
	
	void shutdown()
	{
		running_ = false;
		threads_.joinAll;
	}
	
private:
	ThreadSafeQueue2!(JobType) jobQueue_;
	
	//Atomic!(bool) pause_;
	//Mutex trafficLight_;
	Semaphore greenLight_;
	bool running_;
	DgT workerProc_;
	ThreadGroup threads_;
}	