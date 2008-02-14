/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.routing.Common;

public import sendero.http.Request;

interface IFunctionWrapper(Ret, Req)
{
	Ret exec(Req routeParams, void* ptr = null);
}