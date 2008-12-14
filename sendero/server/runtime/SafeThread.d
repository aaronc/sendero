module sendero.server.runtime.SafeThread;

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

debug import tango.io.Stdout;

abstract class SafeWorkerThread : Thread, IEventLoop
{
	this()
	{
		super(&this.run);
	}
	
	private bool running_ = false;
	
	private ucontext_t restart_ctxt_;
	void handleSyncSignal(SignalInfo sig)
	{
		setcontext(&restart_ctxt_);
	}
	
	abstract protected void doWork();
	
	void run() {
		assert(getcontext(&restart_ctxt_) == 0);
		auto threadManager = new SafeThreadManager(this);
		running_ = true;
		while(running_) {
			doWork;
		}
	}
	
	void shutdown()
	{
		running_ = false;
	}
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
		Stdout.formatln("Caught signal {} on thread {}", sig, context, pthread_self());
		auto pRuntime = pthread_self in runtimeByThread_;
		if(pRuntime) {
			pRuntime.eventLoop_.handleSyncSignal(new SignalInfo(sig));
		}
	}
	
	protected void registerSyncSignalHandler()
	{
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
	
	protected void initSignalHandling()
	{
		registerSyncSignalHandler;
	}
}