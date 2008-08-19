module sendero.util.collection.StaticBitArray;

import tango.core.BitManip;

struct StaticBitArray(size_t size, size_t len)
{
	static assert(len <= size * 32);
	
	private uint[size] bits;
	
	int opApply( int delegate(inout size_t, inout bool) dg )
    {
        int result;

        for( size_t i = 0; i < len; ++i )
        {
            bool b = cast(bool)bt( bits.ptr, i );
            result = dg( i, b );
            if( result )
                break;
        }
        return result;
    }
	
	bool opIndex( size_t pos )
    in
    {
        assert( pos < len );
    }
    body
    {
        return cast(bool)bt( bits.ptr, pos );
    }
    
    bool opIndexAssign( bool b, size_t pos )
    in
    {
        assert( pos < len );
    }
    body
    {
        if( b )
            bts( bits.ptr, pos );
        else
            btr( bits.ptr, pos );
        return b;
    }
    
    bool hasTrue()
    {
    	for( size_t i = 0; i < size; ++i )
        {
            if(bits[i] != 0) return true;
        }
        return false;
    }
    
    void clear()
    {
    	for(uint i = 0; i < size; ++i)
    		bits[i] = 0;
    }
    
    /+bool hasFalse()
    {
    	static if(size > 1) {
	    	for( size_t i = 0; i < size - 1; ++i )
	        {
	    		if(bits[i] != uint.max) return true;
	        }
	    	if(bits[i] != uint max & )
    	}
    	
        return false;
    }+/
    
    /+bool get(size_t i)()
    {
    	static assert(i < len, "Array index out of bounds");
    	
    	 return cast(bool)bt( bits.ptr, i );
    }
    
    void set(size_t i)(bool b)
    {
    	static assert(i < len, "Array index out of bounds");
    	
    	if( b )
            bts( bits.ptr, i );
        else
            btr( bits.ptr, i );
    }+/
}

debug(SenderoUnittest)
{
unittest
{
	StaticBitArray!(1, 5) array;
	
	//assert(array.hasFalse);
	assert(!array.hasTrue);
	
	array[1] = true;
	array[4] = true;
	
	//assert(array.hasFalse);
	assert(array.hasTrue);
	
	assert(array[0] == false);
	assert(array[1] == true);
	assert(array[2] == false);
	assert(array[3] == false);
	assert(array[4] == true);
	
	array[0] = true;
	array[2] = true;
	array[3] = true;
	
	//assert(!array.hasFalse);
	assert(array.hasTrue);

	array.clear;
	
	assert(!array.hasTrue);
	
	/+array.set!(3)(true);
	assert(array[3] == true);
	assert(array.get!(2) == false);
	assert(array.get!(4) == true);+/
}
}