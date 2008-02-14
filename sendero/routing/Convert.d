/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.routing.Convert;

import tango.group.time;

import sendero.routing.Common;
import sendero.conversion.Convert;
import sendero.msg.Msg;

import tango.core.Traits;
import Integer = tango.text.convert.Integer;
import Float = tango.text.convert.Float;

debug import tango.io.Stdout; 

/+interface IConverter(T)
{
	bool convert(Param, inout T);
	char[] getFormatString();
}+/

void fromString(T, Char)(Char[] str, inout T t)
{
	if(str is null) {
		t = T.init;
		return;
	}
	
	static if(is(T == char[]))
	{
		t = str;
	}
	else static if(isIntegerType!(T))
	{
		t = Integer.parse(str);
	}
	else static if(isRealType!(T))
	{
		t = Float.parse(str);
	}
	else static assert(false);
}

template ConvClassParam(char[] n) {
	const char[] ConvClassParam = "static if(val.tupleof.length > " ~ n ~ ") {"
		"pp = val.tupleof[" ~ n ~ "].stringof[4 .. $] in param.obj;"
		"if(pp) {"
			"static if(is(typeof(T.convert!(typeof(val.tupleof[" ~ n ~ "]))))) {"
				"T.convert(*pp, val.tupleof[" ~ n ~ "]);"
			"}"
			"else {"
				"convertParam!(typeof(val.tupleof[" ~ n ~ "]), Req)(val.tupleof[" ~ n ~ "], *pp);"
			"}"
		"}"
	"}";
}

void convertParam(T, Req)(inout T val, Param param)
{
	static if(is(T == char[]))
	{
		if(param.type != ParamT.Value) {
			debug assert(false);
			val = T.init;
		}
		else {
			val = param.val;
		}
	}
	else static if(is(T == bool))
	{
		val = param.type != Param.None ? true : false;  
	}
	else static if(is(typeof(fromString!(T, char))))
	{
		if(param.type != ParamT.Value) {
			debug assert(false);
			val = T.init;
		}
		else {
			debug Stdout("Param ")(val).newline;
			//val = to!(T)(param.val);
			fromString!(T, char)(param.val, val);
		}
	}
/+	else static if(is(typeof(Convert!(T))))
	{
		
	}+/
	else static if(is(T == DateTime) || is(T == Time))
	{
		static assert(false, "Routing system cannot convert type " ~ T.stringof ~ " without specifying a converter.");
	}
	else static if(is(T == class) || is(T == struct))
	{
		if(param.obj.length == 0) {
			val = T.init;
			return;
		}
		
		static if(is(T == class))
			val = new T;
		
		static if(is(typeof(T.convert)))
		{
			auto res = val.convert(param.obj);
			Msg.post(T.stringof, res);
		}
		else
		{
			Param* pp;
			
			/+static if(val.tupleof.length > 0) {
				pp = val.tupleof[0].stringof[4 .. $] in param.obj;
				static if(is(typeof(T.convert!( typeof(val.tupleof[0]) )()) == bool)) {
					T.convert(*pp, val.tupleof[0]);
				}
				else {
					if(pp) convertParam!(typeof(val.tupleof[0]), Req)(val.tupleof[0], *pp);
				}
			};+/
			
			mixin(ConvClassParam!("0"));
			mixin(ConvClassParam!("1"));
			mixin(ConvClassParam!("2"));
			mixin(ConvClassParam!("3"));
			mixin(ConvClassParam!("4"));
			mixin(ConvClassParam!("5"));
			mixin(ConvClassParam!("6"));
			mixin(ConvClassParam!("7"));
			mixin(ConvClassParam!("8"));
			mixin(ConvClassParam!("9"));
			mixin(ConvClassParam!("10"));
			mixin(ConvClassParam!("11"));
			mixin(ConvClassParam!("12"));
			mixin(ConvClassParam!("13"));
			mixin(ConvClassParam!("14"));
			mixin(ConvClassParam!("15"));
		}
	}
	else static if(is(T == char[][]))
	{
		switch(param.type)
		{
		case ParamT.Value:
			val = null;
			val ~= param.val;
			break;
		case ParamT.Array:
			val = param.arr;
			break;
		default:
			val = null;
			break;
		}		
	}
	/+else if(Convert!(T).converter !is null)
	{
		
	}+/
/+	else
	{
		if(param.type != ParamT.Value) {
			debug assert(false);
			val = T.init;
			return;
		}
			
		sendero.util.Convert.fromString(param.val, val);
	}+/
	else static assert(false, "Unhandled conversion type " ~ T.stringof);
	
	return true;
}

template ConvertParam(char[] n) {
	const char[] ConvertParam = "static if(P.length > " ~ n ~ ") {"
		"pParam = paramNames[" ~ n ~ "- offset] in params;"
		"debug Stdout(paramNames[" ~ n ~ "- offset]).newline;"
		"if(pParam) {"
			"static if((is(P[" ~ n ~ "] == class) || is(P[" ~ n ~ "] == struct)) && is(typeof(P[" ~ n ~ "].convert))) {"
					"doClassConvert!(P[" ~ n ~ "])(pParam.obj, p[" ~ n ~ "], paramNames[" ~ n ~ "- offset]);"
				"}"
			"else {"
				"convertParam!(P[" ~ n ~ "], Req)(p[" ~ n ~ "], *pParam);"
			"}"
		"}"
		"else p[" ~ n ~ "] = P[" ~ n ~ "].init;"
	"}";
}

void doClassConvert(T)(Param[char[]] params, inout T t, char[] name)
{
	static if(is(T == class))
		t = new T;
	auto res = t.convert(params);
	if(!res.empty) Msg.post(name, res);
}
	
void convertParams(Req, P...)(Req req, char[][] paramNames, inout P p)
{
	debug Stdout("Start conversion:")(paramNames)(" ")(P.stringof).newline;
	
	auto params = req.params;
	
	Param* pParam;
		
	uint offset = 0;
	
	static if(P.length > 0) {
		static if(is(P[0] == Req))
		{
			offset = 1;
			p[0] = req;
		}
		else
		{
			pParam = paramNames[0] in params;
			if(pParam) {
				static if((is(P[0] == class) || is(P[0] == struct)) && is(typeof(P[0].convert))) {
					doClassConvert!(P[0])(pParam.obj, p[0], paramNames[0]);
				}
				else {
					convertParam!(P[0], Req)(p[0], *pParam);
				}
			}
			else p[0] = P[0].init;
		}
	}
	
	if(paramNames.length < P.length - offset)
		throw new Exception("Incorrect number of parameters: " ~ P.stringof);
	
	/+static if(P.length > 1) {
		pParam = paramNames[1- offset] in params;
		debug Stdout(paramNames[1]).newline;
		if(pParam) {
			convertParam!(P[1], Req)(p[1], *pParam);
		}
		else p[1] = P[1].init;
	};+/
	
	mixin(ConvertParam!("1"));
	mixin(ConvertParam!("2"));
	mixin(ConvertParam!("3"));
	mixin(ConvertParam!("4"));
	mixin(ConvertParam!("5"));
	mixin(ConvertParam!("6"));
	mixin(ConvertParam!("7"));
	mixin(ConvertParam!("8"));
	mixin(ConvertParam!("9"));
	mixin(ConvertParam!("10"));
	mixin(ConvertParam!("11"));
	mixin(ConvertParam!("12"));
	mixin(ConvertParam!("13"));
	mixin(ConvertParam!("14"));
	mixin(ConvertParam!("15"));
}
