module sendero.util.BufferProvider;

import sendero.util.collection.ThreadSafeQueue;

import tango.core.Atomic;

class BufferProvider
{
	this(uint defaultBufferSize = 16384)
	{
		this.bufferPool_ = new ThreadSafeQueue!(void[]);
		this.defaultBufferSize_ = defaultBufferSize;
	}
	
	uint defaultBufferSize() { return defaultBufferSize_; }
	void defaultBufferSize(uint sz) { defaultBufferSize_ = sz; }
	
	uint maxCacheSize() { return maxCacheSize_; }
	void maxCacheSize(uint sz) { maxCacheSize_ = sz; }	
	
	void[] get()
	{
		auto buf = bufferPool_.pull;
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
	ThreadSafeQueue!(void[]) bufferPool_;
	uint defaultBufferSize_;
	uint maxCacheSize_ = 100;
	uint cacheSize_;
}

class SingleThreadBufferPool
{
	this(uint defaultBufferSize = 8192, uint maxCacheSize = 100, uint preAllocSize = 10)
	{
		defaultBufferSize_ = defaultBufferSize;
		bufferPool_ = new void[][maxCacheSize];
		len = maxCacheSize;
		for(index = 0; index < preAllocSize; ++index)
		{
			auto buf = new void[defaultBufferSize_];
			bufferPool_[index] = buf;
			debug bufferPtrMap_[buf.ptr] = buf.ptr;
		}
	}
	
	void[] get()
	{
		if(index >= 0) {
			auto buf = bufferPool_[index];
			--index;
			debug bufferPtrMap_.remove(buf.ptr);
			return buf;
		}
		else return new void[defaultBufferSize_];
	}
	
	void release(void[] buf)
	{
		if(index < len - 1) {
			debug {
				auto pBuf = buf.ptr in bufferPtrMap_;
				if(pBuf) {
					throw new Exception("Trying to place buffer in the pool a second time");
				}
			}
			++index;
			bufferPool_[index] = buf;
			debug bufferPtrMap_[buf.ptr] = buf.ptr;
		}
		else delete buf;
	}
private:
	int index = -1;
	const int len;
	debug void*[void*] bufferPtrMap_;
	void[][] bufferPool_;
	uint defaultBufferSize_;
}