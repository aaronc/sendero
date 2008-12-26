module sendero.server.runtime.HeartBeat;

import sendero.server.runtime.SafeThread;
import sendero.server.runtime.SignalInfo;
version(Windows) {
	
}
else {
import tango.stdc.posix.ucontext;
}
import tango.core.Thread;

import tango.util.log.Log;
private Logger log;
static this() {
	log = Log.lookup("sendero.server.runtime.HeartBeat");
}

class HeartBeatThread : SafeWorkerThread
{
	this(void delegate() heartbeatDg)
	{
		this.heartbeatDg = heartbeatDg;
	}
	
	void delegate() heartbeatDg;

	void handleSyncSignal(SignalInfo sig)
	{
version(Windows) { }
else {
		log.error("Attempting to restart HeartBeatThread");
		assert(gotRestartCtxt_, "Unable to restore restart context");
		setcontext(&restart_ctxt_);
}
	}
	
	void doWork()
	{
		Thread.sleep(1);
		heartbeatDg();
	}
}