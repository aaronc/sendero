
/** 
 * Copyright: Copyright (C) 2007 Aaron Craelius and Kris Bell.  All rights reserved.
 * License:   BSD Style
 * Authors:   Aaron Craelius and Kris Bell
 */

module sendero.xml.XmlParser;

public import sendero.xml.XmlEntities;
import sendero.util.StringCharIterator;
import sendero.util.ArrayWriter;
import sendero.xml.XmlCharIterator;

enum XmlTokenType {StartElement, Attribute, EndElement, EndEmptyElement, Data, Comment, CData, Doctype, PI, None};

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
    ushort depth();
    bool error();
    //char[] errorMsg();
}

import tango.util.log.Log;
import Util = tango.text.Util;


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
class XmlParser(Ch = char)
{
        private static Logger log;

        private XmlCharIterator!(Ch)   text;
        private bool            err = false;
        Ch[]            prefix;    
        Ch[]            localName;     
        Ch[]            rawValue;
        int             depth = 0;
        XmlTokenType    type = XmlTokenType.None;static this()
        {
                log = Log.getLogger("sendero.xml.XmlParser!(" ~ Ch.stringof ~ ")");
        }
        
       /* static XmlParser!(Ch) opCall(Ch[] content)
        {
        	XmlParser!(Ch) itr;
            itr.reset (content);
            return itr;
        }*/
        
        this(Ch[] content)
        {
        	reset(content);}
        
        private bool doAttributeName()
        {
            auto p = text.point;
            auto q = text.eatAttrName (p);

            if (*q == ':')
            {
                prefix = p[0 .. q - p];
                q = text.eatAttrName (p = q + 1);
                localName = p[0 .. q - p];}
            else 
            {
				prefix = null;
                localName = p[0 .. q - p];}
            type = XmlTokenType.Attribute;if (*q <= 32) 
            {
            do {
	        	if (++q >= text.end)                                      
	        		return doEndOfStream();
	        	} while (*q <= 32);
        	}
            
			if (*q is '=')
				doAttributeValue (q + 1);
			return true;
        }

        private bool doEndEmptyElement()
        {
            if(text[0..2] != "/>")
                return doUnexpected("/>");
 
            type = XmlTokenType.EndEmptyElement;
            localName = prefix = null;text.point += 2;
            return true;
        }
        
        private bool doComment()
        {
            auto p = text.point;
            //type = XmlTokenType.Comment;
                
            while (text.good)
            {
                if (! text.forwardLocate('-')) 
                    return doUnexpectedEOF();

                if (text[0..3] == "-->") 
                {
                    rawValue = p [0 .. text.point - p];
					type = XmlTokenType.Comment;
                    //prefix = null;text.point += 3;
                    return true;
                }
                ++text.point;
            }
            return doUnexpectedEOF();
        }
        
