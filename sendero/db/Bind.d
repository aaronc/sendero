module sendero.db.Bind;

struct BindInfo
{
	BindType[] types;
	void* ptrs;
}

interface IBindable {
	/**
	 * 
	 * Params:
	 *     fieldNames = the list of fieldNames to bind, binds all fields if fieldNames is null or 0-length 
	 * Returns: A BindInfo array containing BindTypes and pointers to the bound fields.
	 */
	BindInfo[] bind(char[][] fieldNames = null);
}

// Ideas:

struct Binder
{
	BindType[] types;
	
	package void*[] offsets;
	
	void bind(void* instPtr, ref void*[] ptrs)
	{
		
	}
}

interface IBinder
{
	BindType[] types;
	void*[] bind(void* ptr);
}