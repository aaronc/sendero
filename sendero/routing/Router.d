/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.routing.Router;

public import sendero.routing.Common;
import sendero.routing.FunctionWrapper;
import sendero.routing.IRoute;

debug(SenderoRuntime) {
	import sendero.Debug;
	static this() { log = Log.lookup("debug.SenderoRuntime"); }
	Logger log;
}

const ubyte GET = 0;
const ubyte POST = 1;
const ubyte PUT = 2;
const ubyte DELETE = 3;
const ubyte ALL = 4;

template Route(ResT, ReqT, bool UseDelegates = false)
{
	ResT route(ReqT routeParams, void* ptr = null)
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
		debug(SenderoRuntime) mixin(FailTrace!("Route.route"));
		
		ResT error(char[] msg = "")
		{
			if(errHandler) return errHandler.exec(routeParams, ptr);
			else throw new Exception("Routing error: " ~ msg);
		}
		
		try
		{
			debug(SenderoRuntime) log.trace(MName ~ " BEGIN TRY");
			
			auto token = routeParams.url.top;
			
			debug(SenderoRuntime) log.trace(MName ~ " token = {}", token);
			
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
			//return error("Exception: " ~ ex.toString);
			throw ex;
		}
	}
}

template TypeSafeRouterDef(ResT, ReqT)
{
	alias IFunctionWrapper!(ResT, ReqT) Routing;
	
	private struct Routes
	{
		void setRoute(char[] route, Routing routing)
		{
			if(!route.length) defRoute = routing;
			else if(route == "/") defRoute = routing;
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
	
	static TypeSafeRouter!(ResT, ReqT) opCall()
	{
		TypeSafeRouter!(ResT, ReqT) router;
		return router;
	}
	
	void map(T)(ubyte method, char[] route, T t, char[][] paramNames)
	{
		Routing routing;
		routing = new FunctionWrapper!(T, ReqT)(t, paramNames);
		
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
		case PUT:
		case DELETE:
		default: throw new Exception("Unknown routing method");
		}
	}
	
	void mapContinue(char[] route, ResT function(ReqT) routeFn)
	{
		
	}
	
	void mapWildcardContinue(IIRoute!(ResT, ReqT) function(ReqT) getInstance)
	{
		/+auto fn = function ResT(ReqT req) {
			auto i = getInstance(req);
			return i.iroute(req);
		};+/
	}
	
	void setErrorHandler(T)(T t, char[][] paramNames)
	{
		errHandler = new FunctionWrapper!(T, ReqT)(t, paramNames);
	}
}

struct TypeSafeRouter(ResT, ReqT)
{
	mixin TypeSafeRouterDef!(ResT, ReqT);
	mixin Route!(ResT, ReqT);
}

struct TypeSafeInstanceRouter(ResT, ReqT)
{
	mixin TypeSafeRouterDef!(ResT, ReqT);
	mixin Route!(ResT, ReqT, true);
}


debug(SenderoUnittest)
{

import sendero.http.Request;

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
	auto rParams = new Request;
	rParams.parse(HttpMethod.Get, "/main", "param=test");
	auto res = Ctlr.route(rParams);
	assert(res== "test", res);
}

}