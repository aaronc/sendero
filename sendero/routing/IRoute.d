module sendero.routing.IRoute;

import sendero.http.Request, sendero.http.Response;

interface IIRoute(ResT, ReqT)
{
	ResT iroute(ReqT);
}

alias IIRoute!(Res, Req) IIController;