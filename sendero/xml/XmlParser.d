/** 
 * Copyright: Copyright (C) 2007 Aaron Craelius.  All rights reserved.
 * License:   BSD Style
 * Authors:   Aaron Craelius
 */


module sendero.xml.XmlParser;

public import sendero.xml.IXmlTokenIterator;
public import sendero.util.ICharIterator;
public import sendero.xml.IForwardNodeIterator;
import sendero.util.StringCharIterator;

import tango.util.log.Log;
import Integer = tango.text.convert.Integer;
import Unicode = tango.text.convert.Utf;

/* Acknowledgements:
 * 
 * This parser was inspired by VTD-XML and Marcin Kalicinski's RapidXml parser.  Thanks to the 
 * RapidXml project for the lookup table idea.  We have used a few similar lookup tables
 * to implement this parser. Also the idea of not copying the source string
 * but simply referencing it is used here.  IXmlTokenIterator doesn't implement the same
 * interface as VTD-XML, but  the spirit is similar.  Thank you for your work!
 *  
 *  /

/**
 * Token based XML Parser.  Works with char[], wchar[], and dchar[] based Xml strings. 
 * 
 */
class XmlParser(Ch = char, Int = uint) : IXmlTokenIterator!(Ch, Int)
{
	private static Logger log;
	
	this(Ch[] text)
	{
		this.text = new StringCharIterator!(Ch)(text);	
	}
	
	this(ICharIterator!(Ch) text)
	{
		this.text = text;
	}
	
	private ICharIterator!(Ch) text;
	
	private XmlTokenType curType;
	private Int curLoc;
	private Int curLen;
	private Int curQLen;
	private ushort curDepth = 0;
	private bool inElement = false;
	private bool inPI = false;
	private bool inDeclaration = false;
	private bool retain = false;
	
	final private void eatWhitespace()
	{
		while(text.good && Lookup.whitespace[text[0]]) ++text;
	}
	
	final private bool doStartElement()
	{
		curType = XmlTokenType.StartElement;
		curLoc = text.location;
		while(Lookup.name[text[0]]) ++text;
		if(text[0] == ':') {
			curQLen = text.location - curLoc;
			++text;
			while(Lookup.attributeName[text[0]]) ++text;
			curLen = text.location - curLoc - curQLen - 1;
		}
		else {
			curLen = text.location - curLoc;
			curQLen = 0;
		}
		
		inElement = true;
		return true;
	}
	
	final private bool doEndElement()
	{
		curType = XmlTokenType.EndElement;
		curLoc = text.location;
		while(Lookup.name[text[0]]) ++text;
		if(text[0] == ':') {
			curQLen = text.location - curLoc;
			++text;
			while(Lookup.attributeName[text[0]]) ++text;
			curLen = text.location - curLoc - curQLen - 1;
		}
		else {
			curLen = text.location - curLoc;
			curQLen = 0;
		}
		
		eatWhitespace;
		if(text[0] != '>')
			return doUnexpected();
		++text;
		
		--curDepth;
		
		return true;
	}
	
	final private bool doEndEmptyElement()
	{
		inElement = false;
		if(text[0..2] != "/>")
			return doUnexpected();
		
		curType = XmlTokenType.EndEmptyElement;
		curLoc = text.location;
		text += 2;
		curLen = 0;
		curQLen = 0;
		
		return true;
	}
	
	final private bool doAttributeName()
	{
		curType = XmlTokenType.AttrName;
		curLoc = text.location;
		++text;
		while(Lookup.attributeName[text[0]]) ++text;
		if(text[0] == ':') {
			curQLen = text.location - curLoc;
			++text;
			while(Lookup.attributeName[text[0]]) ++text;
			curLen = text.location - curLoc - curQLen - 1;
		}
		else {
			curLen = text.location - curLoc;
			curQLen = 0;
		}
		
		if(!text.good)
			return doUnexpectedEOF();		
		return true;
	}
	
