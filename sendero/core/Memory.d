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
