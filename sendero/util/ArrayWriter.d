/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.util.ArrayWriter;

//import tango.io.model.IConduit;
//import tango.core.Exception;

class ArrayWriter(T)
{
	this(size_t initSize = 100, size_t growSize = 10)
	{
		this.initSize = initSize;
		this.growSize = growSize;
	}
	
	protected size_t initSize;
	size_t growSize;
	
	protected T[] array;
	protected size_t n = 0;
	
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
	
	void append(T[] t)
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
	
	alias append opCatAssign;
	
	T[] get() {return array[0..n];}
	
	
}
	
/+class StringWriter : ArrayWriter!(char), OutputStream
{
	IConduit conduit () { return null; }
	void close() {}
	uint write(void[] src) { this ~= cast(char[])src; return src.length; }
	OutputStream copy(InputStream src)
	{
		auto copied = src.read(array[n .. array.length]);
		if(copied == IOStream.Eof) throw new IOException("Error when copying InputStream in StringWriter");
		n += copied;
		return this;
	}
	OutputStream flush() { return this; }
}+/

unittest
{
	auto str = new ArrayWriter!(char);
	str ~= 'h';
	str ~= "ello w";
	str ~= 'o';
	str ~= "rld";
	assert(str.get == "hello world");
	
/+	auto str2 = new StringWriter;
	
	str2 ~= 'h';
	str2 ~= "ello w";
	str2 ~= 'o';
	str2 ~= "rld";
	assert(str2.get == "hello world");+/
}