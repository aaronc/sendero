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

import tango.core.sync.Mutex;
import tango.core.sync.Condition;
import tango.core.Atomic;
import tango.util.log.Log;
import tango.util.log.Configurator;
import tango.text.convert.Sprint;

typedef void function() Task;

class WorkQueue
{
	this()
	{
		frontmtx = new Mutex;
		backmtx = new Mutex;
		emptycond = new Condition(frontmtx);
		_size.store(cast(uint)0);
	}

	//TODO refactor this, has to be a cleaner way
	void pushBack(WQFunctor t)
	{
		backmtx.lock();
		bool wasempty = false;
		WorkNode* n = new WorkNode;
		switch (_size.load())
		{
			case 0:
				frontmtx.lock();
				n.prev = null;
				back = n;
				front = n;
				wasempty = true;
				break;
			case 1:
				front.next = n;
				front.next.prev = front;
			default:
        back.next = n;
				n.prev = back;
				back = n;
		}	
		n.task = t;
		n.next = null;
		_size.increment();

		if (wasempty)
		{
			frontmtx.unlock();
		}

		emptycond.notify();
		backmtx.unlock();
	}

  WQFunctor popFront()
	{
		frontmtx.lock();
		while(_size.load() < 1)
		{
			emptycond.wait();
		}
		if (_size.load() > 1)
		  front.next.prev = null;
		WorkNode* n = front;
	  front = front.next;
		_size.decrement();
		frontmtx.unlock();
		return n.task;
	}

	uint size()
	{
		return _size.load();
	}

	private WorkNode* front;
	private WorkNode* back;

	private Atomic!(uint) _size;
	private Mutex frontmtx;	
	private Mutex backmtx;
	private Condition emptycond;
}

class WQFunctor
{
  void opCall() {}
}

struct WorkNode
{
	WorkNode* next;
	WorkNode* prev;
	WQFunctor task;
}
