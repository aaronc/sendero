/** 
 * Copyright: Copyright (C) 2007 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.util.collection.ThreadSafeQueue;

debug import tango.util.log.Log;

/**
 * A new simpler - possibly less performant, but reliable ThreadSafeQueue.
 */
class ThreadSafeQueue(T)
{
	debug {
		static Logger log;

		static this()
		{
			log = Log.lookup("sendero.util.collection.ThreadSafeQueue!(" ~ T.stringof ~ ")");
			log.level(log.Trace);
		}
	}
	
	void push(T t)
	{
		assert(t !is null);
		doPushPop(t);
	}
	
	T pop()
	{
		return doPushPop;
	}
	
private:
	synchronized T doPushPop(T t = null)
	{
		//debug log.trace("Doing push pop");
		if(t !is null) {
			debug log.trace("Doing push");
			if(tail !is null) {
				debug log.trace("Non-null tail");
				auto next = new Node(t);
				tail.next = next;
				tail = next;
			}
			else {
				debug log.trace("Null tail");
				assert(head is null);
				head = new Node(t);
				tail = head;
				debug log.trace("Done adding head");
			}
		}
		else if(head !is null) {
			debug log.trace("Doing pop");
			t = head.t;
			if(head == tail) {
				debug log.trace("head == tail");
				head = null;
				tail = null;
			}
			else {
				debug log.trace("head != tail");
				head = head.next;
			}
			return t;
		}
		return null;
	}
	
	class Node
	{
		this(T t)
		{
			this.t = t;
		}
		
		T t;
		Node next = null;
	}
	Node head = null;
	Node tail = null;
}

class Test
{
	
}

unittest
{
	auto queue = new ThreadSafeQueue!(Test);
	queue.push(new Test);
	queue.push(new Test);
	queue.push(new Test);
	assert(queue.pop !is null);
	assert(queue.pop !is null);
	assert(queue.pop !is null);
	queue.push(new Test);
	assert(queue.pop !is null);
	assert(queue.pop is null);
}