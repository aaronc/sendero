/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.core.Memory;

version(SenderoSessionGC)
{
	import sendero.session.GC;
}

import tango.core.Memory;

struct DefaultAllocator
{
	static void* allocate(size_t sz)
	{
		return GC.malloc(sz);
	}
}

struct SessionAllocator
{
	static void* allocate(size_t sz)
	{
		version(SenderoSessionGC)
		{
			return SessionGC.allocate(sz);
		}
		else
		{
			return GC.malloc(sz);
		}
	}
}

struct ContainerSessionAllocator(T)
{
	T* allocate()
	{
		return SessionAllocator.allocate(T.sizeof);
	}
	
	T*[] allocate(uint count)
	{
		auto sz = T.sizeof * count;
		auto ptr = SessionAllocator.allocate(sz);
		auto res = (cast(T**)(SessionAllocator.allocate(ptrdiff_t.sizeof * count)))[0 .. count];
		auto end = ptr + sz;
		uint i = 0;
		while(ptr < end)
		{
			res[i] = ptr;
			ptr += T.sizeof;
			++i;
		}
		debug assert(i == count);
		return res;
	}
	
	void collect(T* p)
	{ }
	
	void collect(T*[] t)
	{ }
	
	bool collect(bool all = true)
	{ }
}

template SessionAllocate()
{
	new(size_t sz)
    {
		version(SenderoSessionGC)
		{
			return SessionGC.allocate(sz);
		}
		else
		{
			return GC.malloc(sz);
		}
    }
}

abstract class SessionObject
{
	mixin SessionAllocate!();
}
