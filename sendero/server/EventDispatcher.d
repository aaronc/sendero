module sendero.server.EventDispatcher;

import sendero.server.model.IEventDispatcher;
import sendero.server.model.IEventLoop;
import sendero.util.collection.ThreadSafeQueue;
import sendero.util.collection.SingleReaderQueue;

alias ThreadSafeQueue QueueT;

version(linux) { 
	import tango.sys.Common;
    import tango.sys.linux.linux;
    import tango.stdc.errno;
    import tango.stdc.posix.signal;
}
else {
	import tango.io.selector.Selector;
}
import tango.core.Thread;
import tango.util.log.Log;
import tango.io.selector.model.ISelector;
import tango.stdc.posix.ucontext;

debug import sendero.server.runtime.StackTrace;

static Logger log;

static this()
{
	log = Log.lookup("sendero.server.EventDispatcher");
}

class EventDispatcher : IMainEventLoop, ISyncEventDispatcher
{
	this(ISelector selector = null)
	{
		this.signalQueue = new QueueT!(SignalInfo);
		version(linux) { } else {
			if(selector !is null) this.selector = selector;
			else this.selector = new Selector;
		}
		this.taskQueue = new QueueT!(EventTaskDg);
	}
	
	~this()
    {
		version(linux) {
			 if (epfd_ >= 0)
	         {
	             .close(epfd_);
	             epfd_ = -1;
	         }
		}
    }
	
	private QueueT!(EventTaskDg) taskQueue;
	private QueueT!(SignalInfo) signalQueue;
	version(linux) { 
		private int epfd_ = -1;
        private epoll_event[] events_;
        SelectionKey[ISelectable.Handle] keys_;
	} else {
		private ISelector selector;
	}
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
	
	version(Tango_0_99_7) static ISelectable[ISelectable] registered;
	
	/**
	 * Must be called synchronously!
	 * 
	 * 
	 */
	void register(ISelectable conduit, Event events, EventResponder attachment)
	{
		debug log.trace("Registering ISelectable {} for {}", attachment.toString, events);
		debug assert(Thread.getThis == loopThread_, "unregister should only be called from the event loop thread");
		version(linux) { 
			auto key = conduit.fileHandle() in keys_;

            if (key !is null)
            {
                epoll_event event;

                key.events = events;
                key.attachment = attachment;

                event.events = events;
                event.data.ptr = cast(void*) key;

                if (epoll_ctl(epfd_, EPOLL_CTL_MOD, conduit.fileHandle(), &event) != 0)
                {
                    debug assert(false, "Unable to register epoll event");
                }
            }
            else
            {
                epoll_event     event;
                SelectionKey    newkey = SelectionKey(conduit, events, attachment);

                event.events = events;
                keys_[conduit.fileHandle()] = newkey;
                auto x = conduit.fileHandle in keys_;
                event.data.ptr = cast(void*) x;
                if (epoll_ctl(epfd_, EPOLL_CTL_ADD, conduit.fileHandle(), &event) != 0)
                {
                    keys_.remove(conduit.fileHandle);
                    debug assert(false, "Unable to register epoll event, errno {}");
                }
            }
		} else {
			version(Tango_0_99_7) {
				if(conduit in registered)
					selector.reregister(conduit, events, attachment);
				else {
					selector.register(conduit, events, attachment);
					registered[conduit] = conduit;
				}
			}
			else {
				selector.register(conduit, events, attachment);
			}
		}
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
		version(linux) { 
			 if (conduit !is null)
            {
                if (epoll_ctl(epfd_, EPOLL_CTL_DEL, conduit.fileHandle(), null) == 0)
                {
                    keys_.remove(conduit.fileHandle());
                }
                else
                {
                	debug assert(false, "Unable to unregister epoll event, errno {}");
                }
            }
		} else {
			
			selector.unregister(conduit);
		}
	}
	
	void sendSignal(SignalInfo sig)
	{
		signalQueue.push(sig);
	}
	
	SignalHandler setSignalHandler(int signal, SignalHandler dg)
	{
		auto pExistingHandler = signal in signalHandlers_;
		signalHandlers_[signal] = dg;
		if(pExistingHandler !is null) return *pExistingHandler;
		else return null;
	}
	
	SignalHandler unsetSignalHandler(int signal)
	{
		auto pExistingHandler = signal in signalHandlers_;
		signalHandlers_.remove(signal);
		if(pExistingHandler !is null) return *pExistingHandler;
		else return null;
	}
	
	private SignalHandler[int] signalHandlers_;
	
	void open(uint size, uint maxEvents)
	{
		assert(!opened_, "EventDispatcher should be opened only once");
		version(linux) { 
			events_ = new epoll_event[maxEvents];
			epfd_ = epoll_create(cast(int)size);
			assert(epfd_ >= 0, "Unable to start epoll, errno {}");
		} else {
			selector.open(size, maxEvents);
		}
		opened_ = true;
	}
	
	void shutdown()
	{
		running_ = false;
	}
	
	public bool inbeat = false, outbeat = false;
	private ucontext_t restart_ctxt_;
	private bool gotRestartCtxt_ = false;
	
	void handleSyncSignal(SignalInfo sig)
	{
		assert(gotRestartCtxt_, "Don't have restart context");
		setcontext(&restart_ctxt_);
	}
	
	void run()
	{
		assert(opened_,"EventDispatcher.open must be called before run");
		assert(!running_, "Only one instance of the event loop should be called at a time");
		running_ = true;
		loopThread_ = Thread.getThis;
		
		assert(getcontext(&restart_ctxt_) == 0);
		gotRestartCtxt_ = true;
		
		while(running_) {
			try
			{
				inbeat = true;
				
				auto sig = signalQueue.pull;
				while(sig !is null && running_) {
					auto pHandler = sig.signal in signalHandlers_;
					if(pHandler) (*pHandler)(sig);
					else log.warn("Received signal {}, but have no handler", sig.signal);
					sig = signalQueue.pull;
				}
				
				version(linux) {
					int evntCnt;
					while (true)
		            {
		                // FIXME: add support for the wakeup() call.
		                evntCnt = epoll_wait(epfd_, events_.ptr, events_.length, 
		                	cast(int)TimeSpan.fromInterval(timeout).millis);
		                if (evntCnt >= 0)
		                {
		                    break;
		                }
		                else
		                {
		                    if (errno != EINTR)
		                    {
		                        debug assert(false, "epoll_wait failed, errno {}");
		                    }
		                    debug log.warn("Restarting epoll_wait after failure");
		                }
		            }
		                
	                foreach(event; events_[0..evntCnt])
	                {
	                	if(!running_) break;
	                	
	                	if(event.events == 0) continue;
	                	debug log.trace("Found some events {}",event.events);
	                	auto key = *(cast(SelectionKey *)event.data.ptr);
	                    key.events = cast(Event) event.events;
						
						auto responder = cast(EventResponder)key.attachment;
						debug assert(responder);
						if(key.isReadable)
						{
							debug log.trace("Read event for responder {}", responder.toString);
							responder.handleRead(this);
							//debug log.trace("{}",StackTrace.get.toString);
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
				} else {
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
								//debug log.trace("{}",StackTrace.get.toString);
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
				
				auto task = taskQueue.pull;
				while(task !is null && running_) {
					debug log.trace("Running task");
					task(this);
					task = taskQueue.pull;
				}
				
				outbeat = true;
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

		version(linux) {}
		else {
			selector.close;
		}
	}
}
