/** 
 * Copyright: Copyright (C) 2007 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.util.ArrayWriter;

class ArrayWriter(T)
{
	this(size_t initSize = 100, size_t growSize = 10)
	{
		this.initSize = initSize;
		this.growSize = growSize;
	}
	
	private size_t initSize;
	size_t growSize;
	
	private T[] array;
	private size_t n = 0;
	
	size_t length()
	{
		return n;
	}
	
	void opCatAssign(T t)
	{
		while(n >= array.length) {
			uint grow = array.length + growSize;
			array.length = grow;
		}
		
		array[n] = t;
		++n;
	}
	
	void opCatAssign(T[] t)
	{
		auto len = t.length;
		auto target = n + len;
		if(target >= array.length) {
			uint grow = array.length + growSize;
			if(grow < target) grow = target;
			array.length = grow;
		}
		
		array[n .. n + len] = t;
		n += len;
	}
	
	T[] get() {return array[0..n];}
}

unittest
{
	auto str = new ArrayWriter!(char);
	str ~= 'h';
	str ~= "ello w";
	str ~= 'o';
	str ~= "rld";
	assert(str.get == "hello world");
}