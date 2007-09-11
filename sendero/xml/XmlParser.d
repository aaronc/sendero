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
import tango.text.Util;

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
	
	static this()
	{
		log = Log.getLogger("sendero.xml.XmlParser!(" ~ Ch.stringof ~ ")");
	}
	
	this(Ch[] text)
	{
		this.text = new StringCharIterator!(Ch)(text);	
	}
	
	this(ICharIterator!(Ch) text)
	{
		this.text = text;
	}
	
	private ICharIterator!(Ch) text;
	
	private XmlTokenType curType = XmlTokenType.None;
	private Int curLoc;
	private Int curLen;
	private Int curQLen;
	private ushort curDepth = 0;
	private bool inDeclaration = false;
	private bool retain = false;
	private bool err = false;
	
	final private void eatWhitespace()
	{
		//while(Lookup.whitespace[text[0]]) ++text;
		//text.forwardLookup(Lookup.whitespace);
		text.eatSpace;
	}
	
	final private bool doStartElement()
	{
		curType = XmlTokenType.StartElement;
		curLoc = text.location;
		//while(Lookup.name[text[0]]) ++text;
		//text.forwardLookup(Lookup.name);
		text.eatElemName;
		if(text.cur == ':') {
			curQLen = text.location - curLoc;
			++text;
			//while(Lookup.attributeName[text[0]]) ++text;
			//text.forwardLookup(Lookup.attributeName);
			text.eatAttrName;
			curLen = text.location - curLoc - curQLen - 1;
		}
		else {
			curLen = text.location - curLoc;
			curQLen = 0;
		}
		
		return true;
	}
	
	final private bool doEndElement()
	{
		curType = XmlTokenType.EndElement;
		curLoc = text.location;
		//while(Lookup.name[text[0]]) ++text;
		//text.forwardLookup(Lookup.name);
		text.eatElemName;
		if(text.cur == ':') {
			curQLen = text.location - curLoc;
			++text;
			//while(Lookup.attributeName[text[0]]) ++text;
			//text.forwardLookup(Lookup.attributeName);
			text.eatAttrName;
			curLen = text.location - curLoc - curQLen - 1;
		}
		else {
			curLen = text.location - curLoc;
			curQLen = 0;
		}
		
		//eatWhitespace;
		text.eatSpace;
		if(text.cur != '>')
			return doUnexpected();
		++text;
		
		--curDepth;
		
		return true;
	}
	
	final private bool doEndEmptyElement()
	{
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
		//while(Lookup.attributeName[text[0]]) ++text;
		//text.forwardLookup(Lookup.attributeName);
		text.eatAttrName;
		if(text.cur == ':') {
			curQLen = text.location - curLoc;
			++text;
			//while(Lookup.attributeName[text[0]]) ++text;
			//text.forwardLookup(Lookup.attributeName);
			text.eatAttrName;
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
		//eatWhitespace;
		text.eatSpace;
		Ch quote = text.cur;
		++text;
		
		curLoc = text.location;
		
		if(quote == '\'') {
			if(!text.forwardLocate('\'')) return doUnexpectedEOF();
		}
		else if (quote == '\"') {	
			if(!text.forwardLocate('\"')) return doUnexpectedEOF();
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
		if(!text.forwardLocate('<')) return doUnexpectedEOF();
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
			if(!text.forwardLocate('-')) return doUnexpectedEOF();
			if(text[0..3] == "-->") {
				curLen = text.location - curLoc;
				text += 3;
				curQLen = 0;
				return true;
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
			if(!text.forwardLocate(']')) return doUnexpectedEOF();
			if(text[0..3] == "]]>") {
				curLen = text.location - curLoc;
				curQLen = 0;
				text += 3;			
				return true;
			}
			++text;
		}
		return doUnexpectedEOF();
	}
	
	final private bool doPIName()
	{
		curType = XmlTokenType.PIName;
		curLoc = text.location;
		//while(Lookup.name[text[0]]) ++text;
		//text.forwardLookup(Lookup.name);
		text.eatElemName;
		
		curLen = text.location - curLoc;
		curQLen = 0;
		if(!text.good)
			return doUnexpectedEOF();		
		return true;
	}
	
	final private bool doPIValue()
	{		
		curType = XmlTokenType.PIValue;
		curLoc = text.location;
		
		while(text.good)
		{
			if(!text.forwardLocate('\?')) return doUnexpectedEOF();
			if(text[0..2] == "\?>") {
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
		//eatWhitespace;
		text.eatSpace;
		
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
		//eatWhitespace;
		text.eatSpace;
		
		curType = XmlTokenType.Doctype;
		curLoc = text.location;
		curQLen = 0;
		
		void skipInternalSubset()
		{
			text.forwardLocate(']');
			++text;
			return;
		}
		
        while(text.good) {
        	if(text.cur == '>') {
        		curLen = text.location - curLoc;
        		++text;
        		return true;
        	}
        	else if(text.cur == '[') {
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
		log.warn("Unexpected event");
		err = true;
		return false;
	}
	
	final private bool doUnexpectedEOF()
	{
		log.warn("Unexpected EOF");
		err = true;
		return false;
	}
	
	final private bool doEndOfStream()
	{
		return false;
	}
	
	final private bool doInElement()
	{
		switch(text.cur)
		{
		case '=':
			return doAttributeValue();
			break;
		case '/':
			return doEndEmptyElement();
			break;
		case '>':
			++curDepth;
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
		switch(text.cur)
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
		if(text.cur == '<') {
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
		}
		else {
			return doData();
		}
	}
	
	final bool next()
	{	
		if(retain) {
			retain = false;
			return true;
		}
		
		//eatWhitespace;
		text.eatSpace;
		
		if(!text.good)
			return doEndOfStream();
		
		if(inDeclaration)
			return doInDeclaration();
		
		switch(curType)
		{
		case XmlTokenType.StartElement:
		case XmlTokenType.StartNSElement:
		case XmlTokenType.AttrName:
		case XmlTokenType.AttrNSName:
		case XmlTokenType.AttrValue:
			return doInElement();
			break;
		case XmlTokenType.PIName:
			return doPIValue();
			break;
		default:
			return doMain();
			break;
		}
	}
	
	final XmlTokenType type()
	{
		return curType;
	}
	
	final Ch[] qvalue()
	{
		return text.randomAccessSlice(loc, loc + qlen);
	}
	
	final Ch[] value()
	{
		if(qlen) {
			return text.randomAccessSlice(loc + qlen + 1, loc + qlen + 1 + len);
		}
		return text.randomAccessSlice(loc, loc + len);
	}
	
	final Int loc()
	{
		return curLoc;
	}
	
	final Int qlen()
	{
		return curQLen;
	}
	
	final Int len()
	{
		return curLen;
	}
	
	final ushort depth()
	{
		return curDepth;
	}
	
	final bool error()
	{
		return err;
	}
	
	final void retainCurrent()
	{
		retain = true;
	}
	
	final bool reset()
	{
		if(!text.seek(0)) return false;
		reset_;
		return true;
	}
	
	final void reset(Ch[] newText)
	{
		text = new StringCharIterator!(Ch)(newText);
		reset_;
	}
	
	final void reset(ICharIterator!(Ch) newText)
	{
		text = newText;
		reset_;
	}
	
	final private void reset_()
	{
		curDepth = 0;
		curLoc = 0;
		curLen = 0;
		curQLen = 0;
		curType = XmlTokenType.None;
		inDeclaration = false;
		err = false;
		retain = false;
	}
}

class XmlParser2(Ch = char, Int = uint) : IXmlTokenIterator!(Ch, Int)
{
	private static Logger log;
	
	static this()
	{
		log = Log.getLogger("sendero.xml.XmlParser2!(" ~ Ch.stringof ~ ")");
	}
	
	this(Ch[] text)
	{
		this.text = text;
		this.p = text.ptr;
		this.length = text.length;
	}
	
	private Ch[] text;
	private Ch* p;
	private size_t length;
	private size_t itr = 0;
	
	private XmlTokenType curType = XmlTokenType.None;
	private Int curLoc;
	private Int curLen;
	private Int curQLen;
	private ushort curDepth = 0;
	private bool inDeclaration = false;
	private bool retain = false;
	private bool err = false;
	
	
	final private bool locate(Ch ch)
	{
		auto l = indexOf!(Ch)(p + itr, ch, length - itr);
		if(l == length - itr) return false;
		itr += l;
		return true;
	}
	
	/+final private void lookup(ubyte[256] lookupTable)
	{
		version(D_InlineAsm_X86)
		{
			static if (Ch.sizeof == 1)
			{
				void* this_ = cast(void*)this;
				ubyte* lookup_ = lookupTable.ptr;
				asm
				{
					mov EBX, this_;
					mov ECX, [EBX + length];
					mov EAX, [EBX + itr];
					sub ECX, EAX;
                	jng end;
                	
                	add EAX, [EBX + p];           	
                	
                	mov EDI, lookup_;
                	test:;
                		movzx EBX, byte ptr [EAX];
                		add EDI, EBX;
                		mov DL, byte ptr[EDI];
	                	and DL, DL;
	                	jz finish;
	                	sub EDI, EBX;
	                	inc EAX;
	                	loop test;
	                	
	                finish:;
	                	mov EBX, this_;
	                	sub EAX, [EBX + p];
	                	mov [EBX + itr], EAX;
	                
	                end:;	
				}
			}
			else
			{
				//while(itr < end && lookupTable[itr[0]]) ++this;
				while(itr < length && lookupTable[text[itr]]) ++itr;
			}
		}
		else
		{
			//while(itr < end && lookupTable[itr[0]]) ++this;
			while(itr < length && lookupTable[text[itr]]) ++itr;
		}			
	}+/
	
	const static ubyte name[64] =
	    [
	      // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
	         0,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  0,  1,  1,  // 0
	         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
	         0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  // 2
	         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  1,  1,  1,  0,  0,];  // 3
	
	 const static ubyte attributeName[64] =
		    [
		      // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
		         0,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  0,  1,  1,  // 0
		         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
		         0,  0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  // 2
		         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  1,  0,  0,  0,  0];  // 3
	
	final bool eatElemName()
	{      
	              while (itr < length)
	                      {
	                      Ch c = p[itr];
	                      if (c > 63 || name[c])
	                          ++itr;
	                      else
	                         {
	                         return true;
	                         }
	                      }
	                return false;
	    }
	
	final bool eatAttrName()
	{      
	               while (itr < length)
	                      {
	                      Ch c = p[itr];
	                      if (c > 63 || attributeName[c])
	                          ++itr;
	                      else
	                         {
	                        return true;
	                         }
	                      }
	                return false;
	    }
	
	 

	 const static ubyte whitespace[33] = 
		    [
		      // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
		         0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  1,  0,  0,  1,  0,  0,  // 0
		         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 1
		         1];
	
	    final bool eatWhitespace()
	    {      
	                while (itr < length)
	                      {
	                	  Ch c = p[itr];
	                      if (c <= 32 && whitespace[c]) {
	                          ++itr;
	                      }
	                      else
	                         {
	                         return true;
	                         }
	                      }
	                return false;
	    }
	
	final private Ch getChar(uint i = 0)
	{
		version(D_InlineAsm_X86)
		{
			static if (Ch.sizeof == 1)
			{
				void* this_ = cast(void*)this;
                asm
                {
                	mov EBX, this_;
                	mov ECX, [EBX + itr];
                    add ECX, i;
                    
                    mov EAX, [EBX + length];
                    sub EAX, ECX;
                    jng fail;
                    
                    add ECX, [EBX + p];
                    
                    mov AL, [ECX];
                    
                    jmp end;
                    
                    fail:;
                    	xor EAX, EAX;
                    	
                    end:;
                }
            }
            else
            {
            	if(itr + i < length) return text[itr + i];
            	else return '\0';
            }
		}
		else
		{
			if(itr + i < length) return text[itr + i];
        	else return '\0';
		}
	}
	
	final private Ch[] getSlice(uint x, uint y)
	{
		if(itr + x >= length)
			return "\0";
		if(itr + y >= length)
			return text[itr + x .. $];
		return text[itr + x .. itr + y];
	}
	
	final private bool doUnexpected(char[] expected = null)
	{
		log.warn("Unexpected event, expected: " ~ expected);
		err = true;
		return false;
	}
	
	final private bool doUnexpectedEOF()
	{
		log.warn("Unexpected EOF");
		err = true;
		return false;
	}
	
	final private bool doEndOfStream()
	{
		return false;
	}
	
	final private bool doStartElement()
	{
		curType = XmlTokenType.StartElement;
		curLoc = itr;
		eatElemName;
		if(getChar == ':') {
			curQLen = itr - curLoc;
			++itr;
			eatAttrName;
			curLen = itr - curLoc - curQLen - 1;
		}
		else {
			curLen = itr - curLoc;
			curQLen = 0;
		}
		
		return true;
	}
	
	final private bool doEndElement()
	{
		curType = XmlTokenType.EndElement;
		curLoc = itr;
		eatElemName;
		if(getChar == ':') {
			curQLen = itr - curLoc;
			++itr;
			eatAttrName;
			curLen = itr - curLoc - curQLen - 1;
		}
		else {
			curLen = itr - curLoc;
			curQLen = 0;
		}
		
		eatWhitespace;
		if(getChar != '>')
			return doUnexpected();
		++itr;
		
		--curDepth;
		
		return true;
	}
	
	final private bool doEndEmptyElement()
	{
		if(getSlice(0, 2) != "/>")
			return doUnexpected();
		
		curType = XmlTokenType.EndEmptyElement;
		curLoc = itr;
		itr += 2;
		curLen = 0;
		curQLen = 0;
		
		return true;
	}
	
	final private bool doAttributeName()
	{
		curType = XmlTokenType.AttrName;
		curLoc = itr;
		++itr;
		eatAttrName;
		if(getChar == ':') {
			curQLen = itr - curLoc;
			++itr;
			eatAttrName;
			curLen = itr - curLoc - curQLen - 1;
		}
		else {
			curLen = itr - curLoc;
			curQLen = 0;
		}
		
		if(itr >= length)
			return doUnexpectedEOF();		
		return true;
	}
	
	final private bool doAttributeValue()
	{
		curType = XmlTokenType.AttrValue;
		++itr;
		eatWhitespace;
		Ch quote = getChar;
		++itr;
		
		curLoc = itr;
		
		if(quote == '\'') {
			if(!locate('\'')) return doUnexpectedEOF();
		}
		else if (quote == '\"') {	
			if(!locate('\"')) return doUnexpectedEOF();
		}
		else {
			return doUnexpected;
		}
		curLen = itr - curLoc;
		curQLen = 0;
		
		++itr; //Skip end quote
		
		return true;
	}
	
	final private bool doData()
	{
		curType = XmlTokenType.Data;
		curLoc = itr;
		if(!locate('<')) return doUnexpectedEOF();
		curLen = itr - curLoc;
		curQLen = 0;
		return true;
	}
	
	final private bool doComment()
	{
		curType = XmlTokenType.Comment;
		curLoc = itr;
		
		while(itr < length)
		{
			if(!locate('-')) return doUnexpectedEOF();
			if(getSlice(0,3) == "-->") {
				curLen = itr - curLoc;
				itr += 3;
				curQLen = 0;
				return true;
			}
			++itr;
		}
		return doUnexpectedEOF();
	}
	
	final private bool doCData()
	{
		curType = XmlTokenType.CData;
		curLoc = itr;
		
		while(itr < length)
		{
			if(!locate(']')) return doUnexpectedEOF();
			if(getSlice(0,3) == "]]>") {
				curLen = itr - curLoc;
				curQLen = 0;
				itr += 3;
				return true;
			}
			++itr;
		}
		return doUnexpectedEOF();
	}
	
	final private bool doPIName()
	{
		curType = XmlTokenType.PIName;
		curLoc = itr;
		eatElemName;
		
		curLen = itr - curLoc;
		curQLen = 0;
		if(itr >= length)
			return doUnexpectedEOF();		
		return true;
	}
	
	final private bool doPIValue()
	{		
		curType = XmlTokenType.PIValue;
		curLoc = itr;
		
		while(itr < length)
		{
			if(!locate('\?')) return doUnexpectedEOF();
			if(getSlice(0,2) == "\?>") {
				curLen = itr - curLoc;
				curQLen = 0;
				itr += 2;
				return true;
			}
			++itr;
		}
		return doUnexpectedEOF();
	}
	
	final private bool doDeclaration()
	{
		eatWhitespace;
		
		if(itr >= length)
			return doEndOfStream();
		
		curType = XmlTokenType.Declaration;
		curLoc = itr;
		curQLen = 0;
		
		inDeclaration = true;
		
		return true;
	}
	
	final private bool doDoctype()
	{
		eatWhitespace;
		
		curType = XmlTokenType.Doctype;
		curLoc = itr;
		curQLen = 0;
		
		void skipInternalSubset()
		{
			locate(']');
			++itr;
			return;
		}
		
		while(itr < length) {
			if(getChar == '>') {
				curLen = itr - curLoc;
				++itr;
        		return true;
        	}
			else if(getChar == '[') {
        		//++text;
				++itr;
        		skipInternalSubset;
        	}
			else ++itr;
        }
		
		if(itr >= length)
			return doUnexpectedEOF();
		
		return true;
	}
	
	final private bool doMain()
	{
		if(getChar == '<') {
			switch(getChar(1))
			{
			case '!':
				if(getSlice(2,4) == "--") {
					itr += 4;
					return doComment();
				}
				else if(getSlice(2,9) == "[CDATA[") {
					itr += 9;
					return doCData();
				}
				else if(getSlice(2,9) == "DOCTYPE") {
					itr += 9;
					return doDoctype();
				}
				else {
					return doUnexpected();
				}
				break;
			case '\?':
				if(getSlice(2,5)  == "xml") {
					itr += 5;
					return doDeclaration();
				}
				else {
					itr += 2;
					return doPIName();
				}
				break;
			case '/':
				itr += 2;
				return doEndElement();
			default:
				++itr;
				return doStartElement();
				break;
			}
		}
		else {
			return doData();
		}
	}
	
	final private bool doInDeclaration()
	{
		switch(getChar)
		{
		case '=':
			return doAttributeValue();
			break;
		case '\?':
			if(getChar(1) != '>')
				return false;
			inDeclaration = false;
			itr += 2;
			return doMain();
			break;
		default:
			return doAttributeName();
			break;
		}
	}
	
	final private bool doInElement()
	{
		switch(getChar)
		{
		case '=':
			return doAttributeValue();
			break;
		case '/':
			return doEndEmptyElement();
			break;
		case '>':
			++curDepth;
			++itr;
			return doMain();
			break;
		default:
			return doAttributeName();
			break;
		}
	}
	
	public static struct Token
	{
		size_t loc;
		uint len;
		ushort qlen;
		ubyte depth;
		XmlTokenType type;
	}
	
	public static class Index
	{
		Token[] tokens;
		uint[] first;
		uint[] second;
		uint[] third;
	}
	
	Index parse()
	{
		Token[] res;
		auto i = 0;
		auto l = 1000;
		res.length = l;
		while(itr < length)
		{
			eatWhitespace;
			
			if(itr >= length)
				break;
			
			if(inDeclaration)
				doInDeclaration();
			
			switch(curType)
			{
			case XmlTokenType.StartElement:
			case XmlTokenType.StartNSElement:
			case XmlTokenType.AttrName:
			case XmlTokenType.AttrNSName:
			case XmlTokenType.AttrValue:
				doInElement();
				break;
			case XmlTokenType.PIName:
				doPIValue();
				break;
			default:
				doMain();
				break;
			}
			
			res[i].loc = loc;
			res[i].len = len;
			res[i].qlen = qlen;
			res[i].type = type;
			res[i].depth = depth;
			++i;
			if(i >= l) {
				l += 1000;
				res.length = l;
			}
		}
		auto index = new Index;
		index.tokens = res[0 .. i];
		i = 0;
		foreach(t; index.tokens)
		{
			if(t.type == XmlTokenType.StartElement || t.type == XmlTokenType.StartNSElement)
			{
				switch(t.depth)
				{
				case 1:
					index.first ~= i;
					break;
				case 2:
					index.second ~= i;
					break;
				case 3:
					index.third ~= i;
					break;
				default:
					break;
				}
			}
			++i;
		}
		return index;
	}

	bool next() {
		if(retain) {
			retain = false;
			return true;
		}
		
		eatWhitespace;
		
		if(itr >= length)
			return doEndOfStream();
		
		if(inDeclaration)
			return doInDeclaration();
		
		switch(curType)
		{
		case XmlTokenType.StartElement:
		case XmlTokenType.StartNSElement:
		case XmlTokenType.AttrName:
		case XmlTokenType.AttrNSName:
		case XmlTokenType.AttrValue:
			return doInElement();
			break;
		case XmlTokenType.PIName:
			return doPIValue();
			break;
		default:
			return doMain();
			break;
		}
	}
	
	final XmlTokenType type()
	{
		return curType;
	}
	
	final Ch[] qvalue()
	{
		return text[loc .. loc + qlen];
	}
	
	final Ch[] value()
	{
		if(qlen) {
			return text[loc + qlen + 1 .. loc + qlen + 1 + len];
		}
		return text[loc .. loc + len];
	}
	
	final Int loc()
	{
		return curLoc;
	}
	
	final Int qlen()
	{
		return curQLen;
	}
	
	final Int len()
	{
		return curLen;
	}
	
	final ushort depth()
	{
		return curDepth;
	}
	
	final bool error()
	{
		return err;
	}
	
	final void retainCurrent()
	{
		retain = true;
	}
	
	final bool reset()
	{
		reset_;
		return true;
	}
	
	final void reset(Ch[] newText)
	{
		text = newText;
		p = newText.ptr;
		length = newText.length;
		reset_;
	}
	
	final private void reset_()
	{
		itr = 0;
		curDepth = 0;
		curLoc = 0;
		curLen = 0;
		curQLen = 0;
		curType = XmlTokenType.None;
		inDeclaration = false;
		err = false;
		retain = false;
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
	
	this(ICharIterator!(Ch) text)
	{
		this.parser = new XmlParser!(Ch)(text);
	}
	
	this(Ch[] text)
	{
		this.parser = new XmlParser!(Ch)(text);
	}
	
	private XmlParser!(Ch) parser;
	
	private XmlNodeType curType;
	
	private uint attrLoc = 0;
	private uint attrLen = 0;
	private uint attrQLen = 0;
	
	final bool nextElement() {
		while(nextNode) {
			if(this.type == XmlNodeType.Element)
				return true;
		}
		return false;
	}
	
	final bool nextElement(ushort depth)
	{
		while(nextNode(depth)) {
			if(this.type == XmlNodeType.Element)
				return true;
		}
		return false;
	}
	
	final bool nextElement(ushort depth, Ch[] name)
	{
		while(nextElement(depth)) {
			if(this.nodeName == name)
				return true;
		}
		return false;
	}
	
	final private bool processNode()
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
	
	final bool nextNode()
	{
		while(parser.next) {
			if(processNode) return true;
		}
		return false;
	}
	
	final bool nextNode(ushort depth)
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
	
	final private void doPI()
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
	
	final bool nextAttribute()
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
	
	final XmlNodeType type()
	{
		return curType;
	}
	
	final Ch[] prefix()
	{
		if(curType == XmlNodeType.Attribute || curType == XmlNodeType.PI) {
			return parser.text.randomAccessSlice(attrLoc, attrLoc + attrQLen);
		}
		
		return parser.qvalue;
	}
	
	final Ch[] localName()
	{
		if(curType == XmlNodeType.Attribute || curType == XmlNodeType.PI) {
			if(attrQLen) return parser.text.randomAccessSlice(attrLoc + attrQLen + 1, attrLoc + attrQLen + attrLen + 1);
			else return parser.text.randomAccessSlice(attrLoc, attrLoc + attrLen);
		}
		
		return parser.value;
	}
	
	final Ch[] nodeName()
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
	
	final Ch[] nodeValue()
	{
		if(parser.type == XmlTokenType.Data)
			return EntityDecoder!(Ch).decodeBuiltIn(parser.value);
		else return parser.value;
	}
	
	final Ch[] nodeRawValue()
	{
		return parser.value;
	}
	
	final ushort depth()
	{
		return parser.depth;
	}
	
	final bool reset()
	{
		return parser.reset;
	}
	
	final void reset(Ch[] newText)
	{
		return parser.reset(newText);
	}
	
	final void reset(ICharIterator!(Ch) newText)
	{
		return parser.reset(newText);
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

void testParser(Ch)(IXmlTokenIterator!(Ch, uint) itr)
{
	assert(itr.next);
	assert(itr.value == "");
	assert(itr.type == XmlTokenType.Declaration, Integer.toUtf8(itr.type));
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
}

void doTests(Ch)()
{
	Ch[] t = "<?xml version=\"1.0\" ?><!DOCTYPE element [ <!ELEMENT element (#PCDATA)>]><element "
		"attr=\"1\" attr2=\"two\"><!--comment-->test&amp;&#x5a;<qual:elem /><el2 attr3 = "
		"'3three'><![CDATA[sdlgjsh]]><el3 />data<?pi test?></el2></element>";
	
	auto text = new StringCharIterator!(Ch)(t);
	auto itr = new XmlParser!(Ch)(text);
	
	testParser!(Ch)(itr);
	
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
	
	auto itr2 = new XmlParser2!(Ch)(t);
	testParser!(Ch)(itr2);
}

}

unittest
{	
	doTests!(char)();
	doTests!(wchar)();
	doTests!(dchar)();
}