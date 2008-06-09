/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.session.GC;

import sendero.util.BufferPool;

import tango.core.Thread;
import tango.core.Memory;

class SessionHeapTemplate(size_t size = ushort.max)
{
	static this()
	{
		heapPool = new ConnectionPool!(void*, BufferProvider!(size));
	}
	static ConnectionPool!(void*, BufferProvider!(size)) heapPool;
	
	this()
	{
		buffer = heapPool.get;
		end = buffer + size;
		ptr = buffer;
	}
	
	~this()
	{
		heapPool.release(buffer);
		foreach(b; buffers)
			heapPool.release(b);
	}
	
	private void* buffer;
	private void* ptr;
	private void* end;
	private void*[] buffers;
	private void* function(size_t) surrogate;
	
	void activate()
	{
		surrogate = null;
	}
	
	void deactivate()
	{
		surrogate = cast(void* function(size_t))&GC.malloc;
	}
	
	void setSurrogate(void* function(size_t) allocator)
	{
		surrogate = allocator;
	}
	
	void* allocate(size_t sz)
    {
		if(surrogate)
			return surrogate(sz);
		
		if(sz < end - ptr) {
			void* p = ptr;
			ptr += sz;
			return p;
		}
		else {
			buffers ~= buffer;
			buffer = heapPool.get;
			end = buffer + size;
			ptr = buffer;
			return allocate(sz);
		}
    }
	
	void reset()
	{
		ptr = buffer;
		foreach(b; buffers)
			heapPool.release(b);
	}
}

class SessionGCTemplate(size_t size = ushort.max)
{
	private static ThreadLocal!(SessionHeapTemplate!(size)) sessionHeaps;
	static this()
	{
		sessionHeaps = new ThreadLocal!(SessionHeapTemplate!(size));
	}
	
	static void* allocate(size_t sz)
	{
		return sessionHeaps.val.allocate(sz);
	}
	
	static void reset()
	{
		if(!sessionHeaps.val) sessionHeaps.val = new SessionHeapTemplate!(size);
		sessionHeaps.val.reset;
	}
	
	static void activate()
	{
		sessionHeaps.val.activate;
	}
	
	static void deactivate()
	{
		sessionHeaps.val.deactivate;
	}
	
	static void setSurrogate(void* function(size_t) allocator)
	{
		sessionHeaps.val.setSurrogate(allocator);
	}
}

alias SessionGCTemplate!() SessionGC;

unittest
{
	
}