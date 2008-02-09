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
version(Unittest)
{
import tango.time.StopWatch;
import tango.io.Stdout;

void test1(ArrayWriter!(char) w)
{
	for(uint i = 0; i < 100000; ++i)
	{
		w.append("hello");
	}
}

void test2(void delegate(void[]) w)
{
	for(uint i = 0; i < 100000; ++i)
	{
		w("hello");
	}
}

void benchmark(char[] msg, void delegate() dg)
{
	Stdout("Beginning:")(msg).newline;
	StopWatch sw;
	sw.start;
	for(uint i = 0; i < 10; ++i)
		dg();
	auto t = sw.stop;
	Stdout.formatln("{}:{}ms", msg, t);
}

void doBenchmarks()
{
	auto a1 = new ArrayWriter!(char);
	benchmark("A1", {test1(a1);});
	
	auto a2 = new ArrayWriter!(char);
	benchmark("A2", {test2(cast(void delegate(void[]))&a2.append);});
	
	benchmark("A1", {test1(a1);});
	benchmark("A2", {test2(cast(void delegate(void[]))&a2.append);});
	benchmark("A1", {test1(a1);});
	benchmark("A2", {test2(cast(void delegate(void[]))&a2.append);});
}

unittest
{
	auto str = new ArrayWriter!(char);
	str ~= 'h';
	str ~= "ello w";
	str ~= 'o';
	str ~= "rld";
	assert(str.get == "hello world");
	
//	doBenchmarks;
	
/+	auto str2 = new StringWriter;
	
	str2 ~= 'h';
	str2 ~= "ello w";
	str2 ~= 'o';
	str2 ~= "rld";
	assert(str2.get == "hello world");+/
}
}