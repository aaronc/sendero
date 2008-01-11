module sendero.routing.TypeSafeRouter;

public import sendero.routing.Common;
import sendero.routing.TypeSafeHttpFunctionWrapper;

const ubyte GET = 0;
const ubyte POST = 1;
const ubyte ALL = 2;

template TypeSafeRouterDef(Ret, Req)
{
	alias IFunctionWrapper!(Ret, Req) Routing;
	
	private struct Routes
	{
		void setRoute(char[] route, Routing routing)
		{
			if(route == "*") starRoute = routing;
			else if(!route.length) defRoute = routing;
			else routes[route] = routing;
		}
		
		Routing[char[]] routes;
		Routing starRoute = null;
		Routing defRoute = null;
	}
	
	Routes getRoutes;
	Routes postRoutes;
	
	static TypeSafeRouter!(Ret, Req) opCall()
	{
		TypeSafeRouter!(Ret, Req) router;
		return router;
	}
	
	void map(T)(ubyte method, char[] route, T t, char[][] paramNames)
	{
		Routing routing;
		routing = new FunctionWrapper!(T, Req)(t, paramNames);
		
		switch(method)
		{
		case GET:
			getRoutes.setRoute(route, routing);
			break;
		case POST:
			postRoutes.setRoute(route, routing);
			break;
		case ALL:
			getRoutes.setRoute(route, routing);
			postRoutes.setRoute(route, routing);
			break;
		default: assert(false, "Unknown routing method");
		}
	}
	
	Ret route(Req routeParams)
	{
		debug assert(routeParams);
		debug assert(routeParams.url);
		auto token = routeParams.url.top;
		
		Routes* pRoutes;
		switch(routeParams.method)
		{
		case HttpMethod.Get: pRoutes = &getRoutes; break;
		case HttpMethod.Post: pRoutes = &postRoutes; break;
		default: assert(false, "Unknown routing method");
		}
		
		if(!token) {
			if(!pRoutes.defRoute) {
				debug assert(false);
				throw new Exception("Default route access violation");
			}
			
			return pRoutes.defRoute.exec(routeParams);
		}
		
		routeParams.url.pop;
		
		auto routing = token in pRoutes.routes;
		if(!routing) {
			if(!pRoutes.starRoute) {
				debug assert(false);
				throw new Exception("Star route access violation: " ~ token);
			}
			
			routeParams.lastToken = token;
			
			return pRoutes.starRoute.exec(routeParams);
		}
		
		return routing.exec(routeParams);
	}
}

struct TypeSafeRouter(Ret, Req)
{
	mixin TypeSafeRouterDef!(Ret, Req);
}

version(Unittest)
{

import sendero.routing.Request;


alias TypeSafeRouter!(char[], Request) Router;
	
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