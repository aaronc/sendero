module sendero.server.runtime.SafeThreadManager;

/*
Synchronous Signals:

SIGBUS
SIGFPE
SIGSEGV
SIGILL
SIGSYS
*/

import tango.core.Thread;
import tango.stdc.posix.signal;
import tango.stdc.posix.pthread;
import tango.stdc.posix.ucontext;

import sendero.server.model.IEventLoop;
import sendero.server.runtime.StackTrace;

import tango.util.log.Log;
private Logger log;
static this()
{
	log = Log.lookup("sender.server.runtime.SafeThreadManager");
}

class SafeThreadManager
{
	this(IEventLoop eventLoop)
	{
		eventLoop_ = eventLoop;
		initSignalHandling();
	}
	
	static SafeThreadManager[size_t] runtimeByThread_;
	protected IEventLoop eventLoop_;
	
	extern(C) static protected void syncSigHandler(int sig, siginfo_t* info, void* context)
	{
		try
		{
			//Stdout.formatln("Caught signal {} on thread {}", sig, context, pthread_self());
			log.error("Caught signal {} on thread {}", sig, cast(ulong)pthread_self());
			doStackTrace;
			auto pRuntime = pthread_self in runtimeByThread_;
			if(pRuntime) {
				try
				{
					pRuntime.eventLoop_.handleSyncSignal(new SignalInfo(sig));
				}
				catch(Exception ex)
				{
					log.fatal("Fatal exception {} encountered when "
							"trying to recover from signal {}. Shutting down thread.",
						ex.toString, sig);
					pRuntime.eventLoop_.shutdown;
				}
			}
		}
		catch(Exception ex)
		{
			log.fatal("Fatal exception {} encountered when trying to recover "
					"from signal {}. Can't recover or shut down threadcleanly.",
					ex.toString, sig);
		}
	}
	
	protected void registerSyncSignalHandler()
	{
		log.info("Registering sync signal handlers on thread {}", pthread_self);
		runtimeByThread_[pthread_self] = this;
		
		sigset_t sync_signals;
		
		sigemptyset( &sync_signals );
		sigaddset(&sync_signals, SIGFPE);
		sigaddset(&sync_signals, SIGILL);
		sigaddset(&sync_signals, SIGSEGV);
		sigaddset(&sync_signals, SIGBUS);
		
		ucontext_t context;
		assert(getcontext(&context) == 0);
		
		sigaction_t action;
		action.sa_mask = sync_signals;
		action.sa_flags = SA_SIGINFO;
		action.sa_sigaction = &syncSigHandler;
		sigaction(SIGSEGV, &action, null);
	}
	
	static void doStackTrace()
	{
		try
		{
			auto trace = StackTrace.get;
			log.error("Thread {} {} ", cast(ulong)pthread_self, trace.toString);
		}
		catch(Exception ex)
		{
			log.error("Exception performing stacktrace {}", ex.toString);
		}
	}
	
	protected void initSignalHandling()
	{
		registerSyncSignalHandler;
		//doStackTrace;
	}
}