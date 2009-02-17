module sendero.server.io.CachedBuffer;

public import sendero.server.io.model.ICachedBuffer;

abstract class CachedBuffer : ICachedBuffer
{
	this(void[] buffer)
	{
		this.buffer = buffer;
	}
	
	abstract void release();
	final void[] getBuffer()
	{
		return buffer;
	}
	
	final ICachedBuffer getNext() { return next; }
	final void setNext(ICachedBuffer buf) { next = buf; }
	
	void[] buffer;
	
	ICachedBuffer next;
}

class NotCachedBuffer : CachedBuffer
{
	this(void[] buf)
	{
		this.buffer = buf;
	}
	
	final void release()
	{
		
	}
}