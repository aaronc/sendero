module sendero.util.collection.ThreadSafeQueue;

import tango.core.Atomic;

class ThreadSafeQueue(T)
{	
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
	
	static void enqueue(T t)
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
	
	uint length()
	{
		return atomicLoad(size);
	}
}