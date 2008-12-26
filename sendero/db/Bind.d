module sendero.db.Bind;

import dbi.Statement;

struct BindInfo
{
	BindType[] types;
	void*[] ptrs;
}

struct Binder
{
	
}

interface IBindable {
	/**
	 * 
	 * Params:
	 *     fieldNames = the list of fieldNames to bind, binds all fields if fieldNames is null or 0-length 
	 * Returns: A BindInfo array containing BindTypes and pointers to the bound fields.
	 */
	//BindInfo[] bind(char[][] fieldNames = null);
	
	Binder createBinder(char[][] fieldNames);
}

// Ideas:

struct Binder
{
	BindType[] types;
	void*[] ptrs;
	
	package void*[] offsets;
	
	void bind(void* instPtr)
	{
		foreach(i, offset; offset)
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