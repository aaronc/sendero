/** 
 * Copyright: Copyright (C) 2007 Aaron Craelius.  All rights reserved.
 * License:   BSD Style
 * Authors:   Aaron Craelius
 */


module sendero.util.StringCharIterator;

public import sendero.util.ICharIterator;

class StringViewer(Ch) : IStringViewer!(Ch)
{
	this(Ch[] text)
	{
		this.text = text;
	}
	
	private Ch[] text;
	
	Ch[] randomAccessSlice(size_t x, size_t y)
	{
		if(x >= text.length)
			return "\0";
		if(y >= text.length)
			return text[x .. $];
		return text[x .. y];
	}
}

class StringCharIterator(Ch) : ICharIterator!(Ch)
{
	this(Ch[] text)
	{
		this.text = text;
		this.len = text.length;
		this.index = 0;
		this.viewer = new StringViewer!(Ch)(text);
	}
	
	private Ch[] text;
	private size_t len;
	private size_t index;
	private StringViewer!(Ch) viewer;
	
	bool good()
	{
		return index < len;
	}
	
	Ch opIndex(size_t i)
	{
		if((index + i) < len)
			return text[index + i];
		return '\0';
	}
	
	ICharIterator!(Ch) opAddAssign(size_t i)
	{
		index += i;
		return this;
	}
	
	ICharIterator!(Ch) opPostInc()
	{
		index++;
		return this;
	}
	
	ICharIterator!(Ch) opSubAssign(size_t i)
	{
		index -= i;
		return this;
	}
	
	ICharIterator!(Ch) opPostDec()
	{
		index--;
		return this;
	}
	
	Ch[] opSlice(size_t x, size_t y)
	{
		if(index + x >= len)
			return "\0";
		if(index + y >= len)
			return text[index + x .. $];
		return text[index + x .. index + y];
	}
	
	Ch[] randomAccessSlice(size_t x, size_t y)
	{
		return viewer.randomAccessSlice(x, y);
	}
	
	size_t location()
	{
		return index;
	}
	
	size_t length()
	{
		return len;
	}
	
	bool seek(size_t position)
	{
		if(position < length) {
			index = position;
			return true;
		}
		return false;
	}
	
	IStringViewer!(Ch) src()
	{
		return viewer;
	}
	
	void reset(Ch[] newText)
	{
		this.text = newText;
		this.len = newText.length;
		this.index = 0;
		this.viewer.text = newText;
	}
}

import tango.io.Stdout;
import tango.io.File;

unittest
{	
	char[] t = "<element attr=\"1\" attr2=\"two\"><!--comment-->test<el2 attr3 = '3three'><![CDATA[sdlgjsh]]><el3 />data<?pi test?></el2></element>";
	auto text = new StringCharIterator!(char)(t);
	uint i = 0;
	while(text.good)
	{
		assert(text[0] == t[i]);
		++text;
		++i;
	}
}