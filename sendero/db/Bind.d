module sendero.db.Bind;

public import dbi.model.BindType;

interface IBindable {
	BindType[] setBindTypes(char[][] fieldNames, BindType[] dst = null);
	void*[] setBindPtrs(char[][] fieldNames, void*[] dst = null);
	ptrdiff_t[] setBindOffsets(char[][] fieldNames, ptrdiff_t[] dst = null);
}

struct Binder {
	struct Pair {
		IBindable obj;
		char[][] fieldnames;
	}
	
	private ptrdiff_t offsets;
	private size_t[] indices;
	BindInfo info;
	
	static Binder opCall(IBindable obj, char[][] fieldnames)
	{
		Binder binder;
		binder.prep(obj, fieldnames);
		return binder;
	}
	
	static Binder opCall(IBindable obj1, char[][] fieldnames1,
	                     IBindable obj2, char[][] fieldnames2)
	{
		Binder.binder;
		binder.prep(obj1,fieldnames1,obj2,fieldnames2);
		return binder;
	}
	
	static Binder opCall(Pair[] bindPairs...)
	{
		
	}
	
	void prep(IBindable obj, char[][] fieldnames)
	{
		info.types = obj.setBindTypes(fieldnames);
		info.ptrs = obj.setBindPtrs(fieldnames);
		offsets = obj.setBindOffsets(fieldNames);
		indices = [offsets.length];
		assert(info.types.length == info.ptrs.length);
		assert(info.types.length == offsets.length);
	}
	
	void prep(IBindable obj1, char[][] fieldnames1,
                IBindable obj2, char[][] fieldnames2)
	{
		info.types = obj1.setBindTypes(fieldnames1);
		info.ptrs = obj1.setBindPtrs(fieldnames1);
		offsets = obj1.setBindOffsets(fieldNames1);
		
		info.types ~= obj2.setBindTypes(fieldnames2);
		info.ptrs ~= obj2.setBindPtrs(fieldnames2);
		offsets ~= obj2.setBindOffsets(fieldNames2);
		indices = [fieldnames1.length, fieldnames2.length];
		debug assert(indices[0].length + indices[1].length == info.types.length);
		assert(info.types.length == info.ptrs.length);
		assert(info.types.length == offsets.length);
	}
	
	void prep(Pair[] bindPairs...)
	{
		info.types = null;
		info.ptrs = null;
		offsets = null;
		indices = null;
		debug size_t indexSum = 0;
		foreach(pair; bindPairs)
		{
			info.types ~= pair.obj.setBindTypes(pair.fieldnames);
			info.ptrs ~= pair.obj.setBindPtrs(pair.fieldnames);
			offsets ~= pair.obj.setBindOffsets(pair.fieldnames);
			indices ~= pair.fieldnames.length;
			debug indexSum += pair.fieldnames.length;
		}
		debug assert(indexSum == info.types.length);
		assert(info.types.length == info.ptrs.length);
		assert(info.types.length == offsets.length);
	}
	
	void update(IBindable[] objs...)
	{
		size_t nObjs = indices.length;
		assert(nObjs == objs.length, "Incorrect number of object instances passed "
				"to Binder.update");
		size_t n = 0;
		for(size_t i = 0; i < nObjs; ++i)
		{
			for(size_t j = 0;j < indices[i]; ++j, ++n)
			{
				info.ptrs[n] = (cast(void*)objs[i]) + offsets[n];
			}
		}
	}
}

/+interface IBindable {
	/**
	 * 
	 * Params:
	 *     fieldNames = the list of fieldNames to bind, binds all fields if fieldNames is null or 0-length 
	 * Returns: A BindInfo array containing BindTypes and pointers to the bound fields.
	 */
	//BindInfo[] bind(char[][] fieldNames = null);
	
	Binder createBinder(char[][] fieldNames);
}+/


// Ideas:
/+
struct Binder
{
	BindType[] types;
	void*[] ptrs;
	
	package ptrdiff_t[] offsets;
	
	void bind(void* instPtr)
	{
		foreach(i, offset; offsets)
		{
			ptrs[i] = instPtr + offset;
		}
	}
	
	alias bind opCall;
}

interface IBinder
{
	BindType[] types();
	void*[] bind(void* ptr);
}+/