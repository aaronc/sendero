module sendero.server.runtime.SafeRuntime;

import tango.core.Thread;
import tango.stdc.stdlib;

import sendero.server.runtime.SafeThreadManager;
import sendero.server.runtime.SafeThread;

import sendero.server.model.IEventLoop;

import tango.io.Stdout;
import tango.util.log.Log;
private Logger log;
static this() {
	log = Log.lookup("sendero.server.runtime.SafeRuntime");
}

version(Windows) {
	
class SafeRuntime : SafeThreadManager
{		
	this(IMainEventLoop mainEventLoop)
	{
		super(mainEventLoop);
	}
}

}
else {

import tango.stdc.posix.signal;
import tango.stdc.posix.pthread;
import tango.stdc.posix.ucontext;
	
class SafeRuntimeThread : SafeWorkerThread
{
	this(SafeRuntime runtime)
	{
		this.runtime = runtime;
	}
	
	protected SafeRuntime runtime;

	void handleSyncSignal(SignalInfo sig)
	{
		log.error("Attempting to restart SafeWorkerThread");
		assert(gotRestartCtxt_, "Unable to restore restart context");
		setcontext(&restart_ctxt_);
	}
	
	protected void doWork()
	{
		int sig;

		/* wait for async signals */
		sigfillset( &runtime.async_signals );
		sigwait( &runtime.async_signals, &sig );

	    /* when we get this far, we've
	     * caught a signal */

		switch(sig)
		{
	    case SIGTERM: return;
	    /* whatever you need to do for
	     * other signals */
        default:
        	auto pHandler = sig in runtime.signalHandlers_;
        	if(pHandler) (*pHandler)(new SignalInfo(sig)); 
        	else runtime.mainEventLoop_.sendSignal(new SignalInfo(sig));
        	break;
        }
	}
}

class SafeRuntime : SafeThreadManager
{		
	this(IMainEventLoop mainEventLoop)
	{
		mainEventLoop_ = mainEventLoop;
		super(mainEventLoop);
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
	
	protected IMainEventLoop mainEventLoop_;
	protected sigset_t async_signals;
	
	protected void default_SIGINT_handler(SignalInfo sig)
	{
		Stdout.formatln("Shutting down");
		eventLoop_.shutdown;
		exit(0);
	}
	
	protected void initSignalHandling()
	{
		//mainEventLoop_.setSignalHandler(SIGINT, &default_SIGINT_handler);
		setSignalHandler(SIGINT, &default_SIGINT_handler);
		
        /* block all signals */
        sigfillset( &async_signals );
        sigdelset(&async_signals, SIGFPE);
        sigdelset(&async_signals, SIGILL);
        sigdelset(&async_signals, SIGSEGV);
        sigdelset(&async_signals, SIGBUS);
        pthread_sigmask(SIG_BLOCK, &async_signals, null);

        auto signalThread = new SafeRuntimeThread(this);
        signalThread.start;
        
        registerSyncSignalHandler;
	}
	
	
}

}