module sendero.server.model.IEventLoop;

public import sendero.server.runtime.SignalInfo;

interface IEventLoop {
	void run();
	void shutdown();
	//void restart();
	void handleSyncSignal(SignalInfo sig);
}

interface IMainEventLoop : IEventLoop, ISignalSync {
	
}