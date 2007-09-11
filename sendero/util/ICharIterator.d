/** 
 * Copyright: Copyright (C) 2007 Aaron Craelius.  All rights reserved.
 * License:   BSD Style
 * Authors:   Aaron Craelius
 */


module sendero.util.ICharIterator;

public import sendero.util.IStringViewer;

/**
 * Defines the interface for a character iterator useful
 * for parsing strings and viewing random slices of them
 * at a later point.
 */
interface ICharIterator(Ch) : IStringViewer!(Ch)
{
	bool good();
	Ch cur();
	Ch opIndex(size_t);
	ICharIterator!(Ch) opAddAssign(size_t i);
	ICharIterator!(Ch) opPostInc();
	//ICharIterator!(Ch) opSubAssign(size_t i);
	//ICharIterator!(Ch) opPostDec();
	Ch[] opSlice(size_t x, size_t y);
	size_t location();
	Ch[] randomAccessSlice(size_t x, size_t y);
	bool seek(size_t location);
	IStringViewer!(Ch) src();
	bool forwardLocate(Ch ch);
	void forwardLookup(ubyte[256] lookupTable);
	bool eatElemName();
	bool eatAttrName();
	bool eatSpace();
}

public enum Flags: ubyte
{
Attr  = 0x01,
Elem  = 0x02,
Both  = 0x03,
}