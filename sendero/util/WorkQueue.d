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

class WorkQueue(T)
{
	this()
	{
		sprint = new Sprint!(char);
		frontmtx = new Mutex;
		backmtx = new Mutex;
		emptycond = new Condition(frontmtx);
		logger = Log.getLogger("sendero.util.WorkQueue");
	}

	//TODO refactor this, has to be a cleaner way
	void pushBack(T* obj)
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
		n.data = obj;
		n.next = null;
		_size.increment();
    logger.info(sprint("blah {}", _size.load()));
		if (wasempty)
		{
			frontmtx.unlock();
		}

		emptycond.notify();
		backmtx.unlock();
	}

  T* popFront()
	{
		logger.info("top of popFront");
		frontmtx.lock();
		while(_size.load() < 1)
		{
			emptycond.wait();
		}
		if (_size.load() > 1)
		  front.next.prev = null;
		_size.decrement();
		logger.info(sprint("_size is now {}", _size.load()));
		WorkNode* n = front;
	  front = front.next;
		frontmtx.unlock();
		logger.info(sprint("Thread ID {}", Thread.getThis().name()));
		logger.info("done with popFront");
		return n.data;
	}

	T* tryPopFront()
	{
		if (_size.load() == 0)
		{
			logger.info("queue empty, returning null");
			return null;
		}
		frontmtx.lock();
		if (_size.load() > 1)
		  front.next.prev = null;
		_size.decrement();
		WorkNode* n = front;
	  front = front.next;
		frontmtx.unlock();
		
		logger.info("CHECKING NULL");
		if (n.data is null)
			logger.info("tryPopFront task is null");
		
		return n.data;
	}

	uint size()
	{
		return _size.load();
	}

	private WorkNode* front;
	private WorkNode* back;
  private Sprint!(char) sprint;
	private Atomic!(uint) _size;
	private Mutex frontmtx;	
	private Mutex backmtx;
	private Condition emptycond;
  Logger logger;

	struct WorkNode
	{
		WorkNode* next;
		WorkNode* prev;
		T* data;
	}
}


