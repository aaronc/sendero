/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.routing.FunctionWrapper;

import tango.core.Traits;

import sendero.routing.Common;
import sendero.routing.Convert;

debug(SenderoRouting) {
	import sendero.Debug;
	
	Logger log;
	static this()
	{
		log = Log.lookup("debug.SenderoRouting");
	}
}

class FunctionWrapper2(T, Req, bool InstanceFunc = false) : IFunctionWrapper!(ReturnTypeOf!(T), Req)
{
	alias ParameterTupleOf!(T) P;
	alias ReturnTypeOf!(T) Ret;
	
	alias Ret function(P) FnT;
	alias Ret delegate(P) DgT;
	
	this(FnT fn, char[][] paramNames)
	{
		this.fn = fn;
		this.dg.funcptr = fn;
		this.paramNames = paramNames;
	}
	
	private FnT fn;
	private DgT dg;
	private char[][] paramNames;
	
	Ret exec(Req routeParams, void* ptr)
	{
		debug(SenderoRouting) {
			mixin(FailTrace!(typeof(this).stringof ~ ".exec"));
			log.trace(MName ~ " paramNames: {}", paramNames);
		}
		
		debug assert(routeParams);
		
		P p;
		
		convertParams!(Req, P)(routeParams, paramNames, p);
		
		static if(InstanceFunc) {
			dg.ptr = ptr;
			return dg(p);
		}
		else {
			return fn(p);
		}
	}
}

debug(SenderoUnittest)
{

import Integer = tango.text.convert.Integer;
	
struct Address
{
	char[] address;
	char[] city;
	char[] state;
}

char[] test(char[] x, int y, Address address)
{
	char[] res = x ~ Integer.toString(y) ~ "\n";
	res ~= address.address ~ "\n";
	res ~= address.city ~ "\n";
	res ~= address.state;
	
	return res;
}

char[] test2(char[] x, int y)
{
	char[] res = x ~ Integer.toString(y) ~ "\n";
	
	return res;
}

unittest
{
	char[] res;
	
	auto fn = new FunctionWrapper!(typeof(&test), Request)(&test, ["x", "y", "address"]);
	auto routeParams = new Request;
	routeParams.parse(HttpMethod.Get, "/", "x=Hello&y=1&address.address=1+First+St.&address.city=Somewhere&address.state=NY");
	res = fn.exec(routeParams, null);
	assert(res == "Hello1\n1 First St.\nSomewhere\nNY", res);
	
	auto fn2 = new FunctionWrapper!(typeof(&test2), Request)(&test2, ["x", "y"]);
	res = fn2.exec(routeParams, null);
	assert(res == "Hello1\n", res);
}

}