/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.xml.XmlEntities;

import sendero_base.util.Unicode;
import sendero_base.util.StringCharIterator;
import sendero_base.util.ArrayWriter;

import Integer = tango.text.convert.Integer;
import Unicode = tango.text.convert.Utf;

Ch[] decodeBuiltinEntities(Ch)(Ch[] str)
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
                                        res ~= fromDecimalToCh!(Ch)(x);
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
                                        res ~= fromDecimalToCh!(Ch)(x);
                                }
                                break;
                        case 'a':
                                if(i[0 .. 4] == "amp;") {
                                        i += 4;
                                        res ~= "&";
                                }
                                else if(i[0 .. 5] == "apos;") {
                                        i += 5;
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

Ch[] encodeBuiltinEntities(Ch, bool encodeQuotes = true)(Ch[] str)
{
	auto res = new ArrayWriter!(Ch);
	foreach(ch; str)
	{
		switch(ch)
		{
		case '&': res ~= "&amp;"; break;
		case '<': res ~= "&lt;"; break;
		case '>': res ~= "&gt;"; break;
		static if(encodeQuotes)
		{
		case '\'': res ~= "&apos;"; break;
		case '\"': res ~= "&quot;"; break;
		}
		default: res ~= ch; break;
		}
	}
	return res.get;
}