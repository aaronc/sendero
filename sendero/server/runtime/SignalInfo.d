module sendero.server.runtime.SignalInfo;

class SignalInfo
{
	this(int signal)
	{
		this.signal = signal;
	}
	
	int signal;
}

interface ISignalSync
{
	void sendSignal(SignalInfo signal);
    SignalHandler setSignalHandler(int signal, SignalHandler dg);
    SignalHandler unsetSignalHandler(int signal);
}

alias void delegate(SignalInfo signal) SignalHandler;