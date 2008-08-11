/**
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.http.Params;

import tango.net.Uri;
import tango.text.Util;
public import sendero_base.Core;
import sendero.vm.Object, sendero.vm.Array;

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

void addParam2(IObject params, char[][] key, char[] val, uint index = 0)
{
	if(index >= key.length) {
		debug assert(false);
		return;
	}
	
	auto pVal = params[key[index]];
	if(index + 1 < key.length) {
		if(pVal.type != VarT.Object) {
			auto newObj = new Obj;
			if(pVal.type != VarT.Null)
				newObj[""] = pVal;
			pVal.type = VarT.Object;
			pVal.obj_ = newObj;
			params[key[index]] = pVal;
		}
		addParam2(pVal.obj_, key, val, index + 1);
	}
	else {
		Var newVal;
		newVal.type = VarT.String;
		newVal.string_ = val;
		switch(pVal.type)
		{
		case VarT.Array:
			pVal.array_ ~= newVal;
			break;
		case VarT.Object:
			pVal.obj_[""] = newVal;
			break;
		case VarT.Null:
			params[key[index]] = newVal;
			break;
		default:
			auto arr = new Array;
			arr ~= pVal;
			arr ~= newVal;
			pVal.type = VarT.Array;
			pVal.array_ = arr;
			params[key[index]] = pVal;
			break;
		}
	}
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

IObject parseParams2(char[] str)
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
	
	auto resParams = new Obj;
	
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
		
		addParam2(resParams, key, val);
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

debug(SenderoUnittest)
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
	
	Var v;
	auto get2 = parseParams2("a=3&bqz=sgjkh+sgkjh&name=bob&text=hello+world&name.nickname=rob&a=5&obj.x=10&obj.str=name&fruit=apple&fruit=orange&fruit=pineapple");
	
	assert(get2["a"].type == VarT.Array);
	v = get2["a"].array_[0];
	assert(v.type == VarT.String && v.string_ == "3");
	v = get2["a"].array_[1];
	assert(v.type == VarT.String && v.string_ == "5");
	
	assert(get2["bqz"].type == VarT.String && get2["bqz"].string_ == "sgjkh sgkjh");
	
	assert(get2["name"].type == VarT.Object);
	v = get2["name"].obj_[""];
	assert(v.type == VarT.String && v.string_ == "bob");
	v = get2["name"].obj_["nickname"];
	assert(v.type == VarT.String && v.string_ == "rob");
	
	assert(get2["obj"].type == VarT.Object);
	v = get2["obj"].obj_["x"];
	assert(v.type == VarT.String && v.string_ == "10");
	v = get2["obj"].obj_["str"];
	assert(v.type == VarT.String && v.string_ == "name");
	
	assert(get2["fruit"].type == VarT.Array);
	v = get2["fruit"].array_[0];
	assert(v.type == VarT.String && v.string_ == "apple");
	v = get2["fruit"].array_[1];
	assert(v.type == VarT.String && v.string_ == "orange");
	v = get2["fruit"].array_[2];
	assert(v.type == VarT.String && v.string_ == "pineapple");
	
	auto cookies = parseCookies("sg=23shjgt; sgkjg=aby839");
	assert(cookies["sg"] == "23shjgt");
	assert(cookies["sgkjg"] == "aby839");
}

}