module sendero.util.BufferPool;

public import sendero.util.ConnectionPool;

import tango.stdc.stdlib;

class BufferProvider(size_t size = ushort.max)
{
	static void* createNewConnection()
	{
		return malloc(size);
	}
	
	static void release(void* buf)
	{
		free(buf);
	}
}