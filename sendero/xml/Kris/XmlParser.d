/** 
 * Copyright: Copyright (C) 2007 Aaron Craelius.  All rights reserved.
 * License:   BSD Style
 * Authors:   Aaron Craelius
 */


module sendero.xml.XmlParser;

enum XmlTokenType : ubyte {StartElement = 0, StartNSElement = 1, AttrValue = 2, AttrName = 3, AttrNSName = 4, EndElement = 5, EndNSElement = 6, EndEmptyElement = 7, Data = 8, Comment = 9, CData = 10, Doctype = 11, PI = 12, None  = 13};

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
    //void retainCurrent();
    ushort depth();
    //bool error();
    //char[] errorMsg();
}

public import sendero.xml.IForwardNodeIterator;

import tango.util.log.Log;
import Util = tango.text.Util;
import Unicode = tango.text.convert.Utf;
import Integer = tango.text.convert.Integer;


private struct Iterator(Ch)
{
        private Ch*     end;
        private size_t  len;
        private Ch[]    text;
        private Ch*     point;

        final bool good()
        {
                return point < end;
        }
        
        final Ch[] opSlice(size_t x, size_t y)
        in {
                if ((point+y) >= end || y < x)
                     assert(false);                  
           }
        body
        {               
                return point[x .. y];
        }
        
        final void seek(size_t position)
        in {
                if (position >= len) 
                    assert(false);
           }
        body
        {
                point = text.ptr + position;
        }

        final void reset(Ch[] newText)
        {
                this.text = newText;
                this.len = newText.length;
                this.point = text.ptr;
                this.end = point + len;
        }

        final bool forwardLocate(Ch ch)
        {
            version(D_InlineAsm_X86)
            {   
                static if(Ch.sizeof == 1)
                {   
                    char* pitr_ = point;
                    void* e_ = end;
                    bool res;
                    asm
                    {
                         mov EDI, pitr_;
                         mov ECX, e_;
                         sub   ECX, EDI;
                         jng    fail;
                         movzx   EAX, ch;
                         
                         cld;
                         repnz;
                         scasb;
                         jnz   fail;
                         
                         dec EDI;
                         mov   pitr_, EDI;
                         mov   AL, 1;
                         jmp   end_;
                     fail:;
                         xor   AL, AL;
                     end_:;
                         mov res, AL;
                    }
                    point = pitr_;
                    return res;
                }
                else
                {
                    auto tmp = end - point;
                    auto l = Util.indexOf!(Ch)(point, ch, tmp);
                    if (l < tmp) 
                       {
                       point += l;
                       return true;
                       }
                    return false;
                }
            }
            else
            {
                auto tmp = end - point;
                    auto l = Util.indexOf!(Ch)(point, ch, tmp);
                    if (l < tmp) 
                       {
                       point += l;
                       return true;
                       }
                    return false;
            }
        }
        
        final Ch* eatElemName()
        {      
                auto p = point;
                auto e = end;
                while (p < e)
                      {
                      auto c = *p;
                      if (c > 63 || name[c])
                          ++p;
                      else
                         break;
                      }
                return point = p;
        }
        
        final Ch* eatAttrName()
        {      
                auto p = point;
                auto e = end;
                while (p < e)
                      {
                      auto c = *p;
                      if (c > 63 || attributeName[c])
                          ++p;
                      else
                         break;
                      }
                return point = p;
        }
        
        final bool eatSpace()
        {
                auto p = point;
                auto e = end;
                while (p < e)
                      {                
                      if (*p <= 32)                                          
                          ++p;
                      else
                         {
                         point = p;
                         return true;
                         }                                  
                      }
               point = p;
               return false;
        }

        private static const ubyte name[64] =
        [
             // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
                0,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  0,  1,  1,  // 0
                1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
                0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  // 2
                1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  1,  1,  1,  0,  0   // 3
        ];

        private static const ubyte attributeName[64] =
        [
             // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
                0,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  0,  1,  1,  // 0
                1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
                0,  0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  // 2
                1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  1,  0,  0,  0,  0   // 3
        ];
}

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
class XmlParser(Ch = char, Int = uint) 
{
        private static Logger log;