	final private bool doAttributeValue()
	{
		curType = XmlTokenType.AttrValue;
		++text;
		eatWhitespace;
		Ch quote = text[0];
		++text;
		
		curLoc = text.location;
		
		if(quote == '\'') {
			while(text[0] && text[0] != '\'') ++text;
		}
		else if (quote == '\"') {	
			while(text[0] && text[0] != '\"') ++text;
		}
		else {
			return doUnexpected;
		}
		curLen = text.location - curLoc;
		curQLen = 0;
		
		++text; //Skip end quote
		
		return true;
	}
	
	final private bool doData()
	{
		curType = XmlTokenType.Data;
		curLoc = text.location;
		while(Lookup.text[text[0]]) ++text;
		curLen = text.location - curLoc;
		curQLen = 0;
		return true;
	}
	
	final private bool doComment()
	{
		curType = XmlTokenType.Comment;
		curLoc = text.location;
		
		while(text.good)
		{
			if(text[0] == '-')
			{
				if(text[0..3] == "-->") {
					curLen = text.location - curLoc;
					text += 3;
					curQLen = 0;
					return true;
				}
			}
			++text;
		}
		return doUnexpectedEOF();
	}
	
	final private bool doCData()
	{
		curType = XmlTokenType.CData;
		curLoc = text.location;
		
		while(text.good)
		{
			if(text[0] == ']')
			{
				if(text[0..3] == "]]>") {
					curLen = text.location - curLoc;
					curQLen = 0;
					text += 3;			
					return true;
				}
			}
			++text;
		}
		return doUnexpectedEOF();
	}
	
	final private bool doPIName()
	{
		inPI = true;
		curType = XmlTokenType.PIName;
		curLoc = text.location;
		while(Lookup.name[text[0]]) ++text;
		
		curLen = text.location - curLoc;
		curQLen = 0;
		if(!text.good)
			return doUnexpectedEOF();		
		return true;
	}
	
	final private bool doPIValue()
	{
		inPI = false;
		
		curType = XmlTokenType.PIValue;
		curLoc = text.location;
		
		while(text.good)
		{
			if(text[0..2] == "?>") {
				curLen = text.location - curLoc;
				curQLen = 0;
				text += 2;
				return true;
			}
			++text;
		}
		return doUnexpectedEOF();
	}
	
	final private bool doDeclaration()
	{
		eatWhitespace;
		
		if(!text.good)
			return doEndOfStream();
		
		curType = XmlTokenType.Declaration;
		curLoc = text.location;
		curQLen = 0;
		
		inDeclaration = true;
		
		return true;
	}
	
	final private bool doDoctype()
	{
		eatWhitespace;
		
		curType = XmlTokenType.Doctype;
		curLoc = text.location;
		curQLen = 0;
		
		void skipInternalSubset()
		{
			while(text.good) {
				if(text[0] == ']') {
					++text;
					return;
				}
				else ++text;
			}
		}
		
        while(text.good) {
        	if(text[0] == '>') {
        		curLen = text.location - curLoc;
        		++text;
        		return true;
        	}
        	else if(text[0] == '[') {
        		++text;
        		skipInternalSubset;
        	}
        	else ++text;
        }
		
		if(!text.good)
			return doUnexpectedEOF();
		
		return true;
	}
	
	final private bool doUnexpected()
	{
		//TODO Log
		return false;
	}
	
	final private bool doUnexpectedEOF()
	{
		//TODO Log
		return false;
	}
	
	final private bool doEndOfStream()
	{
		return false;
	}
	
	final private bool doInElement()
	{
		switch(text[0])
		{
		case '=':
			return doAttributeValue();
			break;
		case '/':
			return doEndEmptyElement();
			break;
		case '>':
			++curDepth;
			inElement = false;
			++text;
			return doMain();
			break;
		default:
			return doAttributeName();
			break;
		}
	}
	
	final private bool doInDeclaration()
	{
		switch(text[0])
		{
		case '=':
			return doAttributeValue();
			break;
		case '\?':
			if(text[1] != '>')
				return false;
			inDeclaration = false;
			text += 2;
			return doMain();
			break;
		default:
			return doAttributeName();
			break;
		}
	}
	
