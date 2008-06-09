/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.util.CachedBuffer;

import sendero.util.BufferPool;

class CachedBuffer(size_t size = ushort.max) : OutputStream
{
	static this()
	{
		bufferPool = new ConnectionPool!(void[], BufferProvider);
	}
	static ConnectionPool!(void[], BufferProvider!(size)) bufferPool;
	
	this()
	{
		buffers ~= bufferPool.getConnection[0 .. size];
	}
	
	~this()
	{
		foreach(b; buffers)
			bufferPool.releaseConnection(b.ptr);
	}
	
	void[][] buffers;
	
	uint bufNum;
	uint index;
	
	IConduit conduit () { return null; }
	
	void close() {}
	
	private uint writable()
	{
		return buffers[bufNum].length - index;
	}
	
	void clear()
	{
		if(buffers.length > 1) {
			for(uint i = 1; i < buffers.length; ++i)
			{
				bufferPool.releaseConnection(buffers[i]);
			}
		}
		buffers.length = 1;
		index = 0;
		bufNum = 0;
	}
	
	uint write(void[] src)
	{
		uint x = writable;
		if(src.length <= x) {
			buffers[bufNum][index .. index + src.length] = src;
			index += src.length;
			return src.length;
		}
		else {
			uint pos = 0;
			
			buffers[bufNum][index .. x] = src[pos .. x];
			pos += x;
			
			while(pos < src.length) {
				buffers ~= bufferPool.getConnection;
				++bufNum;
				x = writable;
				buffers[bufNum][index .. x] = src[pos .. x];
				pos += x;
			}
		}		
	}
	
	OutputStream copy(InputStream src)
	{
		auto copied = src.read(array[n .. array.length]);
		if(copied == IOStream.Eof) throw new IOException("Error when copying InputStream in StringWriter");
		n += copied;
		return this;
	}
	
	OutputStream flush() { return this; }
}