module sendero.server.io.CachedBuffer;

public import sendero.server.io.model.ICachedBuffer;

/+
class WriteBuffer
{
	enum State { Open, Closed, Cached };
	private State state_;
	
	void[] buffer;
}
+/

abstract class CachedBuffer : ICachedBuffer
{
	abstract void release();
	void[] getBuffer()
	{
		return buffer;
	}
	
	void[] buffer;
}

class NotCachedBuffer : CachedBuffer
{
	this(void[] buf)
	{
		this.buffer = buf;
	}
	
	void release()
	{
		
	}
}
