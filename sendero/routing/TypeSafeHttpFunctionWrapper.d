module sendero.routing.TypeSafeHttpFunctionWrapper;

import tango.core.Traits;

import sendero.routing.Common;
import sendero.routing.Convert;

class FunctionWrapper(T, Req, bool dg = false) : IFunctionWrapper!(ReturnTypeOf!(T), Req)
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
		debug assert(routeParams);
		
		P p;
		
		convertParams!(Req, P)(routeParams, paramNames, p);
		
		if(ptr !is null) {
			dg.ptr = ptr;
			return dg(p);
		}
		else {
			return fn(p);
		}
	}
}

version(Unittest)
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

unittest
{
	auto fn = new FunctionWrapper!(typeof(&test), Request)(&test, ["x", "y", "address"]);
	auto routeParams = new Request;
	routeParams.parse(HttpMethod.Get, "/", "x=Hello&y=1&address.address=1+First+St.&address.city=Somewhere&address.state=NY");
	auto res = fn.exec(routeParams, null);
	assert(res == "Hello1\n1 First St.\nSomewhere\nNY", res);
}

}