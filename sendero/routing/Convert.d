/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.routing.Convert;

import tango.time.Time;
import tango.time.Clock;
import tango.time.ISO8601;

import sendero.routing.Common;
import sendero.conversion.Convert;
import sendero.msg.Msg;

import tango.core.Traits;
import Integer = tango.text.convert.Integer;
import Float = tango.text.convert.Float;

debug import tango.io.Stdout; 

debug(SenderoRouting) {
	import sendero.Debug;
	
	Logger log;
	static this()
	{
		log = Log.lookup("debug.SenderoRouting");
	}
}

T convertParam2(T, Req)(Var param, Req req)
{
	T val;
	static if(is(T == char[]))
	{
		switch(param.type)
		{
		case VarT.String: val = param.string_; break;
		case VarT.Number: val = Float.toString(param.number_); break;
		case VarT.Bool: if(param.bool_) val = "true"; else val = "false"; break;
		default: val = T.init; break;
		}
	}
	else static if(is(T == void[]) || is(T == ubyte[]))
	{
		switch(param.type)
		{
		case VarT.String: val = cast(T)param.string_; break;
		case VarT.Void: val = *cast(T*)param.void_; break;
		default: val = T.init; break;
		}
	}
	else static if(is(T == bool))
	{
		switch(param.type)
		{
		case VarT.String:
			switch(param.string_)
			{
			case "true":
			case "True":
			case "1":
				val = true; break;
			default:
				val = false; break;
			}
			break;
		case VarT.Number: val = param.number_ > 0 ? true : false;
		case VarT.Bool: val = param.bool_; break;
		case VarT.Array: val = param.array_.length > 0 ? true : false; break;
		case VarT.Object: val = true; break;
		default: val = false; break;
		}  
	}
	else static if(isIntegerType!(T))
	{
		switch(param.type)
		{
		case VarT.String: val = Integer.parse(param.string_); break;
		case VarT.Number: val = cast(T)param.number_; break;
		case VarT.Bool: if(param.bool_) val = 1; else val = 0; break;
		default: val = T.init; break;
		}
	}
	else static if(isRealType!(T))
	{
		switch(param.type)
		{
		case VarT.String: val = Float.parse(param.string_); break;
		case VarT.Number: val = cast(T)param.number_; break;
		case VarT.Bool: if(param.bool_) val = 1; else val = 0; break;
		default: val = T.init; break;
		}
	}
	else static if(is(typeof(val.convert)))
	{
		val.convert(param);
	}
	else static if(is(T : IHttpSet))
	{
		if(param.type == VarT.Object) {
			val.httpSet(param.obj_, req);
		}
	}
	else static if(is(T == IObject))
	{
		if(param.type == VarT.Object) val = param.obj_;
		else val = null;
	}
	else static if(is(T == char[][]))
	{
		char[] str;
		switch(param.type)
		{
		case VarT.Array:
			val = new char[][param.array_.length];
			val.length = 0;
			foreach(v; param.array_)
			{
				val ~= convertParam2!(char[], Req)(v, req);
			}
			break;
		case VarT.String:
			val = [param.string_];
			break;
		default:
			val = null;
			break;
		}		
	}
	else static if(is(T == Time))
	{
		switch(param.type)
		{
		case VarT.String:
			parseDateAndTime(param.string_, val);
			break;
		default: val = T.init; break;
		}
	}
	else static if(is(T == DateTime))
	{
		switch(param.type)
		{
		case VarT.String:
			Time time;
			parseDateAndTime(param.string_, time);
			val = Clock.toDate;
			break;
		default: val = T.init; break;
		}
	}
	else static if(is(T == Date))
	{
		switch(param.type)
		{
		case VarT.String:
			Time time;
			parseDate(param.string_, time);
			val = Clock.toDate.date;
			break;
		default: val = T.init; break;
		}
	}
	else static if(is(T == TimeOfDay))
	{
		switch(param.type)
		{
		case VarT.String:
			Time time;
			parseDate(param.string_, time);
			val = Clock.toDate.time;
			break;
		default: val = T.init; break;
		}
	}
	else static assert(false, "Unhandled conversion type " ~ T.stringof);
	
	return val;
}

void doClassConvert(T)(Param[char[]] params, inout T t, char[] name)
{
	static if(is(T == class))
		t = new T;
	auto res = t.convert(params);
	if(!res.empty) Msg.post(name, res);
}

void convertParams2(Req, ParamT...)(Req req, char[][] paramNames, inout ParamT p)
{
	debug(SenderoRouting) {
		mixin(FailTrace!("convertParams2"));
	}
	
	debug Stdout("Start conversion:")(paramNames)(" ")(ParamT.stringof).newline;
	
	auto params = req.params2;
	
	foreach(Index, Type; ParamT)
	{
		static if(is(Type == Req))
			p[Index] = req;
		else {
			if(Index < paramNames.length) {
				auto param = params[paramNames[Index]];
				p[Index] = convertParam2!(Type, Req)(param, req);
			}
		}
	}
}