        private Iterator!(Ch)   text;
        private Ch[]            qName;        
        private Ch[]            token;        
        private bool            err = false;
        private ushort          curDepth = 0;
        private XmlTokenType    curType = XmlTokenType.None;

        static this()
        {
                log = Log.getLogger("sendero.xml.XmlParser!(" ~ Ch.stringof ~ ")");
        }
        
        this (Ch[] content)
        {
                reset (content);
        }
        
        private void eatWhitespace()
        {
                text.eatSpace;
        }

        private bool doEndEmptyElement()
        {
                if(text[0..2] != "/>")
                   return doUnexpected("/>");
                
                curType = XmlTokenType.EndEmptyElement;
                token = qName = null;
                text.point += 2;
                return true;
        }
        
        private bool doAttributeName()
        {
                auto p = text.point;
                ++text.point;
                auto q = text.eatAttrName;

                if (*text.point == ':')
                   {
                   curType = XmlTokenType.AttrNSName;
                   qName = p[0 .. q - p];
                   p = ++text.point;
                   q = text.eatAttrName;
                   token = p[0 .. q - p];
                   }
                else 
                   {
                   curType = XmlTokenType.AttrName;
                   token = p[0 .. q - p];
                   }
                
                if (! text.good)
                      return doUnexpectedEOF();               
                return true;
        }
        
        private bool doAttributeValue()
        {
                if (*text.point != '=') 
                     return doUnexpected("=");

                ++text.point;
                text.eatSpace;
                Ch quote = *text.point;
                auto p = ++text.point;
                curType = XmlTokenType.AttrValue;
                
                if (quote == '\'') 
                   {
                   if (! text.forwardLocate('\'')) 
                         return doUnexpectedEOF();
                   }
                else 
                   if (quote == '\"') 
                      {       
                      if (! text.forwardLocate('\"')) 
                            return doUnexpectedEOF();
                      }
                   else 
                      {
                      return doUnexpected("\' or \"");
                      }
                token = p[0 .. text.point - p];
                
                ++text.point; //Skip end quote
                return true;
        }
      
        private bool doComment()
        {
                auto p = text.point;
                curType = XmlTokenType.Comment;
                
                while (text.good)
                      {
                      if (! text.forwardLocate('-')) 
                            return doUnexpectedEOF();

                      if (text[0..3] == "-->") 
                         {
                         token = p [0 .. text.point - p];
                         qName = null;
                         text.point += 3;
                         return true;
                         }
                      ++text.point;
                      }
                return doUnexpectedEOF();
        }
        
        private bool doCData()
        {
                auto p = text.point;
                curType = XmlTokenType.CData;
                
                while (text.good)
                      {
                      if (! text.forwardLocate(']')) 
                            return doUnexpectedEOF();
                      if (text[0..3] == "]]>") 
                         {
                         token = p [0 .. text.point - p];
                         qName = null;
                         text.point += 3;                      
                         return true;
                         }
                      ++text.point;
                      }
                return doUnexpectedEOF();
        }
        
        private bool doPI()
        {
                curType = XmlTokenType.PI;
                auto p = text.point;
                text.eatElemName;
                ++text.point;
                while (text.good)
                      {
                      if (! text.forwardLocate('\?')) 
                            return doUnexpectedEOF();

                      if (text.point[1] == '>') 
                         {
                         token = p [0 .. text.point - p];
                         text.point += 2;
                         return true;
                         }
                      ++text.point;
                      }
                return doUnexpectedEOF();
        }
        
        private bool doDoctype()
        {
                text.eatSpace;
                auto p = text.point;
                curType = XmlTokenType.Doctype;
                                
                while (text.good) 
                      {
                      if (*text.point == '>') 
                         {
                         token = p [0 .. text.point - p];
                         qName = null;
                         ++text.point;
                         return true;
                         }
                      else 
                         if (*text.point == '[') 
                            {
                            ++text.point;
                            text.forwardLocate(']');
                            ++text.point;
                            }
                         else 
                            ++text.point;
                      }

                if (! text.good)
                      return doUnexpectedEOF();
                return true;
        }
        
