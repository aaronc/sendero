module sendero.routing.TypeSafeRouter;

public import sendero.routing.Common;
import sendero.routing.TypeSafeHttpFunctionWrapper;

const ubyte GET = 0;
const ubyte POST = 1;
const ubyte ALL = 2;

template Route(Ret, Req, bool UseDelegates = false)
{
	Ret route(Req routeParams, void* ptr = null)
	in
	{
		assert(routeParams !is null);
		assert(routeParams.url !is null);
		static if(UseDelegates)
		{
			assert(ptr !is null);
		}
	}
	body
	{	
		Ret error(char[] msg = "")
		{
			if(errHandler) return errHandler.exec(routeParams, ptr);
			else throw new Exception("Routing error: " ~ msg);
		}
		
		try
		{
		
			auto token = routeParams.url.top;
			
			Routes* pRoutes;
			switch(routeParams.method)
			{
			case HttpMethod.Get: pRoutes = &getRoutes; break;
			case HttpMethod.Post: pRoutes = &postRoutes; break;
			default: return error;
			}		
			
			if(!token) {
				if(!pRoutes.defRoute) {
					return error;
				}
				
				return pRoutes.defRoute.exec(routeParams, ptr);
			}
			
			routeParams.url.pop;
			
			auto routing = token in pRoutes.routes;
			if(!routing) {
				if(!pRoutes.starRoute) {
					return error(token);
				}
				
				routeParams.lastToken = token;
				routeParams.params.addParam(["__wildcard__"], token);
				
				return pRoutes.starRoute.exec(routeParams, ptr);
			}
			
			routeParams.lastToken = token;
			
			return routing.exec(routeParams, ptr);
		}
		catch(Exception ex)
		{
			return error(ex.toString);
		}
	}
}

template TypeSafeRouterDef(Ret, Req)
{
	alias IFunctionWrapper!(Ret, Req) Routing;
	
	private struct Routes
	{
		void setRoute(char[] route, Routing routing)
		{
			if(!route.length) defRoute = routing;
			else if(route == "*") starRoute = routing;
			else routes[route] = routing;
		}
		
		Routing[char[]] routes;
		Routing starRoute = null;
		Routing defRoute = null;
	}
	
	Routes getRoutes;
	Routes postRoutes;
	Routing errHandler;
	
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
		default: throw new Exception("Unknown routing method");
		}
	}
	
	void setErrorHandler(T)(T t, char[][] paramNames)
	{
		errHandler = new FunctionWrapper!(T, Req)(t, paramNames);
	}
}

struct TypeSafeRouter(Ret, Req)
{
	mixin TypeSafeRouterDef!(Ret, Req);
	mixin Route!(Ret, Req);
}

struct TypeSafeInstanceRouter(Ret, Req)
{
	mixin TypeSafeRouterDef!(Ret, Req);
	mixin Route!(Ret, Req, true);
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