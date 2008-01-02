module sendero.routing.TypeSafeRouter;

import sendero.routing.TypeSafeHttpFunctionWrapper;

public import sendero.routing.Common;

const ubyte GET = 0;
const ubyte POST = 1;
const ubyte ALL = 2;

//alias Ret delegate(UrlStack url) RoutingFunc(Ret);
//alias Ret delegate(char[] param, UrlStack url) ParamRoutingFunc(Ret);

/*class RoutingFunctionWrapper(Ret) : IFunctionWrapper!(Ret)
{
	this()
	{
		
	}
	
	Ret exec(Param[char[]] params)
	{
		
	}
}

class ParamRoutingFunctionWrapper(Ret) : IFunctionWrapper!(Ret)
{
	this()
	{
		
	}
	
	Ret exec(Param[char[]] params)
	{
		
	}
}*/

struct TypeSafeRouter(Ret)
{
	private struct Routing
	{
		IFunctionWrapper!(Ret) fn;
		ubyte allowedMethod;
	}
	
	private Routing[char[]] routes;
	private Routing starRoute;
	private Routing defRoute;
	
	static TypeSafeRouter!(Ret) opCall()
	{
		TypeSafeRouter!(Ret) router;
		return router;
	}
	
	void map(T)(ubyte method, char[] route, T t, char[][] paramNames)
	{
		Routing routing;
		routing.fn = new FunctionWrapper!(T)(t, paramNames);
		routing.allowedMethod = method;
		if(route == "*") starRoute = routing;
		else if(!route.length) defRoute = routing;
		else routes[route] = routing;
	}
	
	private bool authorize(ubyte allowedMethod, HttpMethod method)
	{
		if(method == HttpMethod.Get) {
			return allowedMethod == GET || allowedMethod == ALL; 
		}
		else if(method == HttpMethod.Post) {
			return allowedMethod == POST || allowedMethod == ALL;
		}
	}
	
	Ret route(Request routeParams)
	{
		debug assert(routeParams);
		debug assert(routeParams.url);
		auto token = routeParams.url.top;
		
		if(!token) {
			if(!defRoute.fn || !authorize(defRoute.allowedMethod, routeParams.method)) {
				debug assert(false);
				throw new Exception("Default route access violation");
			}
			
			return defRoute.fn.exec(routeParams);
		}
		
		routeParams.url.pop;
		
		auto routing = token in routes;
		if(!routing) {
			if(!starRoute.fn || !authorize(starRoute.allowedMethod, routeParams.method)) {
				debug assert(false);
				throw new Exception("Star route access violation");
			}
			
			routeParams.lastToken = token;
			
			return starRoute.fn.exec(routeParams);
		}
		
		if(!authorize(routing.allowedMethod, routeParams.method)) {
			debug assert(false);
			throw new Exception("Mapped route access violation");
		}
		return routing.fn.exec(routeParams);
	}
}

version(Unittest)
{

alias TypeSafeRouter!(char[]) Router;
	
class Ctlr
{
	static this()
	{
		r = Router();
		r.map!(typeof(&Ctlr.main))(ALL, "main", &main, ["param"]);
	}
	
	static const Router r;
	
	static char[] route(Request routeParams)
	{
		return r.route(routeParams);
	}
	
	static char[] main(char[] param)
	{
		return param;
	}
	
}
	
unittest
{
	auto rParams = Request.parse(HttpMethod.Get, "/main", "param=test");
	assert(Ctlr.route(rParams) == "test");
}

}