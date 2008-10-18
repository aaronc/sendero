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

template Route(ReqT, bool UseDelegates = false)
{
	void route(ReqT req, void* ptr = null)
	in
	{
		assert(req !is null);
		assert(req.url !is null);
		static if(UseDelegates)
		{
			assert(ptr !is null);
		}
	}
	body
	{	
		debug(SenderoRuntime) mixin(FailTrace!("Route.route"));
		
		void error(char[] msg = "")
		{
			if(errHandler) return errHandler.exec(req, ptr);
			else throw new Exception("Routing error: " ~ msg);
		}
		
		try
		{
			debug(SenderoRuntime) log.trace(MName ~ " BEGIN TRY");
			
			auto token = req.url.top;
			
			debug(SenderoRuntime) log.trace(MName ~ " token = {}", token);
			
			Routes* pRoutes;
			switch(req.method)
			{
			case HttpMethod.Get: pRoutes = &getRoutes; break;
			case HttpMethod.Post: pRoutes = &postRoutes; break;
			case HttpMethod.Put: pRoutes = &putRoutes; break;
			case HttpMethod.Delete: pRoutes = &deleteRoutes; break;
			default: return error;
			}		
			
			if(!token) {
				if(!pRoutes.defRoute) {
					return error;
				}
				
				return pRoutes.defRoute.exec(req, ptr);
			}
			
			req.url.pop;
			
			auto routing = token in pRoutes.routes;
			if(!routing) {
				if(!pRoutes.starRoute) {
					return error(token);
				}
				
				req.lastToken = token;
				req.params.addParam(["__wildcard__"], token);
				
				return pRoutes.starRoute.exec(req, ptr);
			}
			
			req.lastToken = token;
			
			return routing.exec(req, ptr);
		}
		catch(Exception ex)
		{
			//return error("Exception: " ~ ex.toString);
			throw ex;
		}
	}
}

template TypeSafeRouterDef(ReqT, bool InstanceRouter = false)
{
	alias IFunctionWrapper!(void, ReqT) Routing;
	
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
	Routes putRoutes;
	Routes deleteRoutes;
	Routing errHandler;
	
	static TypeSafeRouter!(ReqT) opCall()
	{
		TypeSafeRouter!(ReqT) router;
		return router;
	}
	
	void map(T)(ubyte method, char[] route, T t, char[][] paramNames)
	{
		Routing routing;
		routing = new FunctionWrapper2!(T, ReqT, InstanceRouter)(t, paramNames);
		
		switch(method)
		{
		case GET:
			getRoutes.setRoute(route, routing);
			break;
		case POST:
			postRoutes.setRoute(route, routing);
			break;
		case PUT:
			putRoutes.setRoute(route, routing);
			break;
		case DELETE:
			deleteRoutes.setRoute(route, routing);
		case ALL:
			getRoutes.setRoute(route, routing);
			postRoutes.setRoute(route, routing);
			putRoutes.setRoute(route, routing);
			deleteRoutes.setRoute(route, routing);
			break;
		default: throw new Exception("Unknown routing method");
		}
	}
	
	void mapContinue(char[] route, void function(ReqT) routeFn)
	{
		map(ALL, route, routeFn, null);
	}
	
	void mapWildcardContinue(IIRoute!(ReqT) function(ReqT) getInstance)
	{
		/+auto fn = function ResT(ReqT req) {
			auto i = getInstance(req);
			return i.iroute(req);
		};+/
	}
	
	void mapWildcardChildContinue(IIRoute!(ReqT) function(ReqT) getInstance)
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

struct TypeSafeRouter(ReqT)
{
	mixin TypeSafeRouterDef!(ReqT);
	mixin Route!(ReqT);
}

struct TypeSafeInstanceRouter(ReqT)
{
	mixin TypeSafeRouterDef!(ReqT, true);
	mixin Route!(ReqT, true);
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
	
	static char[] route(Request req)
	{
		return r.route(req);
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