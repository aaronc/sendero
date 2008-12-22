module sendero.server.WorkerPool;

import tango.core.Thread;
import tango.core.sync.Semaphore, tango.core.sync.Mutex;
import sendero.server.runtime.SafeThread;
//import sendero.server.TimerDispatcher;

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
	}
	
	 static class Node
	{
		this(Thread t, Node prev = null)
		{ this.t = t; this.prev = prev; }
		Thread t;
		Node next = null;
		Node prev = null;
	}
	package Node head = null;
	package Node tail = null;
	private Node remove(Node node)
	{
		if(node.prev !is null) {
			node.prev.next = node.next;
			if(node.next !is null) node.next.prev = node.prev;
			return node.next;
		}									
		else {
			assert(head == node);
			if(node == tail) {
				head = tail = null;
				return null;
			}
			else {
				head = node.next;
				return node.next;
			}
		}
	}
	private void addThread(Thread t)
	{
		if(head is null) {
			assert(tail is null);
			head = tail = new Node(t);
		}
		else {
			assert(tail !is null);
			auto n = new Node(t, tail);
			tail.next = n;
			tail = n;			
		}
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
			auto t = createThread;
			addThread(t);
			t.start;
		}
	}
	
	uint runningThreads()
	{
		uint i = 0;
		auto node = head;
		while(node !is null) {
			assert(node.t);
			if(node.t.isRunning) {
				++i; node = node.next;
			}
			else node = remove(node); 
		}
		return i;
	}
	
	void shutdown()
	{
		running_ = false;
	}
	
	void ensureAlive()
	{
		auto node = head;
		while(node !is null) {
			assert(node.t);
			if(node.t.isRunning)
				return;
			else node = remove(node); 
		}
		
		if(startThreads_ == 0) startThreads_ = 1;
		log.error("Thread pool was dead on call to ensureAlive, "
		"restarting {} threads", startThreads_);
		start(startThreads_);
	}

/+
	void setHeartbeat(TimerDispatcher timer, uint resolutionMultiplier = 0)
	{
		auto heartbeat = new TimedTask(&ensureAlive, resolutionMultiplier, true);
		timer.scheduleTask(heartbeat);
	}
+/
	
protected:
	uint startThreads_;
	ThreadSafeQueue!(JobType) jobQueue_;
	Semaphore greenLight_;
	bool running_;
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
			debug log.trace("Starting Job");
			jobDg();
			debug log.trace("Completed Job");
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