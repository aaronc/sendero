/** 
 * Copyright: Copyright (C) 2007 Aaron Craelius.  All rights reserved.
 * License:   BSD Style
 * Authors:   Aaron Craelius
 */


module sendero.xml.IXmlTokenIterator;

public import sendero.xml.NodeType;

enum XmlTokenType {StartElement, StartNSElement, EndElement, EndNSElement, EndEmptyElement, AttrName, AttrNSName, AttrValue, Data, Comment, CData, PIName, PIValue, Declaration, Doctype};

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
}