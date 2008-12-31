module sendero.server.buffer.SingleThreadBufferPool;

class BufferProvider
{
	this(uint defaultBufferSize = 16384, uint cacheSize = 100)
	{
		this.bufferPool_ = new ThreadSafeQueue!(void[]);
		this.defaultBufferSize_ = defaultBufferSize;
	}
	
	uint defaultBufferSize() { return defaultBufferSize_; }
	void defaultBufferSize(uint sz) { defaultBufferSize_ = sz; }
	
	void[] get()
	{
	}
	
	void release(void[] buf)
	{
	}
private:
	void*[void*] bufferPtrMap_;
}