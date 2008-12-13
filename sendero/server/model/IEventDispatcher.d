module sendero.server.model.IEventDispatcher;

public import tango.io.selector.model.ISelector;

interface IEventDispatcher {
    void postTask(TaskDg);
}

interface ISyncEventDispatcher {
	void register(ISelector,Event,ITaskResponder);
	void unregister(ISelector);
}

alias void delegate(ISyncEventDispatcher) TaskDg;

interface ITaskResponder
{
	char[] toString();
    void handleRead(ISyncEventDispatcher);
    void handleWrite(ISyncEventDispatcher);
    void handleDisconnect(ISyncEventDispatcher);
    void handleError(ISyncEventDispatcher);
}