	final private bool doMain()
	{
		switch(text[0])
		{
		case '<':
			switch(text[1])
			{
			case '!':
				if(text[2..4] == "--") {
					text += 4;
					return doComment();
				}
				else if(text[2..9] == "[CDATA[") {
					text += 9;
					return doCData();
				}
				else if(text[2..9] == "DOCTYPE") {
					text += 9;
					return doDoctype();
				}
				else {
					return doUnexpected();
				}
				break;
			case '\?':
				if(text[2 .. 5] == "xml") {
					text += 5;
					return doDeclaration();
				}
				else {
					text += 2;
					return doPIName();
				}
				break;
			case '/':
				text += 2;
				return doEndElement();
			default:
				++text;
				return doStartElement();
				break;
			}
			break;
		case '/':
			if(text[1] == '>') {
				text += 2;
				return doEndEmptyElement();
			}
			else {
				return doData();
			}
			break;
		default:
			return doData();
		}
	}
	
	bool next()
	{	
		if(retain) {
			retain = false;
			return true;
		}
		
		if(!text.good)
			return doEndOfStream();
		
		eatWhitespace;
		
		if(!text.good)
			return doEndOfStream();
		
		if(inElement)
			return doInElement();
		
		if(inPI)
			return doPIValue();
		
		if(inDeclaration)
			return doInDeclaration();
		
		return doMain();	
	}
	
	XmlTokenType type()
	{
		return curType;
	}
	
	Ch[] qvalue()
	{
		return text.randomAccessSlice(loc, loc + qlen);
	}
	
	Ch[] value()
	{
		if(qlen) {
			return text.randomAccessSlice(loc + qlen + 1, loc + qlen + 1 + len);
		}
		return text.randomAccessSlice(loc, loc + len);
	}
	
	Int loc()
	{
		return curLoc;
	}
	
	Int qlen()
	{
		return curQLen;
	}
	
	Int len()
	{
		return curLen;
	}
	
	ushort depth()
	{
		return curDepth;
	}
	
	bool reset()
	{
		return text.seek(0);
	}
	
	void retainCurrent()
	{
		retain = true;
	}
}

/**
 * Forward reading node based Xml Parser.
 */
class XmlForwardNodeParser(Ch) : IForwardNodeIterator!(Ch)
{
	this(XmlParser!(Ch) parser)
	{
		this.parser = parser;
	}
	
	private XmlParser!(Ch) parser;
	
	private XmlNodeType curType;
	
	private uint attrLoc = 0;
	private uint attrLen = 0;
	private uint attrQLen = 0;
	
	bool nextElement() {
		while(nextNode) {
			if(this.type == XmlNodeType.Element)
				return true;
		}
		return false;
	}
	
	bool nextElement(ushort depth)
	{
		while(nextNode(depth)) {
			if(this.type == XmlNodeType.Element)
				return true;
		}
		return false;
	}
	
	bool nextElement(ushort depth, Ch[] name)
	{
		while(nextElement(depth)) {
			if(this.nodeName == name)
				return true;
		}
		return false;
	}
	
	private bool processNode()
	{
		if(parser.type == XmlTokenType.AttrName || parser.type == XmlTokenType.AttrNSName || parser.type == XmlTokenType.AttrValue)
			return false;;
		
		switch(parser.type)
		{
		case XmlTokenType.StartElement, XmlTokenType.StartNSElement:
			curType = XmlNodeType.Element;
			break;
		case XmlTokenType.EndElement, XmlTokenType.EndNSElement, XmlTokenType.EndEmptyElement, 
			XmlTokenType.AttrName, XmlTokenType.AttrNSName, XmlTokenType.AttrValue, 
			XmlTokenType.Declaration, XmlTokenType.Doctype:
			return false;
			break;
		case XmlTokenType.Data:
			curType = XmlNodeType.Data;
			break;
		case XmlTokenType.Comment:
			curType = XmlNodeType.Comment;
			break;
		case XmlTokenType.CData:
			curType = XmlNodeType.CData;
			break;
		case XmlTokenType.PIName:
			doPI;
			break;
		default:
			assert(false);
			return false;
		}
		return true;
	}
	
