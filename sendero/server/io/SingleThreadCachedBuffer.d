module sendero.server.io.SingleThreadCachedBuffer;

public import sendero.server.io.CachedBuffer;
import sendero.server.util.SingleThreadObjectPool;

class SingleThreadCachedBuffer : CachedBuffer
{
	this(void[] buffer)
	{
		super(buffer);
	}
	
	protected bool released_;
	
	final void release()
	{
		released_ = true;
	}
}

class AbstractSingleThreadBufferPool(BufferT) : SingleThreadObjectPool!(BufferT)
{
	static const size_t DefaultBufferSize = 32768;
	
	this(size_t bufferSize = DefaultBufferSize, uint maxCacheSize = 100, uint preAllocSize = 10)
	{
		bufferSize_ = bufferSize;
		super(maxCacheSize,preAllocSize);
	}
	
	override protected BufferT create()
	{
		return new BufferT(new void[bufferSize_]);
	}
	
	alias BufferT BufferT;
	
	
private:
	size_t bufferSize_;
}

alias AbstractSingleThreadBufferPool!(SingleThreadCachedBuffer) SingleThreadBufferPool;
