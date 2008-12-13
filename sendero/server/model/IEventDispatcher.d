module sendero.server.model.IEventDispatcher;

public import tango.io.selector.model.ISelector;

alias void delegate(ISyncEventDispatcher) EventTaskDg;
interface IEventDispatcher {
    void postTask(EventTaskDg);
}

interface ISyncEventDispatcher : IEventDispatcher {
	void register(ISelectable,Event,EventResponder);
	void unregister(ISelectable);
}

abstract class EventResponder
{
	char[] toString();
    void handleRead(ISyncEventDispatcher);
    void handleWrite(ISyncEventDispatcher);
    void handleDisconnect(ISyncEventDispatcher);
    void handleError(ISyncEventDispatcher);
}