        private bool doCData()
        {
            auto p = text.point;
            //type = XmlTokenType.CData;
                
            while (text.good)
            {
                if (! text.forwardLocate(']')) 
                    return doUnexpectedEOF();
                
                if (text[0..3] == "]]>") 
                {
					type = XmlTokenType.CData;
                    rawValue = p [0 .. text.point - p];
                    //prefix = null;text.point += 3;                      
                    return true;
                }
                ++text.point;
            }
            return doUnexpectedEOF();
        }

        
        private bool doPI()
        {
            //type = XmlTokenType.PI;
            auto p = text.point;
            text.eatElemName;
            ++text.point;
            while (text.good)
            {
                if (! text.forwardLocate('\?')) 
                    return doUnexpectedEOF();

                if (text.point[1] == '>') 
                {
					type = XmlTokenType.PI;
                    rawValue = p [0 .. text.point - p];text.point += 2;
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
                //type = XmlTokenType.Doctype;
                                
                while (text.good) 
                      {
                      if (*text.point == '>') 
                         {
						 type = XmlTokenType.Doctype;
                         rawValue = p [0 .. text.point - p];prefix = null;
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
                log.warn("Unexpected event " ~ msg ~ " " ~ Integer.toUtf8(type));
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
                         type = XmlTokenType.Data;
                         rawValue = q [0 .. p - q];
                         text.point = p;
                         return true;
                         }
                      } while (p < e);
                   return doUnexpectedEOF();
                   }

                switch (p[1])
                       {
                       case '/':
                            p += 2;
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
                               prefix = null;
                               localName = p[0 .. q - p];
                               }
                            else 
                               {
                               prefix = p[0 .. q - p];
                               p = ++text.point;
                               q = text.eatAttrName;
                               localName = p[0 .. q - p];
                               }
                            type = XmlTokenType.EndElement;
                
                            while (*q <= 32 && q <= text.end)
                                   ++q;

                            if (*q == '>')
                               {
                               text.point = q + 1;
                               --depth;
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
                            auto q = ++p;
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
                               prefix = null;
                               localName = p [0 .. q - p];
                               }
                            else
                               {
                               prefix = p [0 .. q - p];
                               p = ++text.point;
                               q = text.eatAttrName;
                               localName = p [0 .. q - p];
                               }
                            type = XmlTokenType.StartElement;
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
                
                if (type >= XmlTokenType.EndElement) 
                    return doMain;

                // in element
                switch (*p)
                       {
                       case '/':
                            return doEndEmptyElement();

                       case '>':
                            ++depth;
                            ++text.point;
                            return doMain();

                       default:
                            break;
                       }
                return doAttributeName();
        }
 
        private void doAttributeValue(Ch* q){
            auto p = text.eatSpace (q);
            auto quote = *p++;
            switch (quote)
            {
    			case '"':
    			case '\'':
    				q = text.forwardLocate(p, quote);	
    				rawValue = p[0 .. q - p];
    				text.point = q + 1; //Skip end quotebreak;

    			default: 
    				doUnexpected("\' or \"");
        	}
        }
        
        final Ch[] value()
        {
        	if(type == XmlTokenType.Attribute || type == XmlTokenType.Data)
        		return decodeBuiltinEntities!(Ch)(rawValue);
        	return rawValue;
        }
        
        final Ch[] name()
        {
        	if(prefix.length)
        		return prefix ~ ":" ~ localName;
        	return localName;
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
                depth = 0;
                type = XmlTokenType.None;static if(Ch.sizeof == 1)
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
}version (Unittest)
{
import tango.io.File;
import tango.io.Stdout;
import tango.util.time.StopWatch;
import tango.util.log.ConsoleAppender;

void benchmarkSenderoReader (int iterations, char[] filename = "othello.xml") 
{       
        uint i;
        StopWatch elapsed;
        
        try {
            auto file = new File ("../senderoRelease/" ~ filename);
            auto content = cast(char[]) file.read;
            auto parser = new XmlParser!(char) (content);
            //XmlParser!(char) parser;
            parser.reset(content);

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

/*void main() 
{
        //Log.getLogger("sendero.xml").addAppender(new ConsoleAppender);
    
        for (int i = 5; --i;)
             testSenderoReader (1000, "hamlet.xml");       
}*/

void testParser(Ch)(XmlParser!(Ch) itr)
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
        assert(itr.localName == "element");
        assert(itr.type == XmlTokenType.StartElement);
        assert(itr.depth == 0);
        assert(itr.next);
        assert(itr.localName == "attr");
        assert(itr.value == "1");
        assert(itr.next);
        assert(itr.type == XmlTokenType.Attribute, Integer.toUtf8(itr.type));
        assert(itr.localName == "attr2");
        assert(itr.value == "two");
        assert(itr.next);
        assert(itr.value == "comment");
        assert(itr.next);
        assert(itr.rawValue == "test&amp;&#x5a;");
        assert(itr.value == "test&Z", itr.value);
        assert(itr.next);
        assert(itr.prefix == "qual");
        assert(itr.localName == "elem");
        assert(itr.next);
        assert(itr.type == XmlTokenType.EndEmptyElement);
        assert(itr.next);
        assert(itr.localName == "el2");
        assert(itr.depth == 1);
        assert(itr.next);
        assert(itr.localName == "attr3");
        assert(itr.value == "3three", itr.value);
        assert(itr.next);
        assert(itr.rawValue == "sdlgjsh");
        assert(itr.next);
        assert(itr.localName == "el3");
        assert(itr.depth == 2);
        assert(itr.next);
        assert(itr.type == XmlTokenType.EndEmptyElement);
        assert(itr.next);
        assert(itr.value == "data");
        assert(itr.next);
      //  assert(itr.qvalue == "pi", itr.qvalue);
      //  assert(itr.value == "test");
        assert(itr.rawValue == "pi test");
        assert(itr.next);
        assert(itr.localName == "el2");
        assert(itr.next);
        assert(itr.localName == "element");
        assert(!itr.next);
}

static const char[] testXML = "<?xml version=\"1.0\" ?><!DOCTYPE element [ <!ELEMENT element (#PCDATA)>]><element "
    "attr=\"1\" attr2=\"two\"><!--comment-->test&amp;&#x5a;<qual:elem /><el2 attr3 = "
    "'3three'><![CDATA[sdlgjsh]]><el3 />data<?pi test?></el2></element>";

void doTests(Ch)()
{
        
        auto itr = new XmlParser!(Ch)(testXML);
//		XmlParser!(Ch) itr;
//		itr.reset(testXML);
        
        testParser!(Ch)(itr);
}


unittest
{       
        char[] txt = "abcdef";
        XmlCharIterator!(char) itr;
        itr.reset(txt);
    
        doTests!(char)();
        //doTests!(wchar)();
        //doTests!(dchar)();
        
        for (int i = 5; --i;)
            benchmarkSenderoReader (1000, "hamlet.xml");
}


}