	bool nextNode()
	{
		while(parser.next) {
			if(processNode) return true;
		}
		return false;
	}
	
	bool nextNode(ushort depth)
	{
		while(parser.next) {
			if(parser.depth == depth) {
				if(processNode) return true;
			}
			else if(parser.depth < depth && (parser.type == XmlTokenType.EndElement || 
					parser.type == XmlTokenType.EndNSElement || 
					parser.type == XmlTokenType.EndEmptyElement))
			{
				parser.retainCurrent;
				return false;
			}
		}
	}
	
	private void doPI()
	{
		curType = XmlNodeType.PI;
		attrLoc = parser.loc;
		attrLen = parser.len;
		attrQLen = parser.qlen;
		
		if(parser.next) {
			if(parser.type != XmlTokenType.PIValue) {
				parser.retainCurrent;
			}
		}
	}
	
	bool nextAttribute()
	{
		if(parser.type == XmlNodeType.Element || parser.type == XmlNodeType.Attribute)
		{
			if(parser.next) {
				if(parser.type == XmlTokenType.AttrName || parser.type == XmlTokenType.AttrNSName) {
					attrLoc = parser.loc;
					attrLen = parser.len;
					attrQLen = parser.qlen;
				}
				
				if(!parser.next) return false;
				
				if(parser.type != XmlTokenType.AttrValue) return false;
				
				curType = XmlNodeType.Attribute;
				
				return true;
			}
			else {
				parser.retainCurrent;
				return false;
			}
		}
		else return false;
	}
	
	XmlNodeType type()
	{
		return curType;
	}
	
	Ch[] prefix()
	{
		if(curType == XmlNodeType.Attribute || curType == XmlNodeType.PI) {
			return parser.text.randomAccessSlice(attrLoc, attrLoc + attrQLen);
		}
		
		return parser.qvalue;
	}
	
	Ch[] localName()
	{
		if(curType == XmlNodeType.Attribute || curType == XmlNodeType.PI) {
			if(attrQLen) return parser.text.randomAccessSlice(attrLoc + attrQLen + 1, attrLoc + attrQLen + attrLen + 1);
			else return parser.text.randomAccessSlice(attrLoc, attrLoc + attrLen);
		}
		
		return parser.value;
	}
	
	Ch[] nodeName()
	{
		if(curType == XmlNodeType.Attribute || curType == XmlNodeType.PI) {
			if(attrQLen) return parser.text.randomAccessSlice(attrLoc, attrLoc + attrQLen + attrLen + 1);
			else return parser.text.randomAccessSlice(attrLoc, attrLoc + attrLen);
		}
		
		if(parser.qvalue.length) {
			return parser.qvalue ~ ":" ~ parser.value;
		}
		return parser.value;
	}
	
	Ch[] nodeValue()
	{
		if(parser.type == XmlTokenType.Data)
			return EntityDecoder!(Ch).decodeBuiltIn(parser.value);
		else return parser.value;
	}
	
	Ch[] nodeRawValue()
	{
		return parser.value;
	}
	
	ushort depth()
	{
		return parser.depth;
	}
}

class EntityDecoder(Ch)
{
	static char[] fromDecimalToUtf8(uint val)
	{
		if(val <= 0x7f) {
			ubyte[1] x;
			x[0] = val;
			return cast(char[])x.dup;
		}
		else if(val <= 0x7ff) {
			ubyte[2] x;
			x[0] = 0xc0 | val >> 6;
			x[1] = 0x80 | val & 0x3f;
			return cast(char[])x.dup;
		}
		else if(val <= 0xd7ff || (val >= 0xe000 && val <= 0xffff)) {
			ubyte[3] x;
			x[0] = 0xe0 | val >> 12;
			x[1] = 0x80 | val >> 6 & 0x3f;
			x[2] = 0x80 | val & 0x3f;
			return cast(char[])x.dup;
		}
		else if(val < 0x10ffff) {
			ubyte[4] x;
			x[0] = 0xf0 | val >> 18;
			x[1] = 0x80 | val >> 18 & 0x3f;
			x[2] = 0x80 | val >> 6 & 0x3f;
			x[3] = 0x80 | val & 0x3f;
			return cast(char[])x.dup;
		}
		else return null;
	}
	
