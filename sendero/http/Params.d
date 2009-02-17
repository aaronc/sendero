/**
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.http.Params;

import tango.net.Uri;
import tango.text.Util;
public import sendero_base.Core;
public import sendero_base.Set;
import sendero.vm.Object, sendero.vm.Array;

private Uri uri;
static this()
{
	uri = new Uri;
}

void addParam(IObject params, char[][] key, char[] val, uint index = 0)
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
			set(pVal, newObj);
			params[key[index]] = pVal;
		}
		addParam(pVal.obj_, key, val, index + 1);
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
			set(pVal, arr);
			params[key[index]] = pVal;
			break;
		}
	}
}
/*
 * Parses a set of HTTP GET or POST parameters ("name=bob&text=hello+world") into an associative array.
 */
IObject parseParams(char[] str, IObject existingObj = null)
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
	
	IObject resParams = existingObj;
	if(resParams is null) resParams = new Obj;
	
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

debug(SenderoUnittest)
{

import tango.io.Stdout;
	
unittest
{
	Var v;
	auto get2 = parseParams("a=3&bqz=sgjkh+sgkjh&name=bob&text=hello+world&name.nickname=rob&a=5&obj.x=10&obj.str=name&fruit=apple&fruit=orange&fruit=pineapple");
	
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
}

}