module sendero.routing.TypeSafeHttpFunctionWrapper;


import tango.core.Traits;

import sendero.util.Convert;
import sendero.routing.Common;

interface IFunctionWrapper(Ret)
{
	Ret exec(Request);
}

template ConvClassParam(char[] n) {
	const char[] ConvClassParam = "static if(val.tupleof.length > " ~ n ~ ") {"
		"pp = val.tupleof[" ~ n ~ "].stringof[4 .. $] in param.obj;"
		"if(pp) convertParam(val.tupleof[" ~ n ~ "], *pp);"
	"}";
}

void convertParam(T)(inout T val, Param param)
{
	static if(is(T == class) || is(T == struct))
	{
		if(param.obj.length == 0) {
			val = T.init;
			return;
		}
		
		static if(is(T == class))
			val = new T;
		
		
		Param* pp;
		
		/*static if(val.tupleof.length > 1) {
			pp = val.tupleof[1].stringof[4 .. $] in param.obj;
			if(pp) convertParam(val.tupleof[1], *pp);
		};*/
		
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
	else static if(is(T == bool))
	{
		val = param.type != Param.None ? true : false;  
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
	else
	{
		if(param.type != ParamT.Value) {
			debug assert(false);
			val = T.init;
			return;
		}
			
		fromString(param.val, val);
	}
}

template ConvertParam(char[] n) {
	const char[] ConvertParam = "static if(P.length > " ~ n ~ ") {"
		"pParam = paramNames[" ~ n ~ "] in params;"
		"if(pParam) {"
			"convertParam(p[" ~ n ~ "], *pParam);"
		"}"
		"else p[" ~ n ~ "] = P[" ~ n ~ "].init;"
	"}";
}

class FunctionWrapper(T) : IFunctionWrapper!(ReturnTypeOf!(T))
{
	alias ParameterTupleOf!(T) P;
	alias ReturnTypeOf!(T) Ret;
	
	alias Ret function(P) FnT;
	
	this(FnT fn, char[][] paramNames)
	{
		this.fn = fn;
		this.paramNames = paramNames;
	}
	
	private FnT fn;	
	private char[][] paramNames;
	
	Ret exec(Request routeParams)
	{
		debug assert(routeParams);
		auto params = routeParams.params;
		
		if(paramNames.length != P.length)
			throw new Exception("Incorrect number of parameters");
		
		P p;
		Param* pParam;
		
		
		static if(P.length > 0) {
			static if(is(P[0] == Request)) {
				p[0] = routeParams;
			}
			else {
				pParam = paramNames[0] in params;
				if(pParam) {
					convertParam(p[0], *pParam);
				}
				else p[0] = P[0].init;
			}
		}
		
		
		//mixin(ConvertParam!("0"));
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
		
		return fn(p);
	}
}

version(Unittest)
{

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

unittest
{
	auto fn = new FunctionWrapper!(typeof(&test))(&test, ["x", "y", "address"]);
	auto routeParams = Request.parse(HttpMethod.Get, "/", "x=Hello&y=1&address.address=1+First+St.&address.city=Somewhere&address.state=NY");
	auto res = fn.exec(routeParams);
	assert(res == "Hello1\n1 First St.\nSomewhere\nNY", res);
}

}