module sendero.util.collection.ThreadSafeQueue;

import tango.core.Atomic;
import tango.util.log.Log;

/**
 * Thread-Safe Queue class that uses synchronization and some atomic(non-locking) operations.
 * Basically objects can be added and removed from the queue simultaneously.
 * However, readers must wait for each other and writers must wait for each other.
 */
class ThreadSafeQueue(T)
{	
	private static Logger debugLog;
	static this()
	{
		debugLog = Log.getLogger("debug.sendero.util.collection.ThreadSafeQueue!(" ~ T.stringof ~ ")");
	}
	
	private static class Node
	{
		T t;
		Atomic!(Node) next;
	}
	private static uint size = 0;
	private static Atomic!(Node) qHead;
	private static Atomic!(Node) qTail;
	
	static this()
	{
		qHead.store!(msync.seq)(null);
		qTail.store!(msync.seq)(null);
	}
	
	static T dequeue()
	{
		try
		{
			auto head = qHead.load!(msync.seq);
			if(head) {
				synchronized {
					head = qHead.load!(msync.seq);
					if(head) {
						T t = head.t;
						auto next = head.next.load!(msync.seq);
						if(next) {
							qHead.store!(msync.seq)(next);
						}
						else {
							if(qTail.storeIf!(msync.seq)(null, head))
								qHead.storeIf!(msync.seq)(null, head);
						}
						atomicDecrement(size);
						return t;
					}
				}
			}
			return null;
		}
		catch(Exception ex)
		{
			debugLog.error("dequeue exception " ~ ex.toUtf8);
			return null;
		}
	}
	
	static void enqueue(T t)
	{	
		try
		{
			synchronized
			{			
				auto next = new Node;
				next.next.store!(msync.seq)(null);
				next.t = t;
				
				void doHead()
				{
					qTail.store!(msync.seq)(next);
					qHead.store!(msync.seq)(next);
				}
				
				scope tail = qTail.load!(msync.seq);
				if(!tail) {
					doHead;	
				}
				else {
					tail.next.store!(msync.seq)(next);
					if(!qTail.storeIf!(msync.seq)(next, tail))
						doHead;
				}
				atomicIncrement(size);
			}
		}
		catch(Exception ex)
		{
			debugLog.error("enqueue exception " ~ ex.toUtf8);
		}
	}
	
	uint length()
	{
		return atomicLoad(size);
	}
}