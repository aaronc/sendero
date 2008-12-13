module sendero.util.BufferProvider;

import sendero.util.collection.ThreadSafeQueue;

import tango.core.Atomic;

class BufferProvider
{
	this(uint defaultBufferSize = 16384)
	{
		this.bufferPool_ = new ThreadSafeQueue2!(void[]);
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
			bufferPtrMap_.remove(buf.ptr);
			return buf;
		}
		else return new void[defaultBufferSize_];
	}
	
	void release(void[] buf)
	{
		if(atomicLoad(cacheSize_) < maxCacheSize_) {
			auto pBuf = buf.ptr in bufferPtrMap_;
			if(pBuf) {
				throw new Exception("Trying to place buffer in the pool a second time");
			}
			bufferPool_.push(buf);
			bufferPtrMap_[buf.ptr] = buf.ptr;
			atomicIncrement(cacheSize_);
		}
		else delete buf;
	}
	
	uint cacheSize()
	{
		return cacheSize_;
	}
	
private:
	void*[void*] bufferPtrMap_;
	ThreadSafeQueue2!(void[]) bufferPool_;
	uint defaultBufferSize_;
	uint maxCacheSize_ = 100;
	uint cacheSize_;
}