        private bool doUnexpected(char[] msg = null)
        {
                log.warn("Unexpected event " ~ msg ~ " " ~ Integer.toUtf8(curType));
                err = true;
                return false;
        }
        
        private bool doUnexpectedEOF()
        {
                log.warn("Unexpected EOF");
                err = true;
                return false;
        }
        
        private bool doEndOfStream()
        {
                return false;
        }
              
        private bool doMain()
        {
                auto p = text.point;
                if (*p != '<') 
                   {
                   auto e = text.end;
                   auto q = p;
                   do {
                      if (*++p == '<')
                         {
                         curType = XmlTokenType.Data;
                         token = q [0 .. p - q];
                         text.point = p;
                         return true;
                         }
                      } while (p < e);
                   return doUnexpectedEOF();
                   }

                switch (p[1])
                       {
                       case '/':
                            p = (text.point += 2);
                            auto e = text.end;
                            auto q = p;
                            while (q < e)
                                  {
                                  auto c = *q;
                                  if (c > 63 || text.name[c])
                                      ++q;
                                  else
                                     break;
                                  }
                            text.point = q;

                            if (*q != ':') 
                               {
                               curType = XmlTokenType.EndElement;
                               token = p[0 .. q - p];
                               }
                            else 
                               {
                               qName = p[0 .. q - p];
                               p = ++text.point;
                               q = text.eatAttrName;
                               token = p[0 .. q - p];
                               }    
                
                            while (*q <= 32 && q <= text.end)
                                   ++q;

                            if (*q == '>')
                               {
                               ++text.point;
                               --curDepth;
                               return true;
                               }
                            return doUnexpected(">");

                       case '!':
                            if (text[2..4] == "--") 
                               {
                               text.point += 4;
                               return doComment();
                               }       
                            else 
                               if (text[2..9] == "[CDATA[") 
                                  {
                                  text.point += 9;
                                  return doCData();
                                  }
                               else 
                                  if (text[2..9] == "DOCTYPE") 
                                     {
                                     text.point += 9;
                                     return doDoctype();
                                     }
                            return doUnexpected("!");

                       case '\?':
                            text.point += 2;
                            return doPI();

                       default:
                            p = ++text.point;
                            auto q = p;
                            auto e = text.end;
                            while (q < e)
                                  {
                                  auto c = *q;
                                  if (c > 63 || text.name[c])
                                      ++q;
                                  else
                                     break;
                                  }
                            text.point = q;

                            if (*q != ':') 
                               {
                               curType = XmlTokenType.StartElement;
                               token = p [0 .. q - p];
                               }
                            else
                               {
                               curType = XmlTokenType.StartNSElement;
                               qName = p [0 .. q - p];
                               p = ++text.point;
                               q = text.eatAttrName;
                               token = p [0 .. q - p];
                               }
                            return true;
                       }

               return false;
        }
        
        final bool next()
        {      
                auto p = text.point;
                if (*p <= 32) 
                   {
                   do {
                      if (++p >= text.end)                                      
                          return doEndOfStream();
                      } while (*p <= 32);
                   text.point = p;
                   }
                
                if (curType > 4) 
                    return doMain;

                if (curType > 2) 
                    return doAttributeValue;

                // in element
                switch (*p)
                       {
                       case '/':
                            return doEndEmptyElement();

                       case '>':
                            ++curDepth;
                            ++text.point;
                            return doMain();

                       default:
                            break;
                       }
                return doAttributeName();
        }
        
        final XmlTokenType type()
        {
                return curType;
        }
        
        final Ch[] qvalue()
        {
                return qName;
        }
        
        final Ch[] value()
        {
                return token;
        }

        final ushort depth()
        {
                return curDepth;
        }
        
        final bool error()
        {
                return err;
        }

        final bool reset()
        {
                text.seek(0);
                reset_;
                return true;
        }
        
        final void reset(Ch[] newText)
        {
                text.reset (newText);
                reset_;                
        }
        
