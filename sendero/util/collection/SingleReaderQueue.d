module sendero.util.collection.SingleReaderQueue;

import tango.core.Atomic;
import tango.stdc.stdlib;

import tango.util.log.Log;
Logger log;
static this() {
	log = Log.lookup("SingleReaderQueue");
}

class SingleReaderQueue(T)
{
	this(uint initSize = 1000)
	{
		head = cast(Node*)malloc(Node.sizeof);
		auto cur = head;
		for(uint i = 1; i < initSize; ++i)
		{
			cur.next = cast(Node*)malloc(Node.sizeof);
			cur = cur.next;
		}
		cur.next = head;
		tail = head;
	}
	
	final T pull()
	{
		if(head == tail) return null;
		auto item = head;
		atomicStore(head, head.next);
		return item.t;
	}
	
	final void push(T t)
	{
		Node* curTail;
		do {
			while(tail.next == head) {}
			curTail = tail;
		}
		while(!atomicStoreIf(tail, tail.next, curTail))
		curTail.t = t;
		//log.trace("Pushed {}",t.i);
	}
	
private:
	Node* head;
	Node* tail;
	static struct Node
	{
		T t;
		Node* next;
	}
}

debug(SenderoUnittest) {
	import tango.core.Thread;
	import tango.util.log.Config;
	
	class Test
	{
		this(uint i) { this.i = i; }
		uint i;
	}
	
	SingleReaderQueue!(Test) queue;
	
	bool running = false;
	void readThread()
	{
		while(running) {
			auto test = queue.pull;
			if(test) log.trace("Pulled {}",test.i);
		}
	}
	
	void writeThread(uint x)()
	{
		queue.push(new Test(x));
		//Thread.sleep(0.0001);
		queue.push(new Test(x));
		//Thread.sleep(0.001);
		queue.push(new Test(x));
	}
	
	unittest
	{
		queue = new typeof(queue);
		running = true;
		auto thr = new Thread(&readThread);
		thr.start;
		
		auto t1 = new Thread(&writeThread!(1));
		auto t2 = new Thread(&writeThread!(2));
		auto t3 = new Thread(&writeThread!(3));
		t1.start;
		t2.start;
		t3.start;
		
		Thread.sleep(0.5);
		
		running = false;
	}
}