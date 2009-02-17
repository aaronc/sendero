module sendero.server.util.SingleThreadObjectPool;

class SingleThreadObjectPool(Type)
{
	this(uint maxCacheSize = 100, uint preAllocSize = 10)
	{
		objPool_ = new Type[maxCacheSize];
		len = maxCacheSize;
		for(index = 0; index < preAllocSize; ++index)
		{
			auto obj = create;
			objPool_[index] = obj;
			debug objPtrMap_[cast(void*)obj] = cast(void*)obj;
		}
		--index;
	}
	
	Type get()
	{
		if(index >= 0) {
			auto obj = objPool_[index];
			--index;
			debug objPtrMap_.remove(cast(void*)obj);
			debug assert(obj !is null);
			return obj;
		}
		else return create;
	}
	
	protected abstract Type create();
	
	void release(Type obj)
	{
		if(index < len - 1) {
			debug {
				auto pObj =  cast(void*)obj in objPtrMap_;
				if(pObj) {
					throw new Exception("Trying to place object of type "
						~ Type.stringof ~ " in the pool a second time");
				}
			}
			++index;
			objPool_[index] = obj;
			debug objPtrMap_[ cast(void*)obj] = cast(void*)obj;
		}
		else delete obj;
	}
private:
	int index = -1;
	const int len;
	debug void*[void*] objPtrMap_;
	Type[] objPool_;
}