        private void reset_()
        {
                err = false;
                curDepth = 0;
                curType = XmlTokenType.None;
                
                static if(Ch.sizeof == 1)
                {
                    //Read UTF8 BOM
                    if(*text.point == 0xef)
                    {
                        if(text.point[1] == 0xbb)
                        {
                            if(text.point[2] == 0xbf)
                                text.point += 3;
                        }
                    }
                }
                
                //TODO enable optional declaration parsing
                text.eatSpace;
                if(*text.point == '<')
                {
                    if(text.point[1] == '\?')
                    {
                        if(text[2..5] == "xml")
                        {
                            text.point += 5;
                            text.forwardLocate('\?');
                            text.point += 2;
                        }
                    }
                }
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
                return str;
                              
/+
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
+/
        }
}


/**
 * Forward reading node based Xml Parser.
 */
class XmlForwardNodeParser(Ch) : IForwardNodeIterator!(Ch)
{
        private XmlParser!(Ch) parser;
        
        private XmlNodeType curType;
        
        private uint attrLoc = 0;
        private uint attrLen = 0;
        private uint attrQLen = 0;
        
        this(XmlParser!(Ch) parser)
        {
                this.parser = parser;
        }
        
        this(Ch[] text)
        {
                this.parser = new XmlParser!(Ch)(text);
        }
        
        final bool nextElement() 
        {
                while (nextNode) 
                      {
                      if (this.type == XmlNodeType.Element)
                          return true;
                      }
                return false;
        }
        
        final bool nextElement(ushort depth)
        {
                while (nextNode(depth)) 
                      {
                      if (this.type == XmlNodeType.Element)
                          return true;
                      }
                return false;
        }
        
        final bool nextElement (ushort depth, Ch[] name)
        {
                while (nextElement(depth)) 
                      {
                      if (this.nodeName == name)
                          return true;
                      }
                return false;
        }
        
