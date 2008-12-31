module sendero.db.Bind;

public import dbi.model.BindType;

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

interface IBindable {
	BindType[] setBindTypes(char[][] fieldNames, BindType[] dst);
	void*[] setBindPtrs(char[][] fieldNames, void*[] dst);
	ptrdiff_t[] setBindPtrs(char[][] fieldNames, ptrdiff_t[] dst);
}

// Ideas:

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
}