	static Ch[] fromDecimalToCh(uint val)
	{
		char[] res = fromDecimalToUtf8(val);
		static if(is(Ch == char))
			return res;
		else static if(is(Ch == wchar))
			return Unicode.toUtf16(res);
		else static if(is(Ch == dchar))
			return Unicode.toUtf32(res);
		else assert(false, "Unsupported character type " ~ Ch.stringof ~ " while doing numeric reference (&#nn;) decoding");
	}
	
	static Ch[] decodeBuiltIn(Ch[] str)
	{		
		Ch[] res;
		
		auto i = new StringCharIterator!(Ch)(str);
		
		while(i.good) {
			if(i[0] == '&') {
				++i;
				switch(i[0]) {
				case '#':
					if(i[1] == 'x') {
						i += 2;
						Ch[] xStr;
						while(i.good && i[0] != ';') {
							xStr ~= i[0];
							++i;
						}
						if(i[0] != ';')
							return null; //TODO log error;
						++i;
						auto x = Integer.parse(xStr, 16);
						res ~= fromDecimalToCh(x);
					}
					else {
						i++;
						Ch[] xStr;
						while(i.good && i[0] != ';') {
							xStr ~= i[0];
							++i;
						}
						if(i[0] != ';')
							return null; //TODO log error;
						++i;
						auto x = Integer.parse(xStr);
						res ~= fromDecimalToCh(x);
					}
					break;
				case 'a':
					if(i[0 .. 4] == "amp;") {
						i += 4;
						res ~= "&";
					}
					else if(i[0 .. 5] == "apos;") {
						i += 4;
						res ~= "'";
					}
					else {
						++i;
						res ~= "&";
					}
					break;
				case 'l':
					if(i[0 .. 3] == "lt;") {
						i += 3;
						res ~= "<";
					}
					else {
						++i;
						res ~= "&";
					}
					break;
				case 'g':
					if(i[0 .. 3] == "gt;") {
						i += 3;
						res ~= ">";
					}
					else {
						++i;
						res ~= "&";
					}
					break;
				case 'q':
					if(i[0 .. 5] == "quot;") {
						i += 5;
						res ~= "\"";
					}
					else {
						++i;
						res ~= "&";
					}
					break;
				default:
					++i;
					res ~= "&";
					break;
				}
			}
			else {
				res ~= i[0];
				++i;
			}
		}
		return res;
	}
}

private class Lookup
{
    // Only space \n \r \t
    const ubyte whitespace[256] = 
    [
      // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
         0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  1,  0,  0,  1,  0,  0,  // 0
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 1
         1,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 2
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 3
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 4
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 5
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 6
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 7
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 8
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 9
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // A
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // B
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // C
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // D
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // E
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0   // F
    ];
    
    // Everything except whitespace / > ? : \0
    const ubyte name[256] =
    [
      // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
         0,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  0,  1,  1,  // 0
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
         0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  // 2
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  1,  1,  1,  0,  0,  // 3
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 4
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 5
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 6
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 7
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 8
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 9
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // A
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // B
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // C
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // D
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // E
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1   // F
    ];

    // Everything except < \0
    const ubyte text[256] =
    [
      // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
         0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 0
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 2
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  1,  1,  1,  // 3
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 4
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 5
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 6
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 7
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 8
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 9
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // A
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // B
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // C
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // D
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // E
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1   // F
    ];

    //Everything except whitespace / < > = ? ! : \0)
    const ubyte attributeName[256] =
    [
      // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
         0,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  0,  1,  1,  // 0
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
         0,  0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  // 2
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  1,  0,  0,  0,  0,  // 3
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 4
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 5
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 6
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 7
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 8
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 9
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // A
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // B
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // C
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // D
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // E
         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1   // F
    ];
}