        final private bool processNode()
        {
                if (parser.type == XmlTokenType.AttrName   || 
                    parser.type == XmlTokenType.AttrNSName || 
                    parser.type == XmlTokenType.AttrValue)
                    return false;
                
                switch (parser.type)
                       {
                       case XmlTokenType.StartElement, 
                            XmlTokenType.StartNSElement:
                            curType = XmlNodeType.Element;
                            break;

                       case XmlTokenType.EndElement, 
                            XmlTokenType.EndNSElement, 
                            XmlTokenType.EndEmptyElement, 
                            XmlTokenType.AttrName, 
                            XmlTokenType.AttrNSName, 
                            XmlTokenType.AttrValue, 
                            XmlTokenType.Declaration, 
                            XmlTokenType.Doctype:
                            return false;

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
                while (parser.next) 
                      {
                      if (processNode) 
                          return true;
                      }
                return false;
        }
        
        final bool nextNode(ushort depth)
        {
                while (parser.next) 
                      {
                      if (parser.depth == depth) 
                         {
                         if (processNode) 
                             return true;
                         }
                      else 
                         if (parser.depth < depth && 
                            (parser.type == XmlTokenType.EndElement || 
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
                
                if (parser.next) 
                   {
                   if (parser.type != XmlTokenType.PIValue) 
                       parser.retainCurrent;
                   }       
        }
        
        final bool nextAttribute()
        {
                if (parser.type == XmlNodeType.Element || 
                    parser.type == XmlNodeType.Attribute)
                    {
                    if (parser.next) 
                       {
                       if (parser.type == XmlTokenType.AttrName || 
                           parser.type == XmlTokenType.AttrNSName) 
                           {
                           attrLoc = parser.loc;
                           attrLen = parser.len;
                           attrQLen = parser.qlen;
                           }
                                     
                       if (! parser.next) 
                             return false;
                                
                       if (parser.type != XmlTokenType.AttrValue) 
                           return false;
                                
                       curType = XmlNodeType.Attribute;
                       return true;
                       }
                    else 
                       {
                       parser.retainCurrent;
                       return false;
                       }
                    }

                return false;
        }
        
        final XmlNodeType type()
        {
                return curType;
        }
        
        final Ch[] prefix()
        {
                if (curType == XmlNodeType.Attribute || 
                    curType == XmlNodeType.PI) 
                    {
                    return parser.text.randomAccessSlice(attrLoc, attrLoc + attrQLen);
                    }
                
                return parser.qvalue;
        }
        
        final Ch[] localName()
        {
                if (curType == XmlNodeType.Attribute || 
                    curType == XmlNodeType.PI) 
                    {
                    if (attrQLen) 
                        return parser.text.randomAccessSlice (attrLoc + attrQLen + 1, attrLoc + attrQLen + attrLen + 1);
                    return parser.text.randomAccessSlice(attrLoc, attrLoc + attrLen);
                    }
                
                return parser.value;
        }
        
        final Ch[] nodeName()
        {
                if (curType == XmlNodeType.Attribute || 
                    curType == XmlNodeType.PI) 
                    {
                    if (attrQLen) 
                        return parser.text.randomAccessSlice(attrLoc, attrLoc + attrQLen + attrLen + 1);
                    return parser.text.randomAccessSlice(attrLoc, attrLoc + attrLen);
                    }
                
                if (parser.qvalue.length) 
                    return parser.qvalue ~ ":" ~ parser.value;

                return parser.value;
        }
        
        final Ch[] nodeValue()
        {
                if (parser.type == XmlTokenType.Data)
                    return EntityDecoder!(Ch).decodeBuiltIn (parser.value);
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
}



debug (UnitTest)
{
import tango.io.File;
import tango.io.Stdout;
import tango.util.time.StopWatch;
import tango.util.log.ConsoleAppender;

void testSenderoReader (int iterations, char[] filename = "othello.xml") 
{       
        uint i;
        StopWatch elapsed;
        
        try {
            auto file = new File (filename);
            auto content = cast(char[]) file.read;
            auto parser = new XmlParser!(char) (content);

            elapsed.start;
            for (i=0; i<iterations; i++)
                {
                while (parser.next) {}
                parser.reset;
                }

            Stdout.formatln ("sendero: {} MB/s", (content.length * iterations) / (elapsed.stop * (1024 * 1024)));
            } catch (Object o) 
                    {
                    Stdout.formatln ("On iteration: {}", i);
                    throw o;
                    } 
}

void main() 
{
        //Log.getLogger("sendero.xml").addAppender(new ConsoleAppender);
    
        testSenderoReader (3000, "hamlet.xml");       
}

void testParser(Ch)(XmlParser!(Ch, uint) itr)
{
  /*      assert(itr.next);
        assert(itr.value == "");
        assert(itr.type == XmlTokenType.Declaration, Integer.toUtf8(itr.type));
        assert(itr.next);
        assert(itr.value == "version");
        assert(itr.next);
        assert(itr.value == "1.0");*/
        assert(itr.next);
        assert(itr.value == "element [ <!ELEMENT element (#PCDATA)>]");
        assert(itr.type == XmlTokenType.Doctype);
        assert(itr.next);
        assert(itr.value == "element");
        assert(itr.type == XmlTokenType.StartElement);
        assert(itr.depth == 0);
        assert(itr.next);
        assert(itr.value == "attr");
        assert(itr.next);
        assert(itr.value == "1");
        assert(itr.next);
        assert(itr.type == XmlTokenType.AttrName, Integer.toUtf8(itr.type));
        assert(itr.value == "attr2");
        assert(itr.next);
        assert(itr.value == "two");
        assert(itr.next);
        assert(itr.value == "comment");
        assert(itr.next);
        assert(itr.value == "test&amp;&#x5a;");
//        assert(EntityDecoder!(Ch).decodeBuiltIn(itr.value) == "test&Z");
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
        assert(itr.qvalue == "pi");
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
        
        auto itr = new XmlParser!(Ch)(t);
        
        //testParser!(Ch)(itr);
        while (itr.next)
               Stdout.formatln ("{}", itr.value);
        
        itr.reset;
   /*     auto fitr = new XmlForwardNodeParser!(Ch)(itr);
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
        
        auto itr2 = new XmlParser!(Ch)(t);
        testParser!(Ch)(itr2);*/
}


unittest
{       
        char[] txt = "abcdef";
        Iterator!(char) itr;
        itr.reset(txt);
        assert(!itr.forwardLocate('q'));
        assert(itr.cur == 'a');
        assert(itr.forwardLocate('d'));
        assert(itr.cur == 'd');
    
        doTests!(char)();
        //doTests!(wchar)();
        //doTests!(dchar)();
}


}
