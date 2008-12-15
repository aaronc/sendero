module sendero.server.runtime.SafeThread;

import sendero.server.runtime.SafeThreadManager;

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
	
	protected bool running_ = false;
	protected bool gotRestartCtxt_ = false;
	protected ucontext_t restart_ctxt_;
	void handleSyncSignal(SignalInfo sig)
	{
		pthread_exit(null);
		/+assert(gotRestartCtxt_, "Unable to restore restart context");
		setcontext(&restart_ctxt_);+/
	}
	
	abstract protected void doWork();
	
	void run() {
		auto threadManager = new SafeThreadManager(this);
		assert(getcontext(&restart_ctxt_) == 0);
		gotRestartCtxt_ = true;
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