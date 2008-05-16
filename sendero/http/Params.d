/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.http.Params;

import tango.net.Uri;
import tango.text.Util;

enum ParamT : ubyte { None, Value, Array };
struct Param
{
	ParamT type = ParamT.None;
	union
	{
		char[] val;
		char[][] arr;
	}
	Param[char[]] obj;
}

void addParam(inout Param[char[]] params, char[][] key, char[] val, uint index = 0)
{
	if(index >= key.length) {
		debug assert(false);
		return;
	}
	
	auto pVal = key[index] in params;
	if(pVal) {			
		if(index + 1 < key.length) {
			addParam(pVal.obj, key, val, index + 1);
		}
		else {
			switch(pVal.type)
			{
			case ParamT.Array:
				pVal.arr ~= val;
				break;
			case ParamT.Value:
				auto x = pVal.val;
				pVal.type = ParamT.Array;
				pVal.arr.length = 2;
				pVal.arr[0] = x.dup;
				pVal.arr[1] = val;
				break;
			case ParamT.None:
			default:
				pVal.type = ParamT.Value;
				pVal.val = val;
			}
		}
	}
	else {
		if(index + 1 < key.length) {
			Param x;
			params[key[index]] = x;
			addParam(params[key[index]].obj, key, val, index + 1);
		}
		else {
			Param x;
			x.type = ParamT.Value;
			x.val = val;
			params[key[index]] = x;
		}
	}
}

/*
 * Parses a set of HTTP GET or POST parameters ("name=bob&text=hello+world") into an associative array.
 */
Param[char[]] parseParams(char[] str)
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
	
	Param[char[]] resParams;
	
	auto uri = new Uri;
	foreach(pair; patterns(str, "&"))
	{
		uint pos = locate(pair,'=');
		char[] rawKey = uri.decode(pair[0 .. pos]);
		char[][] key = split(rawKey, ".");
		char[] val;
		
		if(pos >= pair.length) {
			val = "";
		}
		else {
			auto rawVal = pair[ pos+1 .. $ ];
			plusToSpace(rawVal);
			val = uri.decode(rawVal);
		}
		
		addParam(resParams, key, val);
	}
	return resParams;
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

version(Unittest)
{

import tango.io.Stdout;
	
unittest
{
	auto get = parseParams("a=3&bqz=sgjkh+sgkjh&name=bob&text=hello+world&name.nickname=rob&a=5&obj.x=10&obj.str=name&fruit=apple&fruit=orange&fruit=pineapple");
	assert(get.length == 6);
	assert(get["a"].arr[0] == "3");
	assert(get["a"].arr[1] == "5");
	assert(get["bqz"].val == "sgjkh sgkjh");
	assert(get["name"].val == "bob", get["name"].val);
	assert(get["name"].obj["nickname"].val == "rob", get["name"].obj["nickname"].val);
	assert(get["text"].val == "hello world");
	assert(get["obj"].obj["x"].val == "10");
	assert(get["obj"].obj["str"].val == "name");
	assert(get["fruit"].arr[0] == "apple");
	assert(get["fruit"].arr[1] == "orange");
	assert(get["fruit"].arr[2] == "pineapple");
	
	auto cookies = parseCookies("sg=23shjgt; sgkjg=aby839");
	assert(cookies["sg"] == "23shjgt");
	assert(cookies["sgkjg"] == "aby839");
}

}