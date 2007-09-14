/** 
 * Copyright: Copyright (C) 2007 Aaron Craelius.  All rights reserved.
 * License:   BSD Style
 * Authors:   Aaron Craelius
 */


module sendero.util.HTTPRequest;

import tango.net.Uri;
import tango.text.Util;

/*
 * Parses a set of HTTP GET or POST parameters ("name=bob&text=hello+world") into an associative array.
 */
char[][char[]] parseParams(char[] str)
{
	void plusToSpace(inout char[] val)
	{
		foreach(ref char c; val)
		{
			if(c == '+') {
				c = ' ';
			}
		}
	}
	
	auto uri = new Uri;
	char[][char[]] params;
	foreach(pair; patterns(str, "&"))
	{
		uint pos = locate(pair,'=');
		auto key = uri.decode(pair[0 .. pos]);
		
		if(pos >= pair.length)
			params[ key ] = "";
		else {
			auto val = pair[ pos+1 .. $ ];
			plusToSpace(val);
			params[ key ] = uri.decode(val);
		}
	}
	return params;
}

/**
 * Parses a set of cookies sent by the client to the server into an associative array.
 */
char[][char[]] parseCookies(char[] str)
{
	char[][char[]] params;
	foreach(pair; patterns(str, "; "))
	{
		uint pos = locate(pair,'=');
		if(pos >= pair.length)
			params[ pair[ 0 .. pos] ] = "";
		else
			params[ pair[ 0 .. pos] ] = pair[ pos+1 .. $ ];
	}
	return params;
}

unittest
{
	auto get = parseParams("a=3&bqz=sgjkh+sgkjh&name=bob&text=hello+world");
	assert(get["a"] == "3");
	assert(get["bqz"] == "sgjkh sgkjh");
	assert(get["name"] == "bob");
	assert(get["text"] == "hello world");
	
	auto cookies = parseCookies("sg=23shjgt; sgkjg=aby839");
	assert(cookies["sg"] == "23shjgt");
	assert(cookies["sgkjg"] == "aby839");
}
