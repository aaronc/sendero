module sendero.server.EventDispatcher;

public import sendero.server.model.IEventDispatcher;

import sendero.util.collection.ThreadSafeQueue;

import tango.io.selector.Selector;
import tango.core.Thread;
import tango.util.log.Log;

static Logger log;

static this()
{
	log = Log.lookup("sendero.server.EventDispatcher");
}

class EventDispatcher : ISyncEventDispatcher
{
	this(ISelector selector = null)
	{
		if(selector !is null) this.selector = selector;
		else this.selector = new Selector;
		this.taskQueue = new ThreadSafeQueue2!(EventTaskDg);
		this.timeout = timeout;
	}
	private ThreadSafeQueue2!(EventTaskDg) taskQueue;
	private ISelector selector;
	private double timeout_ = 0.1;
	double timeout() { return timeout_; }
	void timeout(double t) { timeout_ = t; }
	
	private bool opened_ = false;
	private bool running_ = false;
	debug private Thread loopThread_;
	
	void postTask(EventTaskDg task)
	{
		taskQueue.push(task);
	}
	
	/**
	 * Must be called synchronously!
	 * 
	 * 
	 */
	void register(ISelectable conduit, Event events, EventResponder attachment)
	{
		debug log.trace("Registering {} for events {}", attachment, events);
		debug assert(Thread.getThis == loopThread_, "register should only be called from the event loop thread");
		selector.register(conduit, events, attachment);
	}
	
	/**
	 * Must be called synchronously!
	 * 
	 * 
	 */
	void unregister(ISelectable conduit)
	{
		debug log.trace("Unregistering ISelectable");
		debug assert(Thread.getThis == loopThread_, "unregister should only be called from the event loop thread");
		selector.unregister(conduit);
	}
	
	void open(uint size, uint maxEvents)
	{
		assert(!opened_, "EventDispatcher should be opened only once");
		selector.open(size, maxEvents);
		opened_ = true;
	}
	
	void shutdown()
	{
		running_ = false;
	}
	
	void run()
	{
		assert(opened_,"EventDispatcher.open must be called before run");
		assert(!running_, "Only one instance of the event loop should be called at a time");
		running_ = true;
		loopThread_ = Thread.getThis;
		
		while(running_) {
			try
			{
				auto task = taskQueue.pop;
				while(task !is null && running_) {
					debug log.trace("Running task");
					task(this);
					task = taskQueue.pop;
				}
				
				auto eventCnt = selector.select(timeout);
				if(eventCnt > 0) {
					debug log.trace("Found some events");
					foreach(key; selector.selectedSet) {
						if(!running_) break;
						
						auto responder = cast(EventResponder)key.attachment;
						debug assert(responder);
						if(key.isReadable)
						{
							debug log.trace("Read event for responder {}", responder.toString);
							responder.handleRead(this);
						}
						else if(key.isWritable)
						{
							debug log.trace("Write event for responder {}", responder.toString);
							responder.handleWrite(this);
						}
						else if(key.isHangup)
						{
							log.warn("Hangup event for responder {}", responder.toString);
							responder.handleDisconnect(this);
						}
						else if(key.isError() || key.isInvalidHandle())
	                    {
							if(key.isError())
								log.warn("Selection key for responder {} has an error",responder.toString);
							if(key.isInvalidHandle())
								log.warn("Selection key for responder {} return invalid handle",responder.toString);
							responder.handleError(this);
	                    }
					}
				}
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
		
		log.info("Shutting down");

		selector.close;
	}
}
