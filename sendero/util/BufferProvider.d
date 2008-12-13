module sendero.util.BufferProvider;

import sendero.util.collection.ThreadSafeQueue;

import tango.core.Atomic;

class BufferProvider
{
	this(defaultBufferSize = 16384)
	{
		this.defaultBufferSize_ = defaultBufferSize;
	}
	
	uint defaultBufferSize() { return defaultBufferSize_; }
	void defaultBufferSize(uint sz) { defaultBufferSize_ = sz; }
	
	uint maxCacheSize() { return maxCacheSize_; }
	void maxCacheSize(uint sz) { maxCacheSize_ = sz; }	
	
	void[] get()
	{
		auto buf = bufferPool_.pop;
		if(buf.length) {
			atomicDecrement(cacheSize_);
			return buf;
		}
		else return new void[sz];
	}
	
	void release(void[] buf)
	{
		if(atomicLoad(cacheSize_) < maxCacheSize_) {
			bufferPool_.push(buf);
			atomicIncrement(cacheSize_);
		}
	}
	
	uint cacheSize()
	{
		return cacheSize_;
	}
	
private:
	ThreadSafeQueue2!(void[]) bufferPool_;
	uint defaultBufferSize_;
	uint maxCacheSize_ = 100;
	uint cacheSize_;
}