module sendero.server.io.StagedReadBuffer;

import sendero.server.io.SingleThreadCachedBuffer;

class StagedReadBuffer : SingleThreadCachedBuffer
{
	this(void[] buffer)
	{
		super(buffer);
		index_ = 0;
		released_ = false;
	}
	
	private size_t index_;
	private StagedReadBuffer next_; 
	
	final size_t writeable() {
		return buffer.length - index_;
	}
	
	final size_t readable() {
		return index_;
	}
	
	final void[] getWritable()
	{
		assert(!released_);
		return buffer[index_ .. $];
	}
	
	final void[] getReadable() {
		assert(!released_);
		return buffer[0 .. index_];
	}
	
	final void setNext(StagedReadBuffer buf) {
		next_ = buf;
	}
	
	final StagedReadBuffer getNext() {
		return next_;
	}
	
	final void advanceWritten(size_t n)
	{
		assert(!released_);
		index_ += n;
	}
}

alias AbstractSingleThreadBufferPool!(StagedReadBuffer) StagedReadBufferPool;

/+
class StagedReadBufferPool : SingleThreadObjectPool!(StagedReadBuffer)
{
	static const size_t DefaultBufferSize = 32768;
	
	this(size_t bufferSize = DefaultBufferSize, uint maxCacheSize = 100, uint preAllocSize = 10)
	{
		bufferSize_ = bufferSize;
		super(maxCacheSize,preAllocSize);
	}
	
	override protected StagedReadBuffer create()
	{
		return new StagedReadBuffer(new void[bufferSize_]);
	}
private:
	size_t bufferSize_;
}+/