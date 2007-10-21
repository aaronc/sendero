/**
 * Copyright: Copyright (C) 2007 Rick Richardson.  All rights reserved.
 * License:   BSD Style
 * Authors:   Rick Richardson
 */



// Queue class built to be accessed by a thread pool. Offers thread safe 
// access to standard queue features as well as the ability for threads to
// sleep if the queue is empty and be woken when something shows up. 
// The condition sleep/wake functionality is abstracted from the customer by this
// interface

module sendero.util.WorkQueue;
import tango.core.Thread;
import tango.core.sync.Mutex;
import tango.core.sync.Condition;
import tango.core.Atomic;
import tango.util.log.Log;
import tango.util.log.Configurator;
import tango.text.convert.Sprint;
import tango.io.Stdout;
import tango.core.Thread;

class WorkQueue(T)
{
	this()
	{
		sprint = new Sprint!(char);
		lock = new Mutex;
		emptycond = new Condition(lock);
		logger = Log.getLogger("WorkQueue");
		_size.store(cast(uint)0);
		root = new WorkNode;
		root.next = root;
		root.prev = root;
	}

	void pushBack(T obj)
	{
		WorkNode* n = new WorkNode;
	  n.data = obj;

		lock.lock();

		_size.increment();
		n.prev = root.prev;
		n.next = root;
		root.prev.next = n;
		root.prev = n;

		lock.unlock();
		emptycond.notify();
	}

  T popFront()
	{
		lock.lock();
		while(_size.load() < 1)
		{
			emptycond.wait();
		}
		logger.info(sprint("Thread: {} done waiting on size", Thread.getThis().name()));

		_size.decrement();

		WorkNode *n = root.next;
		root.next = n.next;
		root.next.prev = root;
		lock.unlock();
		return n.data;
	}

	T tryPopFront()
	{
		lock.lock();
		scope(exit) lock.unlock();
		if (_size.load() < 1)
		{
			return cast(T)(null);
		}
		_size.decrement();
		WorkNode *n = root.next;
		root.next = n.next;
		root.next.prev = root;

		return n.data;
	}

	//this is a course lock, but it serves the purposes of
	//the server better, the foreach is used by the selector
	//to re-assign sockets and events
	int opApply(int delegate(inout T) dg)
	{
		if (_size.load() < 1)
			return 0;

		lock.lock();
		scope(exit) lock.unlock();
		int rc;
		int max = _size.load();
		for(int i = 0; i < max; ++i)
		{
			_size.decrement();
			WorkNode *n = root.next;
			root.next = n.next;
			root.next.prev = root;
			rc = dg(n.data);
			//if (rc)
			//	break;
		}
		return rc;
	}

	uint size()
	{
		return _size.load();
	}

	private WorkNode* root;
  private Sprint!(char) sprint;
	private Atomic!(uint) _size;
	private Mutex lock;	
	private Condition emptycond;
  Logger logger;

	struct WorkNode
	{
		WorkNode* next;
		WorkNode* prev;
		T data;
	}
}

version(unit)
{
	void main()
	{
		auto wq = new WorkQueue!(int);
		wq.pushBack(1);
		wq.pushBack(2);
		Stdout.formatln("size = {}", wq.size());
		wq.pushBack(3);
		wq.pushBack(4);
		Stdout.formatln("size {}", wq.size());
		Stdout.formatln("1- {}", wq.popFront());
		Stdout.formatln("1- {}", wq.popFront());
		Stdout.formatln("size = {}", wq.size());
		Stdout.formatln("1- {}",wq.popFront());
		Stdout.formatln("1- {}",wq.popFront());
		Stdout.formatln("1- {}",wq.tryPopFront());
		Stdout.formatln("We should not be here");

		wq.pushBack(1);
		wq.pushBack(2);
		wq.pushBack(3);
		wq.pushBack(4);
		wq.pushBack(5);
		wq.pushBack(6);
		wq.pushBack(7);
		Stdout.formatln("size = {}", wq.size());
		foreach(i; wq)
		{
			Stdout.formatln("forloop - {}", i);
		}
		foreach(i; wq)
		{
			Stdout.formatln("forloop2 - {}", i);
		}
		foreach(i; wq)
		{
			Stdout.formatln("forloop3 - {}", i);
		}
	}
}