version(Unittest)
{
import tango.io.Stdout;
import tango.io.File;

void doTests(Ch)()
{
	Ch[] t = "<?xml version=\"1.0\" ?><!DOCTYPE element [ <!ELEMENT element (#PCDATA)>]><element "
		"attr=\"1\" attr2=\"two\"><!--comment-->test&amp;&#x5a;<qual:elem /><el2 attr3 = "
		"'3three'><![CDATA[sdlgjsh]]><el3 />data<?pi test?></el2></element>";
	
	auto text = new StringCharIterator!(Ch)(t);
	auto itr = new XmlParser!(Ch)(text);
	assert(itr.next);
	assert(itr.value == "");
	assert(itr.type == XmlTokenType.Declaration);
	assert(itr.next);
	assert(itr.value == "version");
	assert(itr.next);
	assert(itr.value == "1.0");
	assert(itr.next);
	assert(itr.value == "element [ <!ELEMENT element (#PCDATA)>]");
	assert(itr.next);
	assert(itr.value == "element");
	assert(itr.depth == 0);
	assert(itr.next);
	assert(itr.value == "attr");
	assert(itr.next);
	assert(itr.value == "1");
	assert(itr.next);
	assert(itr.value == "attr2");
	assert(itr.next);
	assert(itr.value == "two");
	assert(itr.next);
	assert(itr.value == "comment");
	assert(itr.next);
	assert(itr.value == "test&amp;&#x5a;");
	assert(EntityDecoder!(Ch).decodeBuiltIn(itr.value) == "test&Z");
	assert(itr.next);
	assert(itr.qvalue == "qual");
	assert(itr.value == "elem");
	assert(itr.next);
	assert(itr.type == XmlTokenType.EndEmptyElement);
	assert(itr.next);
	assert(itr.value == "el2");
	assert(itr.depth == 1);
	assert(itr.next);
	assert(itr.value == "attr3");
	assert(itr.next);
	assert(itr.value == "3three");
	assert(itr.next);
	assert(itr.value == "sdlgjsh");
	assert(itr.next);
	assert(itr.value == "el3");
	assert(itr.depth == 2);
	assert(itr.next);
	assert(itr.type == XmlTokenType.EndEmptyElement);
	assert(itr.next);
	assert(itr.value == "data");
	assert(itr.next);
	assert(itr.value == "pi");
	assert(itr.next);
	assert(itr.value == "test");
	assert(itr.next);
	assert(itr.value == "el2");
	assert(itr.next);
	assert(itr.value == "element");
	assert(!itr.next);
	
	itr.reset;
	auto fitr = new XmlForwardNodeParser!(Ch)(itr);
	assert(fitr.nextElement(1));
	assert(fitr.type == XmlNodeType.Element);
	assert(fitr.nodeName == "qual:elem");
	assert(fitr.prefix == "qual");
	assert(fitr.localName == "elem");
	assert(fitr.nextElement(1));
	assert(fitr.type == XmlNodeType.Element);
	assert(fitr.nodeName == "el2");
	assert(fitr.nextAttribute);
	assert(fitr.nodeName == "attr3");
	assert(fitr.nodeValue == "3three");
	assert(fitr.nextNode(2));
	assert(fitr.type == XmlNodeType.CData);
	assert(fitr.nodeValue == "sdlgjsh");
	assert(fitr.nextElement(2));
	assert(fitr.type == XmlNodeType.Element);
	assert(fitr.nodeValue == "el3");
	assert(fitr.nextNode);
	assert(fitr.type == XmlNodeType.Data);
	assert(fitr.nodeValue == "data");
	assert(fitr.nextNode);
	assert(fitr.type == XmlNodeType.PI);
	assert(fitr.nodeName == "pi");
	assert(fitr.nodeValue == "test");
}

}

unittest
{	
	doTests!(char)();
	doTests!(wchar)();
	doTests!(dchar)();
}