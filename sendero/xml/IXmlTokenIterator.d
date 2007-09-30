/** 
 * Copyright: Copyright (C) 2007 Aaron Craelius.  All rights reserved.
 * License:   BSD Style
 * Authors:   Aaron Craelius
 */


module sendero.xml.IXmlTokenIterator;

public import sendero.xml.NodeType;

enum XmlTokenType : ubyte {StartElement = 0, StartNSElement = 1, AttrName = 2, AttrNSName = 3, AttrValue = 4, EndElement = 5, EndNSElement = 6, EndEmptyElement = 7, Data = 8, Comment = 9, CData = 10, Declaration = 11, Doctype = 12, PIValue = 13, PIName = 14, None  = 15};

interface IXmlTokenIterator(Ch, Int)
{
	bool next();
	XmlTokenType type();
	Ch[] qvalue();
	Ch[] value();
	Int loc();
	Int qlen();
	Int len();
	bool reset();
	void retainCurrent();
	ushort depth();
	//bool error();
	//char[] errorMsg();
}