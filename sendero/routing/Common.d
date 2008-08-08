/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.routing.Common;

public import sendero.http.Request;

interface IFunctionWrapper(RetT, ReqT)
{
	RetT exec(ReqT routeParams, void* ptr = null);
}

interface IDelegateWrapper(RetT, ReqT)
{
	RetT exec(void* ptr, ReqT routeParams);
}