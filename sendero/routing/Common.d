module sendero.routing.Common;

public import sendero.http.Request;

interface IFunctionWrapper(Ret, Req)
{
	Ret exec(Req routeParams, void* ptr = null);
}