module sendero.server.runtime.SafeRuntime;

import tango.core.Thread;
import tango.stdc.posix.signal;
import tango.stdc.posix.pthread;
import tango.stdc.posix.ucontext;
import tango.stdc.stdlib;

import sendero.server.runtime.SafeThread;

import sendero.server.model.IEventLoop;

debug import tango.io.Stdout;

class SafeRuntime : SafeThreadManager
{		
	this(IEventLoop eventLoop)
	{
		super(eventLoop);
	}
	
	protected sigset_t async_signals;
	
	protected void default_SIGINT_handler(SignalInfo sig)
	{
		Stdout.formatln("Shutting down");
		eventLoop_.shutdown;
		exit(0);
	}
	
	protected void initSignalHandling()
	{
		eventLoop_.setSignalHandler(SIGINT, &default_SIGINT_handler);
		
        /* block all signals */
        sigfillset( &async_signals );
        sigdelset(&async_signals, SIGFPE);
        sigdelset(&async_signals, SIGILL);
        sigdelset(&async_signals, SIGSEGV);
        sigdelset(&async_signals, SIGBUS);
        pthread_sigmask(SIG_BLOCK, &async_signals, null);

        auto signalThread = new Thread(&signalHandlerProc);
        signalThread.start;
        
        registerSyncSignalHandler;
	}
	
	protected void signalHandlerProc()
	{
		int sig;

		while(true) {
			/* wait for async signals */
			sigfillset( &async_signals );
			sigwait( &async_signals, &sig );
	
		    /* when we get this far, we've
		     * caught a signal */
	
			switch(sig)
			{
		    case SIGTERM: return;
		    /* whatever you need to do for
		     * other signals */
	        default:
	        	eventLoop_.sendSignal(new SignalInfo(sig));
	        }
		}
	}
}